# Модуль 6. Хранимые процедуры и триггеры

**Продолжительность:** 4 академических часа

## Содержание модуля

1. Понятие ROUTINES
2. Хранимые процедуры
3. Встроенные функции
4. Работа с датой/временем
5. Работа с числами
6. Строки
7. Собственные функции
8. Оператор IF
9. Создание триггеров

---

## 1. Понятие ROUTINES

### Что такое ROUTINES?

**ROUTINES** — хранимые программные объекты MySQL:

| Тип | Описание | Возвращает |
|-----|----------|------------|
| **PROCEDURE** | Хранимая процедура | Ничего (может иметь OUT параметры) |
| **FUNCTION** | Хранимая функция | Одно значение |
| **TRIGGER** | Триггер | Ничего (автоматическое выполнение) |
| **EVENT** | Событие | Ничего (выполнение по расписанию) |

### Просмотр ROUTINES

```sql
-- Показать все процедуры и функции
SHOW PROCEDURE STATUS;
SHOW FUNCTION STATUS;

-- Показать создание процедуры
SHOW CREATE PROCEDURE procedure_name;
SHOW CREATE FUNCTION function_name;

-- Информация из INFORMATION_SCHEMA
SELECT * FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = 'database_name';
```

---

## 2. Хранимые процедуры

### Создание процедуры

```sql
DELIMITER //

CREATE PROCEDURE procedure_name(
    IN param1 datatype,
    IN param2 datatype,
    OUT result datatype
)
BEGIN
    -- Тело процедуры
    SELECT column INTO result FROM table WHERE id = param1;
END//

DELIMITER ;
```

### Примеры процедур

```sql
DELIMITER //

-- Простая процедура
CREATE PROCEDURE get_book_by_id(IN book_id INT)
BEGIN
    SELECT * FROM books WHERE id = book_id;
END//

-- Процедура с несколькими запросами
CREATE PROCEDURE get_reader_info(IN reader_id INT)
BEGIN
    -- Информация о читателе
    SELECT * FROM readers WHERE id = reader_id;
    
    -- Активные выдачи
    SELECT * FROM loans 
    WHERE reader_id = reader_id AND status = 'active';
    
    -- Штрафы
    SELECT SUM(amount) AS total_fines 
    FROM fines 
    WHERE reader_id = reader_id AND status != 'paid';
END//

-- Процедура с OUT параметром
CREATE PROCEDURE count_books_by_author(
    IN author_id INT,
    OUT book_count INT
)
BEGIN
    SELECT COUNT(*) INTO book_count 
    FROM book_authors 
    WHERE author_id = author_id;
END//

-- Вызов процедуры с OUT параметром
CALL count_books_by_author(1, @count);
SELECT @count;

DELIMITER ;
```

### Параметры процедур

| Тип | Описание |
|-----|----------|
| **IN** | Входной параметр (по умолчанию) |
| **OUT** | Выходной параметр |
| **INOUT** | Входной и выходной |

```sql
CREATE PROCEDURE increment_counter(INOUT value INT)
BEGIN
    SET value = value + 1;
END//

SET @counter = 5;
CALL increment_counter(@counter);
SELECT @counter; -- 6
```

---

## 3. Встроенные функции

### Математические функции

```sql
SELECT 
    ABS(-10) AS absolute,           -- 10
    CEIL(4.3) AS ceiling,           -- 5
    FLOOR(4.7) AS floor,            -- 4
    ROUND(4.567, 2) AS rounded,     -- 4.57
    TRUNCATE(4.567, 2) AS truncated,-- 4.56
    MOD(10, 3) AS remainder,        -- 1
    POWER(2, 3) AS power,           -- 8
    SQRT(16) AS square_root,        -- 4
    RAND() AS random;               -- случайное число
```

### Строковые функции

```sql
SELECT 
    LENGTH('Hello') AS length,              -- 5
    CONCAT('Hello', ' ', 'World') AS concat,-- 'Hello World'
    UPPER('hello') AS upper,                -- 'HELLO'
    LOWER('HELLO') AS lower,                -- 'hello'
    SUBSTRING('Hello World', 1, 5) AS sub,  -- 'Hello'
    REPLACE('Hello World', 'World', 'MySQL') AS repl, -- 'Hello MySQL'
    TRIM('  Hello  ') AS trimmed,           -- 'Hello'
    LPAD('1', 3, '0') AS padded,            -- '001'
    REVERSE('Hello') AS reversed,           -- 'olleH'
    INSTR('Hello', 'l') AS position;        -- 3
```

