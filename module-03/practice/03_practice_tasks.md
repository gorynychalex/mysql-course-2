# Практические задания - Модуль 3

## Задание 1. Создание базы данных с DDL

**Цель:** Отработать операторы CREATE DATABASE и CREATE TABLE

### Задание:

1. Создайте базу данных `library_ddl` с кодировкой utf8mb4
2. Создайте таблицы для библиотеки:

```sql
-- Таблица авторов
CREATE TABLE authors (
    -- id, name, birth_date, country, biography (TEXT)
);

-- Таблица книг
CREATE TABLE books (
    -- id, title, isbn, year, pages, price, description (TEXT)
);

-- Таблица читателей
CREATE TABLE readers (
    -- id, first_name, last_name, email, phone, birth_date, address
);

-- Таблица выдачи книг
CREATE TABLE loans (
    -- id, book_id, reader_id, loan_date, due_date, return_date, status
);
```

3. Добавьте все необходимые ограничения (PRIMARY KEY, FOREIGN KEY, NOT NULL, DEFAULT, UNIQUE)
4. Добавьте индексы для ускорения поиска

### Отчет:
- SQL-скрипт создания БД
- Скриншот выполнения SHOW CREATE TABLE для каждой таблицы

---

## Задание 2. Работа с ALTER TABLE

**Цель:** Научиться модифицировать структуру таблиц

### Задание:

Выполните следующие изменения в созданной базе:

1. **Добавьте столбцы:**
   - В `books`: `publisher` (VARCHAR), `language` (CHAR(2) DEFAULT 'ru'), `rating` (DECIMAL(3,2))
   - В `readers`: `registration_date` (TIMESTAMP), `is_active` (BOOLEAN)
   - В `loans`: `fine_amount` (DECIMAL), `notes` (TEXT)

2. **Измените столбцы:**
   - В `books`: увеличьте `title` до VARCHAR(500)
   - В `readers`: измените `email` на NOT NULL UNIQUE
   - В `loans`: добавьте CHECK ограничение на `fine_amount` (>= 0)

3. **Удалите столбцы:**
   - Если есть неиспользуемые столбцы

4. **Добавьте индексы:**
   - Составной индекс на (last_name, first_name) в readers
   - Полнотекстовый индекс на description в books
   - Индекс на status в loans

### Отчет:
- SQL-скрипт с ALTER командами
- Скриншот SHOW CREATE TABLE после изменений

---

## Задание 3. Индексы и производительность

**Цель:** Понять влияние индексов на производительность

### Задание:

1. Создайте таблицу без индексов:
```sql
CREATE TABLE test_performance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    city VARCHAR(100),
    created_at TIMESTAMP
);
```

2. Заполните таблицу 10000 записей (используйте цикл или скрипт)

3. Выполните запрос БЕЗ индекса:
```sql
EXPLAIN SELECT * FROM test_performance WHERE last_name = 'Иванов';
EXPLAIN SELECT * FROM test_performance WHERE city = 'Москва';
```

4. Создайте индексы:
```sql
CREATE INDEX idx_last_name ON test_performance(last_name);
CREATE INDEX idx_city ON test_performance(city);
```

5. Выполните те же запросы С индексом и сравните EXPLAIN

### Отчет:
- Скриншоты EXPLAIN до и после
- Выводы о влиянии индексов

---

## Задание 4. Полнотекстовый поиск

**Цель:** Освоить полнотекстовый поиск

### Задание:

1. Добавьте в таблицу `books` полнотекстовый индекс:
```sql
ALTER TABLE books ADD FULLTEXT INDEX ft_book_info (title, description);
```

2. Вставьте тестовые данные (минимум 20 книг с разными описаниями)

3. Выполните поисковые запросы:
   - Поиск по слову "программирование"
   - Поиск по фразе "базы данных"
   - Поиск с исключением: "MySQL" но не "учебник"
   - Поиск с подстановкой: "программ*"

### Отчет:
- SQL-скрипт с запросами
- Результаты поиска

---

## Задание 5. Временные таблицы

**Цель:** Научиться использовать временные таблицы

### Задание:

1. Создайте временную таблицу для отчёта:
```sql
CREATE TEMPORARY TABLE reader_report (
    reader_id INT,
    reader_name VARCHAR(100),
    total_loans INT,
    active_loans INT,
    total_fines DECIMAL(10,2),
    last_loan_date DATE
);
```

2. Заполните её данными из основных таблиц

3. Выполните выборку с фильтрацией

4. Проверьте, что таблица удаляется после закрытия соединения

### Отчет:
- SQL-скрипт с временной таблицей
- Результаты выборки

---

## Критерии оценки

| Критерий | Баллы |
|----------|-------|
| Задание 1: CREATE | 5 |
| Задание 2: ALTER | 10 |
| Задание 3: Индексы | 10 |
| Задание 4: FULLTEXT | 5 |
| Задание 5: TEMPORARY | 5 |
| Оформление | 5 |
| **ИТОГО** | **40** |
