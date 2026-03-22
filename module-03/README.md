# Модуль 3. Синтаксис выражений SQL для определения структуры данных (DDL)

**Продолжительность:** 4 академических часа

## Содержание модуля

1. DDL-операторы
2. Операторы создания базы
3. Создание таблиц
4. Временные таблицы
5. Индексы
6. Полнотекстовый индекс
7. Оператор модификации ALTER

---

## 1. DDL-операторы

### Что такое DDL?

**DDL (Data Definition Language)** — язык определения данных, подмножество SQL для создания и модификации структуры базы данных.

### Основные DDL-операторы

| Оператор | Описание | Пример |
|----------|----------|--------|
| **CREATE** | Создание объекта | CREATE TABLE |
| **ALTER** | Изменение объекта | ALTER TABLE |
| **DROP** | Удаление объекта | DROP TABLE |
| **TRUNCATE** | Очистка таблицы | TRUNCATE TABLE |
| **RENAME** | Переименование | RENAME TABLE |
| **CREATE OR REPLACE** | Создание или замена | CREATE OR REPLACE VIEW |

### Особенности DDL

```sql
-- DDL-операторы автоматически фиксируют транзакции
-- Нельзя откатить изменения без резервной копии

BEGIN;
CREATE TABLE test (id INT);
-- После выполнения CREATE транзакция автоматически зафиксирована
ROLLBACK; -- Не отменит CREATE TABLE
```

---

## 2. Операторы создания базы данных

### CREATE DATABASE

```sql
-- Базовый синтаксис
CREATE DATABASE database_name;

-- С указанием кодировки
CREATE DATABASE library_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Если база не существует
CREATE DATABASE IF NOT EXISTS library_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
```

### Параметры кодировки

| Параметр | Описание | Рекомендация |
|----------|----------|--------------|
| **CHARACTER SET** | Набор символов | utf8mb4 |
| **COLLATE** | Правила сравнения | utf8mb4_unicode_ci |

### Популярные кодировки

```sql
--_utf8mb4_ (рекомендуется)
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci    -- Универсальная
COLLATE utf8mb4_general_ci    -- Быстрее, менее точная
COLLATE utf8mb4_bin           -- Двоичное сравнение

-- Для конкретных языков
COLLATE utf8mb4_ru_0900_ai_ci -- Русский (MySQL 8.0+)
COLLATE utf8mb4_en_0900_ai_ci -- Английский
```

### Просмотр информации о базах данных

```sql
-- Показать все базы
SHOW DATABASES;

-- Показать создание базы
SHOW CREATE DATABASE library_db;

-- Использовать базу
USE library_db;

-- Текущая база
SELECT DATABASE();
```

### Удаление базы данных

```sql
-- Удаление базы
DROP DATABASE database_name;

-- Удаление с проверкой существования
DROP DATABASE IF EXISTS database_name;
```

---

## 3. Создание таблиц

### Базовый синтаксис CREATE TABLE

```sql
CREATE TABLE table_name (
    column1_name datatype [constraints],
    column2_name datatype [constraints],
    ...
    table_constraints
) ENGINE=storage_engine DEFAULT CHARSET=charset;
```

### Пример создания таблицы

```sql
CREATE TABLE books (
    -- Первичный ключ
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Обязательные поля
    title VARCHAR(255) NOT NULL,
    isbn CHAR(13) NOT NULL UNIQUE,
    
    -- Необязательные поля
    author VARCHAR(100),
    description TEXT,
    pages_count INT UNSIGNED,
    
    -- Числовые поля
    price DECIMAL(10,2) DEFAULT 0.00,
    quantity INT UNSIGNED DEFAULT 0,
    
    -- Дата и время
    published_year YEAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Статусы
    status ENUM('available', 'borrowed', 'reserved', 'lost') DEFAULT 'available',
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Индексы
    INDEX idx_title (title),
    INDEX idx_author (author),
    INDEX idx_status (status),
    FULLTEXT INDEX ft_description (description)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Таблица книг библиотеки';
```

### Ограничения столбцов (Constraints)

| Ограничение | Описание | Пример |
|-------------|----------|--------|
| **NOT NULL** | Не может быть NULL | column VARCHAR(50) NOT NULL |
| **NULL** | Может быть NULL | column VARCHAR(50) NULL |
| **DEFAULT** | Значение по умолчанию | column INT DEFAULT 0 |
| **UNIQUE** | Уникальное значение | column VARCHAR(50) UNIQUE |
| **PRIMARY KEY** | Первичный ключ | column INT PRIMARY KEY |
| **AUTO_INCREMENT** | Автоинкремент | column INT AUTO_INCREMENT |
| **REFERENCES** | Внешний ключ | column INT REFERENCES other(id) |
| **CHECK** | Проверка условия | column INT CHECK (column > 0) |