---

## 4. Работа с датой/временем

### Функции даты и времени

```sql
SELECT 
    NOW() AS current_datetime,              -- 2024-01-15 10:30:00
    CURDATE() AS current_date,              -- 2024-01-15
    CURTIME() AS current_time,              -- 10:30:00
    YEAR(NOW()) AS year,                    -- 2024
    MONTH(NOW()) AS month,                  -- 1
    DAY(NOW()) AS day,                      -- 15
    HOUR(NOW()) AS hour,                    -- 10
    MINUTE(NOW()) AS minute,                -- 30
    DAYNAME(NOW()) AS day_name,             -- 'Monday'
    MONTHNAME(NOW()) AS month_name;         -- 'January'
```

### Операции с датами

```sql
SELECT 
    DATE_ADD(NOW(), INTERVAL 1 DAY) AS tomorrow,
    DATE_SUB(NOW(), INTERVAL 1 MONTH) AS last_month,
    DATEDIFF('2024-12-31', NOW()) AS days_to_end,
    TIMESTAMPDIFF(DAY, '2024-01-01', NOW()) AS days_since_start,
    DATE_FORMAT(NOW(), '%d.%m.%Y %H:%i') AS formatted,
    STR_TO_DATE('15.01.2024', '%d.%m.%Y') AS parsed;
```

### Форматы даты

| Код | Описание | Пример |
|-----|----------|--------|
| %Y | Год 4 цифры | 2024 |
| %y | Год 2 цифры | 24 |
| %m | Месяц | 01-12 |
| %d | День | 01-31 |
| %H | Часы | 00-23 |
| %i | Минуты | 00-59 |
| %s | Секунды | 00-59 |
| %W | День недели | Monday |
| %M | Месяц | January |

---

## 5. Работа с числами

```sql
-- Форматирование чисел
SELECT FORMAT(1234567.89, 2) AS formatted; -- '1,234,567.89'

-- Конвертация типов
SELECT CAST('123.45' AS DECIMAL(10,2)) AS decimal_value;
SELECT CONVERT('123', UNSIGNED) AS int_value;

-- Работа с NULL
SELECT 
    NULLIF(5, 5) AS nullif_same,      -- NULL
    NULLIF(5, 3) AS nullif_diff,      -- 5
    IFNULL(NULL, 0) AS ifnull,        -- 0
    COALESCE(NULL, NULL, 10, 20) AS coalesce; -- 10
```

---

## 6. Строки

```sql
-- Сравнение строк
SELECT 
    'abc' = 'ABC' AS case_insensitive,  -- 1 (по умолчанию)
    BINARY 'abc' = 'ABC' AS binary_cmp; -- 0

-- Извлечение подстроки
SELECT 
    LEFT('Hello World', 5) AS left_part,    -- 'Hello'
    RIGHT('Hello World', 5) AS right_part,  -- 'World'
    SUBSTRING_INDEX('a.b.c', '.', 2) AS sub;-- 'a.b'

-- Поиск и замена
SELECT 
    LOCATE('World', 'Hello World') AS position, -- 7
    REPLACE('Hello World', ' ', '-') AS replaced; -- 'Hello-World'
```

---

## 7. Собственные функции

### Создание функции

```sql
DELIMITER //

CREATE FUNCTION function_name(param datatype)
RETURNS return_datatype
DETERMINISTIC
BEGIN
    DECLARE result datatype;
    -- Логика
    RETURN result;
END//

DELIMITER ;
```

### Примеры функций

```sql
DELIMITER //

-- Функция расчёта возраста
CREATE FUNCTION calculate_age(birth_date DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE age INT;
    SET age = TIMESTAMPDIFF(YEAR, birth_date, CURDATE());
    RETURN age;
END//

-- Функция расчёта штрафа
CREATE FUNCTION calculate_fine(
    due_date DATE, 
    return_date DATE
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE days_overdue INT;
    DECLARE fine_amount DECIMAL(10,2);
    
    SET days_overdue = DATEDIFF(return_date, due_date);
    
    IF days_overdue > 0 THEN
        SET fine_amount = days_overdue * 10.00;
    ELSE
        SET fine_amount = 0.00;
    END IF;
    
    RETURN fine_amount;
END//

-- Функция форматирования имени
CREATE FUNCTION format_name(
    first_name VARCHAR(50),
    last_name VARCHAR(50)
)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    RETURN CONCAT(UPPER(last_name), ' ', INITCAP(first_name));
END//

DELIMITER ;

-- Использование функций
SELECT calculate_age('1990-05-15') AS age;
SELECT calculate_fine('2024-01-01', '2024-01-10') AS fine;
```

