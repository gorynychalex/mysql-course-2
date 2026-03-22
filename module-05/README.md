# Модуль 5. Объединение запросов и манипулирование данными

**Продолжительность:** 4 академических часа

## Содержание модуля

1. Объединение SELECT (UNION)
2. Подзапросы IN, SOME, ALL, BETWEEN
3. Оператор EXISTS
4. Представления (VIEW)
5. Ограничения представлений

---

## 1. Объединение SELECT (UNION)

### UNION vs UNION ALL

```sql
-- UNION: уникальные строки (удаляет дубликаты)
SELECT column FROM table1
UNION
SELECT column FROM table2;

-- UNION ALL: все строки (включая дубликаты)
SELECT column FROM table1
UNION ALL
SELECT column FROM table2;
```

### Примеры UNION

```sql
-- Объединение списков людей
SELECT first_name, last_name, 'reader' AS type FROM readers
UNION
SELECT first_name, last_name, 'staff' AS type FROM staff
ORDER BY last_name;

-- Поиск по нескольким таблицам
SELECT book_id, 'loan' AS source, loan_date AS date FROM loans
UNION ALL
SELECT book_id, 'reservation' AS source, reservation_date AS date FROM reservations
ORDER BY date DESC;

-- UNION с разным количеством столбцов
SELECT id, title, author, NULL AS reason FROM books
UNION ALL
SELECT id, title, author, ban_reason FROM banned_books;
```

### Требования к UNION

- Одинаковое количество столбцов
- Совместимые типы данных
- Псевдонимы берутся из первого SELECT

---

## 2. Подзапросы

### Подзапросы в WHERE

```sql
-- IN: значение в списке
SELECT * FROM books 
WHERE author_id IN (SELECT id FROM authors WHERE country = 'Россия');

-- NOT IN: значение не в списке
SELECT * FROM readers 
WHERE id NOT IN (SELECT DISTINCT reader_id FROM loans WHERE status = 'overdue');

-- Сравнение с подзапросом
SELECT * FROM books 
WHERE price > (SELECT AVG(price) FROM books);

-- ANY/SOME: сравнение с любым значением
SELECT * FROM books 
WHERE price > SOME (SELECT price FROM books WHERE category_id = 1);

-- ALL: сравнение со всеми значениями
SELECT * FROM books 
WHERE price > ALL (SELECT price FROM books WHERE category_id = 1);
```

### Подзапросы в FROM

```sql
-- Подзапрос как таблица
SELECT 
    category_name,
    avg_price
FROM (
    SELECT 
        c.name AS category_name,
        AVG(b.price) AS avg_price
    FROM books b
    JOIN categories c ON b.category_id = c.id
    GROUP BY c.id
) AS category_stats
WHERE avg_price > 100;
```

### Подзапросы в SELECT

```sql
-- Скалярный подзапрос
SELECT 
    b.title,
    (SELECT COUNT(*) FROM loans l JOIN book_copies bc ON l.copy_id = bc.id 
     WHERE bc.book_id = b.id) AS loan_count,
    (SELECT AVG(rating) FROM reviews WHERE book_id = b.id) AS avg_rating
FROM books b;
```

### Коррелированные подзапросы

```sql
-- Подзапрос зависит от внешнего запроса
SELECT 
    r.first_name,
    r.last_name,
    (SELECT COUNT(*) FROM loans l WHERE l.reader_id = r.id) AS total_loans
FROM readers r;

-- С EXISTS
SELECT * FROM readers r
WHERE EXISTS (
    SELECT 1 FROM loans l 
    WHERE l.reader_id = r.id 
    AND l.status = 'overdue'
);
```

---

## 3. Оператор EXISTS

### EXISTS vs IN

```sql
-- EXISTS: проверка существования (быстрее на больших данных)
SELECT * FROM categories c
WHERE EXISTS (
    SELECT 1 FROM questions q WHERE q.category_id = c.id
);

-- IN: проверка вхождения
SELECT * FROM categories c
WHERE c.id IN (SELECT category_id FROM questions);
```

### Примеры EXISTS

