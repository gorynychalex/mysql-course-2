# Модуль 8. Оптимизация и обслуживание сервера MySQL

**Продолжительность:** 4 академических часа

## Содержание модуля

1. Создание резервной копии базы
2. Учётные записи
3. Сброс пароля суперпользователя
4. Оптимизация запросов
5. Выгрузка данных в HTML и XML

---

## 1. Создание резервной копии базы

### mysqldump

```bash
# Базовый синтаксис
mysqldump -u username -p database_name > backup.sql

# Полная резервная копия
mysqldump -u root -p \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --all-databases > full_backup.sql

# Только структура
mysqldump -u root -p --no-data database_name > structure.sql

# Только данные
mysqldump -u root -p --no-create-info database_name > data.sql

# С сжатием
mysqldump -u root -p database_name | gzip > backup.sql.gz

# Несколько баз данных
mysqldump -u root -p --databases db1 db2 db3 > backup.sql
```

### Восстановление из备份

```bash
# Восстановление базы
mysql -u root -p database_name < backup.sql

# Восстановление из сжатого файла
gunzip < backup.sql.gz | mysql -u root -p database_name

# Восстановление всех баз
mysql -u root -p < full_backup.sql
```

### Резервное копирование в MySQL

```sql
-- Копирование таблицы
CREATE TABLE books_backup AS SELECT * FROM books;

-- Копирование структуры
CREATE TABLE books_structure LIKE books;

-- Копирование с данными
CREATE TABLE books_copy LIKE books;
INSERT INTO books_copy SELECT * FROM books;
```

---

## 2. Учётные записи

### Создание пользователей

```sql
-- Создание пользователя
CREATE USER 'username'@'host' IDENTIFIED BY 'password';

-- Примеры
CREATE USER 'librarian'@'localhost' IDENTIFIED BY 'secure_password';
CREATE USER 'admin'@'%' IDENTIFIED BY 'admin_password';
CREATE USER 'readonly'@'192.168.1.%' IDENTIFIED BY 'read_password';
```

### Предоставление прав (GRANT)

```sql
-- Все права на базу
GRANT ALL PRIVILEGES ON database_name.* TO 'user'@'host';

-- Конкретные права
GRANT SELECT, INSERT, UPDATE, DELETE ON database_name.* TO 'user'@'host';

-- Только чтение
GRANT SELECT ON database_name.* TO 'readonly'@'host';

-- Только определённые таблицы
GRANT SELECT, INSERT ON database_name.books TO 'user'@'host';
GRANT SELECT ON database_name.readers TO 'user'@'host';

-- Применение изменений
FLUSH PRIVILEGES;
```

### Типы привилегий

| Привилегия | Описание |
|------------|----------|
| **SELECT** | Выборка данных |
| **INSERT** | Вставка данных |
| **UPDATE** | Обновление данных |
| **DELETE** | Удаление данных |
| **CREATE** | Создание таблиц/БД |
| **DROP** | Удаление таблиц/БД |
| **ALTER** | Изменение структуры |
| **INDEX** | Создание индексов |
| **REFERENCES** | Внешние ключи |
| **ALL PRIVILEGES** | Все права |

### Отзыв прав (REVOKE)

```sql
-- Отзыв конкретных прав
REVOKE DELETE ON database_name.* FROM 'user'@'host';

-- Отзыв всех прав
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'user'@'host';

-- Удаление пользователя
DROP USER 'user'@'host';
```

### Просмотр прав

```sql
-- Права пользователя
SHOW GRANTS FOR 'user'@'host';

-- Все пользователи
SELECT User, Host FROM mysql.user;

-- Детальная информация
SELECT * FROM mysql.user WHERE User = 'librarian';
```

---

## 3. Сброс пароля суперпользователя

### MySQL 5.7+ / 8.0

```bash
# Остановка сервера
sudo systemctl stop mysql

# Запуск в безопасном режиме
sudo mysqld_safe --skip-grant-tables &

# Подключение без пароля
mysql -u root

# Сброс пароля
USE mysql;
UPDATE user SET authentication_string=PASSWORD('new_password') 
WHERE User='root';
FLUSH PRIVILEGES;
EXIT;

# Перезапуск сервера
sudo systemctl restart mysql
```

### MySQL 8.0+ (альтернативный способ)

```bash
# С использованием опции
sudo mysqld --initialize-insecure

# Или через mysqladmin
mysqladmin -u root password 'new_password'
```

### Через ALTER USER (MySQL 5.7+)

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
```

---

## 4. Оптимизация запросов

### EXPLAIN

```sql
-- Анализ запроса
EXPLAIN SELECT * FROM books WHERE author_id = 5;

-- Расширенный анализ
EXPLAIN FORMAT=JSON SELECT * FROM books WHERE author_id = 5;

