# Модуль 4. Выражения SQL: манипулирование данными (DML)

**Продолжительность:** 4 академических часа

## Содержание модуля

1. CRUD-операторы
2. Вставка данных
3. Загрузка данных LOAD
4. Обновление данных
5. Удаление
6. Выборка данных
7. Предикаты
8. Объединения таблиц

---

## 1. CRUD-операторы

### Что такое CRUD?

**CRUD** — аббревиатура четырёх базовых операций с данными:

| Операция | SQL | Описание |
|----------|-----|----------|
| **C**reate | INSERT | Создание новых записей |
| **R**ead | SELECT | Чтение/выборка данных |
| **U**pdate | UPDATE | Обновление существующих записей |
| **D**elete | DELETE | Удаление записей |

### Пример CRUD операций

```sql
-- CREATE: Вставка новой книги
INSERT INTO books (title, author, year) 
VALUES ('Война и мир', 'Л.Н. Толстой', 1869);

-- READ: Выборка книг
SELECT * FROM books WHERE author = 'Л.Н. Толстой';

-- UPDATE: Обновление книги
UPDATE books SET year = 1870 WHERE title = 'Война и мир';

-- DELETE: Удаление книги
DELETE FROM books WHERE id = 1;
```

---

## 2. Вставка данных (INSERT)

### Базовый синтаксис INSERT

```sql
-- Вставка одной строки
INSERT INTO table_name (column1, column2, column3)
VALUES (value1, value2, value3);

-- Вставка нескольких строк
INSERT INTO table_name (column1, column2, column3)
VALUES 
    (value1, value2, value3),
    (value4, value5, value6),
    (value7, value8, value9);
```

### Примеры INSERT

```sql
-- Вставка с указанием всех столбцов
INSERT INTO readers (id, first_name, last_name, email, phone, registration_date)
VALUES (1, 'Иван', 'Петров', 'ivan@example.com', '+7-900-123-4567', '2024-01-15');

-- Вставка без указания столбцов с DEFAULT
INSERT INTO readers VALUES (DEFAULT, 'Петр', 'Иванов', 'petr@example.com', 
                           '+7-900-765-4321', CURDATE());

-- Вставка нескольких читателей
INSERT INTO readers (first_name, last_name, email, registration_date) VALUES
    ('Анна', 'Сидорова', 'anna@example.com', '2024-01-16'),
    ('Ольга', 'Кузнецова', 'olga@example.com', '2024-01-17'),
    ('Дмитрий', 'Попов', 'dmitry@example.com', '2024-01-18');

-- Вставка с игнорированием ошибок
INSERT IGNORE INTO readers (email, first_name, last_name) 
VALUES ('ivan@example.com', 'Иван', 'Новиков');

-- Вставка с обновлением при конфликте
INSERT INTO readers (email, first_name, last_name)
VALUES ('ivan@example.com', 'Иван', 'Новиков')
ON DUPLICATE KEY UPDATE 
    first_name = 'Иван',
    last_name = 'Новиков',
    updated_at = CURRENT_TIMESTAMP;
```

### INSERT ... SELECT

```sql
-- Копирование данных из одной таблицы в другую
INSERT INTO readers_archive (id, first_name, last_name, email)
SELECT id, first_name, last_name, email
FROM readers
WHERE is_active = FALSE;

-- Вставка с вычисляемыми значениями
INSERT INTO reader_stats (reader_id, total_loans, last_visit)
SELECT id, 0, NOW()
FROM readers
WHERE registration_date >= '2024-01-01';
```

---

## 3. Загрузка данных LOAD DATA

### Синтаксис LOAD DATA INFILE

```sql
LOAD DATA [LOCAL] INFILE 'file_path'
INTO TABLE table_name
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

### Примеры загрузки

```sql
-- Загрузка из CSV файла
LOAD DATA LOCAL INFILE '/path/to/readers.csv'
INTO TABLE readers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(first_name, last_name, email, phone, @reg_date)
SET registration_date = STR_TO_DATE(@reg_date, '%d.%m.%Y');

-- Загрузка с указанием столбцов
LOAD DATA LOCAL INFILE '/path/to/books.csv'
INTO TABLE books
FIELDS TERMINATED BY ';'
(title, @year_str, author, @price_str)
SET 
    publication_year = CAST(@year_str AS UNSIGNED),
    price = CAST(REPLACE(@price_str, '₽', '') AS DECIMAL(10,2));
```

### Формат CSV файла

```csv
first_name,last_name,email,phone,registration_date
Иван,Петров,ivan@example.com,+7-900-123-4567,15.01.2024
Петр,Сидоров,petr@example.com,+7-900-765-4321,16.01.2024
```

### Экспорт данных в файл

```sql
-- Выгрузка в CSV
SELECT first_name, last_name, email
INTO OUTFILE '/tmp/readers_export.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM readers;