---

## 8. Оператор IF и условия

### IF в запросах

```sql
SELECT 
    title,
    IF(price > 100, 'expensive', 'cheap') AS price_category,
    IFNULL(description, 'No description') AS desc_display,
    CASE 
        WHEN status = 'available' THEN 'Доступна'
        WHEN status = 'borrowed' THEN 'Выдана'
        WHEN status = 'reserved' THEN 'Зарезервирована'
        ELSE 'Неизвестно'
    END AS status_russian
FROM books;
```

### IF в процедурах

```sql
DELIMITER //

CREATE PROCEDURE check_book_availability(
    IN book_id INT,
    OUT is_available BOOLEAN,
    OUT message VARCHAR(255)
)
BEGIN
    DECLARE available_copies INT;
    
    SELECT COUNT(*) INTO available_copies
    FROM book_copies
    WHERE book_id = book_id AND status = 'available';
    
    IF available_copies > 0 THEN
        SET is_available = TRUE;
        SET message = CONCAT('Доступно копий: ', available_copies);
    ELSE
        SET is_available = FALSE;
        SET message = 'Книга недоступна';
    END IF;
END//

DELIMITER ;
```

### CASE выражение

```sql
DELIMITER //

CREATE PROCEDURE get_loan_status_description(
    IN loan_id INT
)
BEGIN
    DECLARE status VARCHAR(20);
    
    SELECT l.status INTO status FROM loans l WHERE l.id = loan_id;
    
    SELECT CASE status
        WHEN 'active' THEN 'Книга на руках'
        WHEN 'returned' THEN 'Книга возвращена'
        WHEN 'overdue' THEN 'Просрочено'
        WHEN 'lost' THEN 'Книга утеряна'
        ELSE 'Неизвестный статус'
    END AS status_description;
END//

DELIMITER ;
```

---

## 9. Создание триггеров

### Синтаксис триггера

```sql
CREATE TRIGGER trigger_name
{BEFORE | AFTER} {INSERT | UPDATE | DELETE}
ON table_name
FOR EACH ROW
BEGIN
    -- Тело триггера
END;
```

### Примеры триггеров

```sql
DELIMITER //

-- Триггер перед вставкой (автоматическая дата)
CREATE TRIGGER before_reader_insert
BEFORE INSERT ON readers
FOR EACH ROW
BEGIN
    IF NEW.registration_date IS NULL THEN
        SET NEW.registration_date = CURDATE();
    END IF;
END//

-- Триггер после вставки (логирование)
CREATE TRIGGER after_loan_insert
AFTER INSERT ON loans
FOR EACH ROW
BEGIN
    INSERT INTO loan_log (loan_id, action, action_date)
    VALUES (NEW.id, 'created', NOW());
    
    -- Обновление статуса копии
    UPDATE book_copies SET status = 'borrowed' WHERE id = NEW.copy_id;
END//

-- Триггер перед обновлением (проверка)
CREATE TRIGGER before_loan_update
BEFORE UPDATE ON loans
FOR EACH ROW
BEGIN
    -- Нельзя изменить дату выдачи после создания
    SET NEW.loan_date = OLD.loan_date;
    
    -- Если возвращена, установить дату возврата
    IF NEW.status = 'returned' AND OLD.status != 'returned' THEN
        IF NEW.return_date IS NULL THEN
            SET NEW.return_date = CURDATE();
        END IF;
    END IF;
END//

-- Триггер после удаления (каскадное логирование)
CREATE TRIGGER after_reader_delete
AFTER DELETE ON readers
FOR EACH ROW
BEGIN
    INSERT INTO reader_archive (
        reader_id, first_name, last_name, archived_at
    ) VALUES (
        OLD.id, OLD.first_name, OLD.last_name, NOW()
    );
END//

DELIMITER ;
```

### Псевдонимы в триггерах

| Псевдоним | Описание |
|-----------|----------|
| **NEW.column** | Новое значение (INSERT, UPDATE) |
| **OLD.column** | Старое значение (UPDATE, DELETE) |

### Управление триггерами

```sql
-- Показать триггеры
SHOW TRIGGERS;

-- Показать создание триггера
SHOW CREATE TRIGGER trigger_name;

-- Удалить триггер
DROP TRIGGER IF EXISTS trigger_name;
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