-- Анализ с выполнением
EXPLAIN ANALYZE SELECT * FROM books WHERE author_id = 5;
```

### Поля EXPLAIN

| Поле | Описание |
|------|----------|
| **id** | Идентификатор выбора |
| **select_type** | Тип SELECT |
| **table** | Таблица |
| **type** | Тип соединения |
| **possible_keys** | Возможные ключи |
| **key** | Используемый ключ |
| **key_len** | Длина ключа |
| **ref** | Столбцы для сравнения |
| **rows** | Оцениваемое количество строк |
| **Extra** | Дополнительная информация |

### Типы соединений (type)

| Тип | Описание |
|-----|----------|
| **system** | Одна строка (лучший) |
| **const** | Константа (очень быстро) |
| **eq_ref** | Уникальный ключ |
| **ref** | Не уникальный ключ |
| **range** | Диапазон по индексу |
| **index** | Полное сканирование индекса |
| **ALL** | Полное сканирование таблицы (худший) |

### Оптимизация индексами

```sql
-- Проблема: полный scan
EXPLAIN SELECT * FROM books WHERE title LIKE '%война%';
-- type: ALL

-- Решение: FULLTEXT индекс
ALTER TABLE books ADD FULLTEXT INDEX ft_title (title);
EXPLAIN SELECT * FROM books WHERE MATCH(title) AGAINST('война');
-- type: fulltext

-- Проблема: нет индекса на foreign key
EXPLAIN SELECT * FROM loans WHERE reader_id = 5;

-- Решение: добавить индекс
CREATE INDEX idx_reader_id ON loans(reader_id);
```

### Оптимизация запросов

```sql
-- Плохо: SELECT *
SELECT * FROM books WHERE author_id = 5;

-- Хорошо: конкретные столбцы
SELECT id, title, year FROM books WHERE author_id = 5;

-- Плохо: функция в WHERE
SELECT * FROM books WHERE YEAR(publication_year) = 2020;

-- Хорошо: диапазон
SELECT * FROM books 
WHERE publication_year >= '2020-01-01' 
  AND publication_year < '2021-01-01';

-- Плохо: OR без индексов
SELECT * FROM books WHERE title = 'ABC' OR description = 'XYZ';

-- Хорошо: UNION
SELECT * FROM books WHERE title = 'ABC'
UNION
SELECT * FROM books WHERE description = 'XYZ';
```

### Профилирование запросов

```sql
-- Включение профилирования
SET profiling = 1;

-- Выполнение запросов
SELECT * FROM books WHERE author_id = 5;
SELECT * FROM books WHERE category_id = 3;

-- Просмотр профиля
SHOW PROFILES;
SHOW PROFILE FOR QUERY 1;

-- Детальная статистика
SHOW PROFILE CPU, BLOCK IO FOR QUERY 1;
```

### Медленные запросы

```sql
-- Включение медленного лога
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2; -- секунды
SET GLOBAL slow_query_log_file = '/var/log/mysql/slow.log';

-- Просмотр медленных запросов
SELECT * FROM mysql.slow_log;
```

---

## 5. Выгрузка данных в HTML и XML

### Экспорт в XML

```sql
-- Простой экспорт в XML
SELECT * FROM books 
WHERE author_id = 5
INTO OUTFILE '/tmp/books.xml'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- XML формат через команду
mysql -u root -p -X -e "SELECT * FROM books" database_name > books.xml
```

### Экспорт в HTML

```bash
# Через mysql с форматированием
mysql -u root -p -H -e "SELECT * FROM books" database_name > books.html
```

### Генерация HTML отчёта

```sql
-- Создание HTML отчёта
SELECT 
    CONCAT(
        '<html><head><title>Library Report</title></head><body>',
        '<h1>Book Catalog</h1>',
        '<table border="1">',
        '<tr><th>ID</th><th>Title</th><th>Author</th><th>Year</th></tr>'
    ) AS html_header;

SELECT 
    CONCAT(
        '<tr>',
        '<td>', id, '</td>',
        '<td>', title, '</td>',
        '<td>', author, '</td>',
        '<td>', publication_year, '</td>',
        '</tr>'
    ) AS html_row
FROM books
LIMIT 10;

SELECT CONCAT('</table></body></html>') AS html_footer;
```

### Экспорт в различные форматы

```bash
# CSV
mysql -u root -p -B -e "SELECT * FROM books" database_name | \
    sed 's/\t/,/g' > books.csv

# JSON (MySQL 5.7+)
mysql -u root -p -N -e "SELECT JSON_ARRAYAGG(JSON_OBJECT('id', id, 'title', title)) FROM books" database_name

# Excel-compatible TSV
mysql -u root -p -B -e "SELECT * FROM books" database_name > books.tsv
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
