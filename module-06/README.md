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

**Синтаксис CREATE PROCEDURE:**
```sql
DELIMITER //

CREATE [DEFINER = {user | CURRENT_USER}]
PROCEDURE procedure_name(
    [IN | OUT | INOUT] param_name datatype [, ...]
)
[COMMENT 'описание']
[LANGUAGE SQL]
[DETERMINISTIC | NOT DETERMINISTIC]
[SQL SECURITY {DEFINER | INVOKER}]
BEGIN
    -- Объявление переменных
    DECLARE variable_name datatype [DEFAULT value];

    -- Обработчики ошибок
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- код обработки
    END;

    -- Логика процедуры
    SQL statements;

    -- Присваивание значений OUT параметрам
    SET out_param = value;
END//

DELIMITER ;
```

**Параметры:**
- `DEFINER` — пользователь от имени которого выполняется процедура
- `IN` — входной параметр (передаётся в процедуру)
- `OUT` — выходной параметр (возвращается из процедуры)
- `INOUT` — входной и выходной параметр
- `COMMENT` — описание процедуры
- `DETERMINISTIC` — процедура всегда возвращает одинаковый результат
- `NOT DETERMINISTIC` — результат может отличаться (по умолчанию)
- `SQL SECURITY` — чьи привилегии использовать

**Особенности:**
- Требуют изменения разделителя (DELIMITER)
- Могут иметь несколько OUT параметров
- Могут возвращать несколько наборов результатов
- Могут содержать сложную логику с условиями и циклами
- Не возвращают значение напрямую (в отличие от функций)

**Вызов процедуры:**
```sql
-- Процедура без параметров
CALL procedure_name();

-- Процедура с IN параметрами
CALL procedure_name(value1, value2);

-- Процедура с OUT параметром
CALL procedure_name(IN_value, @out_var);
SELECT @out_var;

-- Удаление процедуры
DROP PROCEDURE [IF EXISTS] procedure_name;
```

### Создание процедуры

```sql
DELIMITER //

-- Простая процедура
CREATE PROCEDURE get_question_by_id(IN question_id INT)
BEGIN
    SELECT * FROM questions WHERE id = question_id;
END//

-- Процедура с несколькими запросами
CREATE PROCEDURE get_player_info(IN player_id INT)
BEGIN
    -- Информация об игроке
    SELECT * FROM players WHERE id = player_id;

    -- Активные сессии
    SELECT * FROM game_sessions
    WHERE player_id = player_id AND status = 'in_progress';

    -- Статистика
    SELECT COUNT(*) AS total_games, SUM(score) AS total_score
    FROM game_sessions
    WHERE player_id = player_id;
END//

-- Процедура с OUT параметром
CREATE PROCEDURE count_questions_by_category(
    IN category_id INT,
    OUT question_count INT
)
BEGIN
    SELECT COUNT(*) INTO question_count
    FROM questions
    WHERE category_id = category_id;
END//

-- Вызов процедуры с OUT параметром
CALL count_questions_by_category(1, @count);
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

**Синтаксис CREATE FUNCTION:**
```sql
DELIMITER //

CREATE [DEFINER = {user | CURRENT_USER}]
FUNCTION function_name(
    param_name datatype [, param_name datatype ...]
)
RETURNS return_datatype
[DETERMINISTIC | NOT DETERMINISTIC]
[READS SQL DATA | MODIFIES SQL DATA | CONTAINS SQL]
[SQL SECURITY {DEFINER | INVOKER}]
[COMMENT 'описание']
BEGIN
    -- Объявление переменных
    DECLARE variable_name datatype [DEFAULT value];

    -- Логика функции
    SQL statements;

    -- Возврат значения
    RETURN value;
END//

DELIMITER ;
```

**Параметры:**
- `DEFINER` — пользователь от имени которого выполняется функция
- `RETURNS` — тип возвращаемого значения (обязательно)
- `DETERMINISTIC` — функция всегда возвращает одинаковый результат для тех же входных данных
- `NOT DETERMINISTIC` — результат может отличаться (по умолчанию)
- `READS SQL DATA` — функция читает данные, но не модифицирует
- `MODIFIES SQL DATA` — функция модифицирует данные
- `CONTAINS SQL` — функция содержит SQL, но не читает и не модифицирует
- `SQL SECURITY` — чьи привилегии использовать
- `COMMENT` — описание функции

**Особенности:**
- Обязательно возвращает одно значение
- Можно использовать в SELECT, WHERE, ORDER BY
- Не может изменять данные таблицы (только READS SQL DATA)
- Требует изменения разделителя (DELIMITER)
- Может вызывать процедуры и другие функции

**Использование:**
```sql
-- В SELECT
SELECT function_name(param1, param2) AS alias;

-- В WHERE
SELECT * FROM table WHERE function_name(column) > value;

-- В выражениях
SELECT column, function_name(column) * 2 AS calculated FROM table;

-- Удаление функции
DROP FUNCTION [IF EXISTS] function_name;
```

### Примеры функций

```sql
DELIMITER //