```sql
-- Читатели с активными выдачами
SELECT * FROM readers r
WHERE EXISTS (
    SELECT 1 FROM loans l 
    WHERE l.reader_id = r.id 
    AND l.status = 'active'
);

-- Книги без экземпляров
SELECT * FROM books b
WHERE NOT EXISTS (
    SELECT 1 FROM book_copies bc WHERE bc.book_id = b.id
);

-- Авторы без книг в библиотеке
SELECT * FROM authors a
WHERE NOT EXISTS (
    SELECT 1 FROM book_authors ba WHERE ba.author_id = a.id
);
```

---

## 4. Представления (VIEW)

### Создание представлений

```sql
-- Простое представление
CREATE VIEW v_available_books AS
SELECT 
    b.id,
    b.title,
    b.author,
    bc.inventory_number,
    bc.location
FROM books b
JOIN book_copies bc ON b.id = bc.book_id
WHERE bc.status = 'available';

-- Представление с группировкой
CREATE VIEW v_reader_stats AS
SELECT 
    r.id,
    r.first_name,
    r.last_name,
    r.email,
    COUNT(l.id) AS total_loans,
    SUM(CASE WHEN l.status = 'active' THEN 1 ELSE 0 END) AS active_loans,
    SUM(f.amount) AS total_fines
FROM readers r
LEFT JOIN loans l ON r.id = l.reader_id
LEFT JOIN fines f ON r.id = f.reader_id
GROUP BY r.id;

-- Представление с вычислениями
CREATE VIEW v_overdue_loans AS
SELECT 
    l.id,
    r.first_name,
    r.last_name,
    r.phone,
    b.title,
    l.loan_date,
    l.due_date,
    DATEDIFF(CURDATE(), l.due_date) AS days_overdue,
    DATEDIFF(CURDATE(), l.due_date) * 10 AS fine_amount
FROM loans l
JOIN readers r ON l.reader_id = r.id
JOIN book_copies bc ON l.copy_id = bc.id
JOIN books b ON bc.book_id = b.id
WHERE l.status = 'active' 
  AND l.due_date < CURDATE();
```

### Использование представлений

```sql
-- Запрос к представлению
SELECT * FROM v_available_books WHERE location = 'A1';

-- Объединение представлений
SELECT * FROM v_reader_stats 
JOIN v_overdue_loans ON v_reader_stats.id = v_overdue_loans.reader_id;
```

### Обновляемые представления

```sql
-- Представление можно обновлять, если:
-- 1. Один источник данных
-- 2. Нет GROUP BY, DISTINCT, агрегатных функций
-- 3. Нет подзапросов в SELECT

CREATE VIEW v_active_readers AS
SELECT id, first_name, last_name, email
FROM readers
WHERE is_active = TRUE;

-- Обновление через представление
UPDATE v_active_readers 
SET email = 'new@email.com' 
WHERE id = 1;
```

---

## 5. Ограничения представлений

### Что нельзя делать в представлениях

```sql
-- ОШИБКА: нельзя с ORDER BY без LIMIT
CREATE VIEW v_books_sorted AS
SELECT * FROM books ORDER BY title;

-- ПРАВИЛЬНО: с LIMIT
CREATE VIEW v_books_sorted AS
SELECT * FROM books ORDER BY title LIMIT 100;

-- ОШИБКА: нельзя с GROUP BY и обновлением
CREATE VIEW v_book_stats AS
SELECT author, COUNT(*) AS cnt FROM books GROUP BY author;
-- Нельзя UPDATE/INSERT/DELETE через это представление
```

### Материал представления

```sql
-- Обычное представление (вычисляется при запросе)
CREATE VIEW v_stats AS SELECT ...;

-- В MySQL нет материализованных представлений
-- Но можно использовать таблицы для кэширования
CREATE TABLE m_book_stats AS
SELECT author, COUNT(*) AS cnt FROM books GROUP BY author;
```

### Управление представлениями

```sql
-- Показать создания представления
SHOW CREATE VIEW v_available_books;

-- Обновить представление
CREATE OR REPLACE VIEW v_available_books AS
SELECT ... новый запрос ...;

-- Удалить представление
DROP VIEW IF EXISTS v_available_books;

-- Показать все представления
SHOW FULL TABLES WHERE TABLE_TYPE = 'VIEW';
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