### Типы таблиц (Storage Engines)

| Движок | Описание | Применение |
|--------|----------|------------|
| **InnoDB** | Транзакционный, FK | По умолчанию, OLTP |
| **MyISAM** | Быстрый, нет транзакций | Чтение, устарел |
| **MEMORY** | В памяти, быстро | Временные данные |
| **ARCHIVE** | Архивирование | Логи, история |
| **CSV** | CSV файлы | Импорт/экспорт |

---

## 4. Временные таблицы

### Что такое временные таблицы?

**Временные таблицы** существуют только в течение сессии подключения и автоматически удаляются при закрытии соединения.

### Создание временной таблицы

```sql
-- Создание временной таблицы
CREATE TEMPORARY TABLE temp_results (
    id INT,
    value DECIMAL(10,2),
    calculated_at TIMESTAMP
);

-- Использование
INSERT INTO temp_results VALUES (1, 100.50, NOW());
SELECT * FROM temp_results;

-- Временная таблица удалится автоматически при закрытии соединения
```

### Явное удаление временной таблицы

```sql
DROP TEMPORARY TABLE IF EXISTS temp_results;
```

### Пример использования

```sql
-- Создание временной таблицы с результатами
CREATE TEMPORARY TABLE reader_stats AS
SELECT 
    r.id,
    r.first_name,
    r.last_name,
    COUNT(l.id) AS loans_count,
    SUM(f.amount) AS total_fines
FROM readers r
LEFT JOIN loans l ON r.id = l.reader_id
LEFT JOIN fines f ON r.id = f.reader_id
GROUP BY r.id;

-- Использование
SELECT * FROM reader_stats WHERE loans_count > 5;

-- Таблица удалится автоматически
```

### Преимущества временных таблиц

- Автоматическая очистка
- Не занимают место после сессии
- Можно создавать с тем же именем в разных сессиях
- Ускоряют сложные запросы

---

## 5. Индексы

### Что такое индекс?

**Индекс** — структура данных для ускорения поиска строк в таблице.

### Типы индексов

| Тип | Описание | Синтаксис |
|-----|----------|-----------|
| **PRIMARY KEY** | Первичный ключ | PRIMARY KEY (col) |
| **UNIQUE** | Уникальный индекс | UNIQUE KEY (col) |
| **INDEX** | Обычный индекс | INDEX (col) |
| **FULLTEXT** | Полнотекстовый | FULLTEXT (col) |
| **SPATIAL** | Пространственный | SPATIAL (col) |
| **COMPOSITE** | Составной индекс | INDEX (col1, col2) |

### Создание индексов

```sql
-- При создании таблицы
CREATE TABLE readers (
    id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    last_name VARCHAR(50),
    first_name VARCHAR(50),
    phone VARCHAR(20),
    
    INDEX idx_name (last_name, first_name),
    INDEX idx_phone (phone)
);

-- Добавление индекса после создания
CREATE INDEX idx_email ON readers(email);

-- Уникальный индекс
CREATE UNIQUE INDEX idx_unique_email ON readers(email);

-- Составной индекс
CREATE INDEX idx_full_name ON readers(last_name, first_name);
```

### Просмотр индексов

```sql
-- Показать индексы таблицы
SHOW INDEX FROM readers;

-- Альтернатива
SHOW INDEXES FROM readers;
SHOW KEYS FROM readers;
```

### Удаление индексов

```sql
-- Удаление по имени
DROP INDEX idx_email ON readers;

-- Через ALTER TABLE
ALTER TABLE readers DROP INDEX idx_email;

-- Удаление PRIMARY KEY
ALTER TABLE readers DROP PRIMARY KEY;
```

### Когда создавать индексы

✅ **Создавать индекс:**
- Поля в WHERE
- Поля в JOIN
- Поля в ORDER BY
- Поля в GROUP BY
- Внешние ключи

❌ **Не создавать индекс:**
- Таблицы с частыми INSERT/UPDATE/DELETE
- Поля с низкой селективностью (пол, статус)
- Маленькие таблицы

---

## 6. Полнотекстовый индекс

### Что такое полнотекстовый поиск?

**FULLTEXT индекс** позволяет выполнять поиск по текстовому содержимому с учётом морфологии.

### Создание полнотекстового индекса

```sql
-- При создании таблицы
CREATE TABLE articles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255),
    body TEXT,
    FULLTEXT INDEX ft_title_body (title, body)
) ENGINE=InnoDB;

-- Добавление к существующей таблице
ALTER TABLE articles ADD FULLTEXT INDEX ft_body (body);
```