-- Выгрузка с заголовками
(SELECT 'first_name', 'last_name', 'email')
UNION ALL
(SELECT first_name, last_name, email FROM readers)
INTO OUTFILE '/tmp/readers_with_headers.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

---

## 4. Обновление данных (UPDATE)

### Базовый синтаксис UPDATE

```sql
-- Обновление одной таблицы
UPDATE table_name
SET column1 = value1, column2 = value2
WHERE condition;

-- Обновление с JOIN
UPDATE t1
JOIN t2 ON t1.id = t2.t1_id
SET t1.column = value
WHERE t2.condition;
```

### Примеры UPDATE

```sql
-- Простое обновление
UPDATE books 
SET price = price * 1.1 
WHERE publication_year < 2000;

-- Обновление нескольких столбцов
UPDATE readers 
SET 
    is_active = TRUE,
    is_blocked = FALSE,
    block_reason = NULL,
    updated_at = CURRENT_TIMESTAMP
WHERE reader_card_number = 'R001';

-- Обновление с подзапросом
UPDATE books 
SET rating = (
    SELECT AVG(rating) 
    FROM reviews 
    WHERE reviews.book_id = books.id
)
WHERE id IN (SELECT book_id FROM reviews);

-- Обновление с JOIN
UPDATE loans l
JOIN book_copies bc ON l.copy_id = bc.id
SET l.status = 'overdue'
WHERE l.due_date < CURDATE() 
  AND l.status = 'active'
  AND bc.status = 'borrowed';

-- Обновление с CASE
UPDATE books
SET status = CASE
    WHEN publication_year < 1950 THEN 'archived'
    WHEN publication_year < 2000 THEN 'inactive'
    ELSE 'active'
END;
```

---

## 5. Удаление данных (DELETE)

### Базовый синтаксис DELETE

```sql
-- Удаление с условием
DELETE FROM table_name WHERE condition;

-- Удаление всех записей
DELETE FROM table_name;

-- Удаление с LIMIT
DELETE FROM table_name WHERE condition LIMIT 10;

-- Удаление с ORDER BY
DELETE FROM table_name 
WHERE condition 
ORDER BY column 
LIMIT 10;
```

### Примеры DELETE

```sql
-- Удаление по условию
DELETE FROM fines 
WHERE status = 'paid' 
  AND paid_date < DATE_SUB(CURDATE(), INTERVAL 3 YEAR);

-- Удаление с JOIN
DELETE l, f
FROM loans l
LEFT JOIN fines f ON l.id = f.loan_id
WHERE l.reader_id = 1 
  AND l.status = 'returned';

-- Удаление дубликатов
DELETE t1 FROM readers t1
INNER JOIN readers t2 
WHERE t1.id > t2.id 
  AND t1.email = t2.email;
```

### DELETE vs TRUNCATE

| Операция | Описание | Отличия |
|----------|----------|---------|
| **DELETE** | DML операция | Можно с WHERE, логируется, медленнее |
| **TRUNCATE** | DDL операция | Всегда вся таблица, сбрасывает AUTO_INCREMENT, быстрее |

```sql
-- Удаление всех записей с сохранением структуры
DELETE FROM temp_table;

-- Быстрая очистка со сбросом AUTO_INCREMENT
TRUNCATE TABLE temp_table;
```

---

## 6. Выборка данных (SELECT)

### Базовый синтаксис SELECT

```sql
SELECT [DISTINCT] column1, column2, ...
FROM table_name
WHERE condition
GROUP BY columns
HAVING condition
ORDER BY columns
LIMIT offset, count;
```

### Примеры SELECT

```sql
-- Выборка всех столбцов
SELECT * FROM books;

-- Выборка конкретных столбцов
SELECT title, author, price FROM books;

-- Выборка с псевдонимами
SELECT 
    title AS "Название",
    author AS "Автор",
    price AS "Цена, ₽"
FROM books;

-- DISTINCT - уникальные значения
SELECT DISTINCT author FROM books;

-- Выборка с вычислениями
SELECT 
    title,
    price,
    price * 0.8 AS discounted_price
FROM books;

-- Выборка с функциями
SELECT 
    author,
    COUNT(*) AS book_count,
    AVG(price) AS avg_price,
    MAX(publication_year) AS latest_year
FROM books
GROUP BY author
HAVING book_count > 1
ORDER BY book_count DESC;
```

---

## 7. Предикаты

### Предикаты сравнения