-- Функция расчёта возраста игрока
CREATE FUNCTION calculate_player_age(birth_date DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE age INT;
    SET age = TIMESTAMPDIFF(YEAR, birth_date, CURDATE());
    RETURN age;
END//

-- Функция расчёта бонусных очков
CREATE FUNCTION calculate_bonus(
    base_score INT,
    difficulty DECIMAL(3,1)
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE bonus INT;

    SET bonus = FLOOR(base_score * difficulty / 10);

    RETURN bonus;
END//

-- Функция форматирования имени пользователя
CREATE FUNCTION format_player_tag(
    username VARCHAR(50),
    level INT
)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    RETURN CONCAT(username, '[L', level, ']');
END//

DELIMITER ;

-- Использование функций
SELECT calculate_player_age('1990-05-15') AS age;
SELECT calculate_bonus(1000, 5.0) AS bonus;
```

---

## 8. Оператор IF и условия

### IF в запросах

```sql
SELECT
    question_text,
    IF(difficulty > 7.0, 'hard', 'easy') AS difficulty_category,
    IFNULL(explanation, 'No explanation') AS explanation_display,
    CASE
        WHEN status = 'active' THEN 'Активен'
        WHEN status = 'inactive' THEN 'Неактивен'
        WHEN status = 'draft' THEN 'Черновик'
        ELSE 'Неизвестно'
    END AS status_russian
FROM questions;
```

### IF в процедурах

```sql
DELIMITER //

CREATE PROCEDURE check_question_availability(
    IN question_id INT,
    OUT is_available BOOLEAN,
    OUT message VARCHAR(255)
)
BEGIN
    DECLARE active_sessions INT;

    SELECT COUNT(*) INTO active_sessions
    FROM game_sessions gs
    JOIN session_answers sa ON gs.id = sa.session_id
    WHERE sa.question_id = question_id AND gs.status = 'in_progress';

    IF active_sessions > 0 THEN
        SET is_available = FALSE;
        SET message = CONCAT('Вопрос используется в сессиях: ', active_sessions);
    ELSE
        SET is_available = TRUE;
        SET message = 'Вопрос доступен';
    END IF;
END//

DELIMITER ;
```

### CASE выражение

```sql
DELIMITER //

CREATE PROCEDURE get_session_status_description(
    IN session_id INT
)
BEGIN
    DECLARE status VARCHAR(20);

    SELECT gs.status INTO status FROM game_sessions gs WHERE gs.id = session_id;

    SELECT CASE status
        WHEN 'in_progress' THEN 'Игра идет'
        WHEN 'completed' THEN 'Игра завершена'
        WHEN 'cancelled' THEN 'Игра отменена'
        WHEN 'timeout' THEN 'Время вышло'
        ELSE 'Неизвестный статус'
    END AS status_description;
END//

DELIMITER ;
```

---

## 9. Создание триггеров

**Синтаксис CREATE TRIGGER:**
```sql
DELIMITER //

CREATE TRIGGER trigger_name
{BEFORE | AFTER} {INSERT | UPDATE | DELETE}
ON table_name
FOR EACH ROW
[ORDER]  -- MySQL 8.0.17+
BEGIN
    -- Объявление переменных
    DECLARE variable_name datatype;

    -- Логика триггера
    -- Доступ к новым значениям: NEW.column_name
    -- Доступ к старым значениям: OLD.column_name

    -- Примеры операций:
    -- SET NEW.column = value;  -- только в BEFORE
    -- INSERT INTO ...;
    -- UPDATE ...;
    -- DELETE ...;
END//

DELIMITER ;

-- Удаление триггера
DROP TRIGGER [IF EXISTS] trigger_name;

-- Просмотр триггеров
SHOW TRIGGERS;
SHOW CREATE TRIGGER trigger_name;
```

**Параметры:**
- `BEFORE` — выполнить до операции (можно изменять NEW значения)
- `AFTER` — выполнить после операции (нельзя изменять данные)
- `INSERT` — срабатывает при вставке строки
- `UPDATE` — срабатывает при обновлении строки
- `DELETE` — срабатывает при удалении строки
- `FOR EACH ROW` — выполняется для каждой затронутой строки
- `ORDER` — порядок выполнения триггеров (MySQL 8.0.17+)

**Псевдонимы:**
- `NEW.column` — новое значение (доступно в BEFORE INSERT/UPDATE, AFTER INSERT/UPDATE)
- `OLD.column` — старое значение (доступно в BEFORE UPDATE/DELETE, AFTER UPDATE/DELETE)

**Ограничения:**
- Нельзя вызывать COMMIT, ROLLBACK (неявная транзакция)
- Нельзя изменять таблицу, на которой установлен триггер
- Нельзя использовать динамический SQL
- Ошибка в триггере отменяет всю операцию

**Применение:**
- Аудит и логирование изменений
- Проверка сложных ограничений
- Автоматическое вычисление значений
- Каскадные обновления
- Поддержание денормализованных данных

### Синтаксис триггера

```sql
DELIMITER //

-- Триггер перед вставкой (автоматическая дата)
CREATE TRIGGER before_player_insert
BEFORE INSERT ON players
FOR EACH ROW
BEGIN
    IF NEW.created_at IS NULL THEN
        SET NEW.created_at = CURDATE();
    END IF;
END//

-- Триггер после вставки (логирование)
CREATE TRIGGER after_session_insert
AFTER INSERT ON game_sessions
FOR EACH ROW
BEGIN
    INSERT INTO session_log (session_id, action, action_date)
    VALUES (NEW.id, 'created', NOW());

    -- Обновление статистики игрока
    UPDATE players SET games_played = games_played + 1 WHERE id = NEW.player_id;
END//

-- Триггер перед обновлением (проверка)
CREATE TRIGGER before_session_update
BEFORE UPDATE ON game_sessions
FOR EACH ROW
BEGIN
    -- Нельзя изменить дату начала после создания
    SET NEW.started_at = OLD.started_at;

    -- Если завершена, установить дату завершения
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        IF NEW.completed_at IS NULL THEN
            SET NEW.completed_at = CURDATE();
        END IF;
    END IF;
END//

-- Триггер после удаления (каскадное логирование)
CREATE TRIGGER after_player_delete
AFTER DELETE ON players
FOR EACH ROW
BEGIN
    INSERT INTO player_archive (
        player_id, username, email, archived_at
    ) VALUES (
        OLD.id, OLD.username, OLD.email, NOW()
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