### Режимы полнотекстового поиска

```sql
-- Естественный язык (по умолчанию)
SELECT * FROM articles
WHERE MATCH(title, body) AGAINST('библиотека книга' IN NATURAL LANGUAGE MODE);

-- С расширением (слова с * )
SELECT * FROM articles
WHERE MATCH(title, body) AGAINST('библио*' IN BOOLEAN MODE);

-- Точная фраза
SELECT * FROM articles
WHERE MATCH(title, body) AGAINST('"научная фантастика"' IN BOOLEAN MODE);

-- Исключение слов
SELECT * FROM articles
WHERE MATCH(title, body) AGAINST('+библиотека -учебная' IN BOOLEAN MODE);
```

### Операторы BOOLEAN MODE

| Оператор | Описание | Пример |
|----------|----------|--------|
| **+** | Слово должно присутствовать | +библиотека |
| **-** | Слово должно отсутствовать | -учебная |
| **\*** | Подстановочный знак | библио* |
| **"** | Точная фраза | "научная фантастика" |
| **>** | Повысить релевантность | >важное |
| **<** | Понизить релевантность | <менееважное |
| **()** | Группировка | +(библиотека книга) |

### Настройки полнотекстового поиска

```sql
-- Минимальная длина слова (по умолчанию 4)
SHOW VARIABLES LIKE 'ft_min_word_len';

-- Стоп-слова
SHOW VARIABLES LIKE 'ft_stopword_file';

-- Для InnoDB (MySQL 5.6+)
-- Минимальная длина для InnoDB
SHOW VARIABLES LIKE 'innodb_ft_min_token_size';
```

---

## 7. Оператор модификации ALTER

### ALTER TABLE

**ALTER TABLE** — оператор для изменения структуры существующей таблицы.

### Добавление столбца

```sql
-- Добавить столбец в конец
ALTER TABLE books ADD COLUMN publisher VARCHAR(100);

-- Добавить столбец в начало
ALTER TABLE books ADD COLUMN id INT FIRST;

-- Добавить столбец после другого
ALTER TABLE books ADD COLUMN isbn CHAR(13) AFTER title;

-- Добавить столбец с ограничениями
ALTER TABLE books ADD COLUMN rating DECIMAL(3,2) DEFAULT 0.00 CHECK (rating >= 0 AND rating <= 5);
```

### Изменение столбца

```sql
-- Изменить тип данных
ALTER TABLE books MODIFY COLUMN title VARCHAR(500);

-- Изменить имя и тип
ALTER TABLE books CHANGE COLUMN title book_title VARCHAR(500);

-- Добавить NOT NULL
ALTER TABLE books MODIFY COLUMN author VARCHAR(100) NOT NULL;

-- Удалить NOT NULL
ALTER TABLE books MODIFY COLUMN author VARCHAR(100) NULL;

-- Изменить значение по умолчанию
ALTER TABLE books MODIFY COLUMN status ENUM('available', 'borrowed') DEFAULT 'available';
```

### Удаление столбца

```sql
ALTER TABLE books DROP COLUMN publisher;
```

### Добавление ограничений

```sql
-- Первичный ключ
ALTER TABLE books ADD PRIMARY KEY (id);

-- Уникальный ключ
ALTER TABLE books ADD UNIQUE KEY unique_isbn (isbn);

-- Внешний ключ
ALTER TABLE loans ADD CONSTRAINT fk_book
    FOREIGN KEY (book_id) REFERENCES books(id);

-- Индекс
ALTER TABLE books ADD INDEX idx_title (title);
```

### Удаление ограничений

```sql
-- Первичный ключ
ALTER TABLE books DROP PRIMARY KEY;

-- Уникальный ключ
ALTER TABLE books DROP INDEX unique_isbn;

-- Внешний ключ
ALTER TABLE loans DROP FOREIGN KEY fk_book;

-- Индекс
ALTER TABLE books DROP INDEX idx_title;
```

### Переименование таблицы

```sql
-- Переименовать таблицу
ALTER TABLE books RENAME TO book_catalog;

-- Несколько таблиц
ALTER TABLE old_name1 RENAME TO new_name1,
             old_name2 RENAME TO new_name2;
```

### Изменение движка и кодировки

```sql
-- Изменить движок
ALTER TABLE books ENGINE=MyISAM;

-- Изменить кодировку
ALTER TABLE books CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Изменить кодировку столбца
ALTER TABLE books MODIFY title VARCHAR(255) CHARACTER SET utf8mb4;
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