```sql
-- Равенство и неравенство
SELECT * FROM books WHERE price = 100;
SELECT * FROM books WHERE price != 100;
SELECT * FROM books WHERE price <> 100;

-- Сравнение с диапазоном
SELECT * FROM books WHERE price BETWEEN 100 AND 500;
SELECT * FROM books WHERE price NOT BETWEEN 100 AND 500;

-- Сравнение со списком
SELECT * FROM books WHERE status IN ('available', 'reserved');
SELECT * FROM books WHERE status NOT IN ('lost', 'written_off');

-- Сравнение с NULL
SELECT * FROM readers WHERE phone IS NULL;
SELECT * FROM readers WHERE phone IS NOT NULL;

-- Сравнение с шаблоном (LIKE)
SELECT * FROM books WHERE title LIKE 'Война%';
SELECT * FROM books WHERE title LIKE '%мир%';
SELECT * FROM books WHERE title LIKE '_ойна';
SELECT * FROM books WHERE isbn LIKE '978-_-___-___-_'

-- Регулярные выражения (REGEXP)
SELECT * FROM books WHERE title REGEXP '^[А-Я]';
SELECT * FROM readers WHERE email REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
```

### Логические операторы

```sql
-- AND
SELECT * FROM books 
WHERE price > 100 AND publication_year > 2000;

-- OR
SELECT * FROM books 
WHERE status = 'available' OR status = 'reserved';

-- NOT
SELECT * FROM books 
WHERE NOT status = 'lost';

-- Комбинация
SELECT * FROM books 
WHERE (price > 100 AND publication_year > 2000) 
   OR status = 'new';
```

### EXISTS и NOT EXISTS

```sql
-- EXISTS - проверка существования
SELECT * FROM readers r
WHERE EXISTS (
    SELECT 1 FROM loans l 
    WHERE l.reader_id = r.id 
    AND l.status = 'active'
);

-- NOT EXISTS
SELECT * FROM readers r
WHERE NOT EXISTS (
    SELECT 1 FROM loans l 
    WHERE l.reader_id = r.id
);
```

---

## 8. Объединения таблиц (JOIN)

### Типы JOIN

| Тип | Описание | Синтаксис |
|-----|----------|-----------|
| **INNER JOIN** | Только совпадающие строки | JOIN или INNER JOIN |
| **LEFT JOIN** | Все из левой + совпадения из правой | LEFT JOIN или LEFT OUTER JOIN |
| **RIGHT JOIN** | Все из правой + совпадения из левой | RIGHT JOIN или RIGHT OUTER JOIN |
| **FULL JOIN** | Все строки из обеих | UNION LEFT + RIGHT |
| **CROSS JOIN** | Декартово произведение | CROSS JOIN |
| **SELF JOIN** | Соединение таблицы с собой | JOIN table AS alias |

### Примеры JOIN

```sql
-- INNER JOIN (внутреннее соединение)
SELECT 
    b.title,
    a.first_name,
    a.last_name
FROM books b
INNER JOIN book_authors ba ON b.id = ba.book_id
INNER JOIN authors a ON ba.author_id = a.id;

-- LEFT JOIN (левое соединение)
SELECT 
    r.first_name,
    r.last_name,
    l.loan_date,
    l.due_date
FROM readers r
LEFT JOIN loans l ON r.id = l.reader_id AND l.status = 'active';

-- RIGHT JOIN (правое соединение)
SELECT 
    b.title,
    bc.inventory_number
FROM books b
RIGHT JOIN book_copies bc ON b.id = bc.book_id;

-- Множественное соединение
SELECT 
    r.first_name,
    r.last_name,
    b.title,
    bc.inventory_number,
    l.loan_date,
    l.due_date
FROM loans l
JOIN readers r ON l.reader_id = r.id
JOIN book_copies bc ON l.copy_id = bc.id
JOIN books b ON bc.book_id = b.id
WHERE l.status = 'active';

-- SELF JOIN (иерархия категорий)
SELECT 
    c.name AS category_name,
    p.name AS parent_category
FROM categories c
LEFT JOIN categories p ON c.parent_id = p.id;

-- CROSS JOIN (декартово произведение)
SELECT 
    d.day_name,
    t.time_slot
FROM days d
CROSS JOIN time_slots t;
```

### UNION для объединения результатов

```sql
-- UNION (уникальные строки)
SELECT first_name, last_name, 'reader' AS type FROM readers
UNION
SELECT first_name, last_name, 'staff' AS type FROM staff;

-- UNION ALL (все строки, включая дубликаты)
SELECT book_id FROM loans WHERE status = 'active'
UNION ALL
SELECT book_id FROM reservations WHERE status = 'pending';
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
