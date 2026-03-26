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
-- CREATE: Вставка нового вопроса
INSERT INTO questions (question_text, category_id, difficulty)
VALUES ('Столица России?', 1, 1.0);

-- READ: Выборка вопросов
SELECT * FROM questions WHERE category_id = 1;

-- UPDATE: Обновление вопроса
UPDATE questions SET difficulty = 2.0 WHERE question_text = 'Столица России?';

-- DELETE: Удаление вопроса
DELETE FROM questions WHERE id = 1;
```

---

## 2. Вставка данных (INSERT)

### Базовый синтаксис INSERT

**Синтаксис INSERT:**
```sql
-- Вставка одной строки
INSERT [IGNORE] [INTO] table_name
    [(column1, column2, ..., columnN)]
    VALUES (value1, value2, ..., valueN);

-- Вставка нескольких строк
INSERT [IGNORE] [INTO] table_name
    [(column1, column2, ..., columnN)]
    VALUES
        (value1_1, value1_2, ..., value1_N),
        (value2_1, value2_2, ..., value2_N),
        ...;

-- Вставка из SELECT
INSERT [IGNORE] [INTO] table_name [(columns)]
    SELECT ...;

-- Вставка с обновлением при конфликте
INSERT INTO table_name (columns) VALUES (values)
    ON DUPLICATE KEY UPDATE column=value;
```

**Параметры:**
- `IGNORE` — игнорировать ошибки (дубликаты, NULL в NOT NULL)
- `INTO` — необязательное ключевое слово
- `DEFAULT` — использовать значение по умолчанию
- `VALUES` — список значений для вставки
- `ON DUPLICATE KEY UPDATE` — обновить при конфликте уникального ключа

**Правила:**
- Порядок значений должен соответствовать порядку столбцов
- Можно не указывать столбцы с AUTO_INCREMENT и DEFAULT
- TEXT и BLOB нельзя использовать в VALUES по умолчанию

### Примеры INSERT

```sql
-- Вставка с указанием всех столбцов
INSERT INTO players (id, username, email, total_score, games_played)
VALUES (1, 'ivan_gamer', 'ivan@example.com', 0, 0);

-- Вставка без указания столбцов с DEFAULT
INSERT INTO players VALUES (DEFAULT, 'petr_player', 'petr@example.com',
                           0, 0, CURDATE());

-- Вставка нескольких игроков
INSERT INTO players (username, email, total_score) VALUES
    ('anna_quiz', 'anna@example.com', 0),
    ('olga_master', 'olga@example.com', 0),
    ('dmitry_pro', 'dmitry@example.com', 0);

-- Вставка с игнорированием ошибок
INSERT IGNORE INTO players (email, username)
VALUES ('ivan@example.com', 'ivan_new');

-- Вставка с обновлением при конфликте
INSERT INTO players (email, username, total_score)
VALUES ('ivan@example.com', 'ivan_new', 100)
ON DUPLICATE KEY UPDATE
    username = 'ivan_new',
    total_score = total_score + 100,
    updated_at = CURRENT_TIMESTAMP;
```

### INSERT ... SELECT

```sql
-- Копирование данных из одной таблицы в другую
INSERT INTO players_archive (id, username, email, total_score)
SELECT id, username, email, total_score
FROM players
WHERE is_active = FALSE;

-- Вставка с вычисляемыми значениями
INSERT INTO player_stats (player_id, total_games, last_played)
SELECT id, 0, NOW()
FROM players
WHERE created_at >= '2024-01-01';
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
LOAD DATA LOCAL INFILE '/path/to/players.csv'
INTO TABLE players
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(username, email, @score_str, @games_str, @created_str)
SET
    total_score = CAST(@score_str AS UNSIGNED),
    games_played = CAST(@games_str AS UNSIGNED),
    created_at = STR_TO_DATE(@created_str, '%d.%m.%Y');

-- Загрузка с указанием столбцов
LOAD DATA LOCAL INFILE '/path/to/questions.csv'
INTO TABLE questions
FIELDS TERMINATED BY ';'
(category_id, @question_text, @difficulty_str, @points_str)
SET
    question_text = @question_text,
    difficulty = CAST(@difficulty_str AS DECIMAL(3,1)),
    points = CAST(@points_str AS UNSIGNED);
```

### Формат CSV файла

```csv
username,email,total_score,games_played,created_at
ivan_gamer,ivan@example.com,100,5,15.01.2024
petr_player,petr@example.com,200,10,16.01.2024
```

### Экспорт данных в файл

```sql
-- Выгрузка в CSV
SELECT username, email, total_score
INTO OUTFILE '/tmp/players_export.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM players;

-- Выгрузка с заголовками
(SELECT 'username', 'email', 'total_score')
UNION ALL
(SELECT username, email, total_score FROM players)
INTO OUTFILE '/tmp/players_with_headers.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

---

## 4. Обновление данных (UPDATE)

### Базовый синтаксис UPDATE

**Синтаксис UPDATE:**
```sql
-- Обновление одной таблицы
UPDATE [LOW_PRIORITY] [IGNORE] table_name [AS alias]
SET column1 = value1 [, column2 = value2, ...]
[WHERE condition]
[ORDER BY column [ASC|DESC]]
[LIMIT row_count];

-- Обновление с JOIN (несколько таблиц)
UPDATE [LOW_PRIORITY] [IGNORE] table1 [AS alias1]
    JOIN table2 [AS alias2] ON join_condition
    [JOIN table3 ON join_condition ...]
SET table1.column = value1, table2.column = value2
[WHERE condition]
[LIMIT row_count];
```

**Параметры:**
- `LOW_PRIORITY` — отложить выполнение до завершения чтений
- `IGNORE` — игнорировать ошибки обновления
- `SET` — присвоить новые значения столбцам
- `WHERE` — условие для выбора строк (без него обновятся ВСЕ строки!)
- `ORDER BY` — порядок обновления строк
- `LIMIT` — ограничить количество обновляемых строк
- `JOIN` — обновление по нескольким таблицам

**Важно:**
- Всегда используйте WHERE, если не хотите обновить все строки
- ORDER BY полезен с LIMIT для обновления конкретных строк
- При обновлении с JOIN можно обновлять столбцы обеих таблиц

### Примеры UPDATE

```sql
-- Простое обновление
UPDATE questions
SET points = points * 2
WHERE difficulty > 5.0;

-- Обновление нескольких столбцов
UPDATE players
SET
    is_active = TRUE,
    is_blocked = FALSE,
    block_reason = NULL,
    updated_at = CURRENT_TIMESTAMP
WHERE username = 'ivan_gamer';

-- Обновление с подзапросом
UPDATE questions
SET difficulty = (
    SELECT AVG(difficulty)
    FROM questions q2
    WHERE q2.category_id = questions.category_id
)
WHERE id IN (SELECT id FROM questions WHERE category_id = 1);

-- Обновление с JOIN
UPDATE game_sessions gs
JOIN players p ON gs.player_id = p.id
SET gs.status = 'completed'
WHERE p.username = 'ivan_gamer'
  AND gs.status = 'in_progress';

-- Обновление с CASE
UPDATE questions
SET status = CASE
    WHEN difficulty < 3.0 THEN 'easy'
    WHEN difficulty < 7.0 THEN 'medium'
    ELSE 'hard'
END;
```

---

## 5. Удаление данных (DELETE)

### Базовый синтаксис DELETE

**Синтаксис DELETE:**
```sql
-- Удаление из одной таблицы
DELETE [LOW_PRIORITY] [QUICK] [IGNORE] FROM table_name [AS alias]
[WHERE condition]
[ORDER BY column [ASC|DESC]]
[LIMIT row_count];

-- Удаление из нескольких таблиц (с JOIN)
DELETE [LOW_PRIORITY] [QUICK] [IGNORE]
    table1_alias [, table2_alias ...]
FROM table1 [AS alias1]
    JOIN table2 [AS alias2] ON join_condition
    [JOIN table3 ON join_condition ...]
[WHERE condition]
[LIMIT row_count];
```

**Параметры:**
- `LOW_PRIORITY` — отложить выполнение до завершения чтений
- `QUICK` — не объединять индексы (быстрее для MyISAM)
- `IGNORE` — игнорировать ошибки удаления
- `WHERE` — условие для выбора строк (без него удалятся ВСЕ строки!)
- `ORDER BY` — порядок удаления строк
- `LIMIT` — ограничить количество удаляемых строк
- `table1_alias` — псевдонимы таблиц для удаления из нескольких

**Важно:**
- Всегда используйте WHERE, если не хотите удалить все строки
- При удалении с JOIN укажите, из каких таблиц удалять
- FOREIGN KEY с ON DELETE CASCADE автоматически удалит дочерние строки

### Примеры DELETE

```sql
-- Удаление по условию
DELETE FROM session_answers
WHERE is_correct = FALSE
  AND created_at < DATE_SUB(CURDATE(), INTERVAL 3 YEAR);

-- Удаление с JOIN
DELETE gs, sa
FROM game_sessions gs
LEFT JOIN session_answers sa ON gs.id = sa.session_id
WHERE gs.player_id = 1
  AND gs.status = 'completed';

-- Удаление дубликатов
DELETE p1 FROM players p1
INNER JOIN players p2
WHERE p1.id > p2.id
  AND p1.email = p2.email;
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

**Синтаксис SELECT:**
```sql
SELECT
    [ALL | DISTINCT | DISTINCTROW]
    [HIGH_PRIORITY]
    [STRAIGHT_JOIN]
    [SQL_SMALL_RESULT] [SQL_BIG_RESULT] [SQL_BUFFER_RESULT]
    [SQL_CACHE | SQL_NO_CACHE] [SQL_CALC_FOUND_ROWS]
    select_expression [, select_expression ...]
FROM table_reference
[WHERE where_condition]
[GROUP BY {col_name | expr | position} [ASC | DESC], ...]
    [WITH ROLLUP]
[HAVING where_condition]
[ORDER BY {col_name | expr | position} [ASC | DESC], ...]
[LIMIT {[offset,] row_count | row_count OFFSET offset}]
[PROCEDURE procedure_name]
[INTO OUTFILE | DUMPFILE | INFILE]
[FOR UPDATE | LOCK IN SHARE MODE];
```

**Основные параметры:**
- `ALL` — все строки (по умолчанию)
- `DISTINCT` — только уникальные строки
- `HIGH_PRIORITY` — высокий приоритет выполнения
- `SQL_CALC_FOUND_ROWS` — подсчитать общее количество строк
- `WHERE` — фильтрация строк
- `GROUP BY` — группировка результатов
- `HAVING` — фильтрация групп
- `ORDER BY` — сортировка результатов
- `LIMIT` — ограничение количества строк
- `OFFSET` — пропустить N строк перед началом
- `FOR UPDATE` — блокировка выбранных строк

**Порядок выполнения:**
1. FROM — выборка таблиц
2. WHERE — фильтрация строк
3. GROUP BY — группировка
4. HAVING — фильтрация групп
5. SELECT — выборка столбцов
6. ORDER BY — сортировка
7. LIMIT — ограничение

### Примеры SELECT

```sql
-- Выборка всех столбцов
SELECT * FROM questions;

-- Выборка конкретных столбцов
SELECT question_text, difficulty, points FROM questions;

-- Выборка с псевдонимами
SELECT
    question_text AS "Вопрос",
    difficulty AS "Сложность",
    points AS "Очки"
FROM questions;

-- DISTINCT - уникальные значения
SELECT DISTINCT category_id FROM questions;

-- Выборка с вычислениями
SELECT
    question_text,
    points,
    points * 1.5 AS bonus_points
FROM questions;

-- Выборка с функциями
SELECT
    category_id,
    COUNT(*) AS question_count,
    AVG(difficulty) AS avg_difficulty,
    MAX(points) AS max_points
FROM questions
GROUP BY category_id
HAVING question_count > 1
ORDER BY question_count DESC;
```

---

## 7. Предикаты

### Предикаты сравнения

```sql
-- Равенство и неравенство
SELECT * FROM questions WHERE points = 10;
SELECT * FROM questions WHERE points != 10;
SELECT * FROM questions WHERE points <> 10;

-- Сравнение с диапазоном
SELECT * FROM questions WHERE difficulty BETWEEN 1 AND 5;
SELECT * FROM questions WHERE difficulty NOT BETWEEN 1 AND 5;

-- Сравнение со списком
SELECT * FROM questions WHERE status IN ('active', 'draft');
SELECT * FROM questions WHERE status NOT IN ('archived', 'deleted');

-- Сравнение с NULL
SELECT * FROM players WHERE email IS NULL;
SELECT * FROM players WHERE email IS NOT NULL;

-- Сравнение с шаблоном (LIKE)
SELECT * FROM questions WHERE question_text LIKE 'Что%';
SELECT * FROM questions WHERE question_text LIKE '%столица%';
SELECT * FROM questions WHERE question_text LIKE '_то%';
SELECT * FROM questions WHERE slug LIKE 'hist_-_';

-- Регулярные выражения (REGEXP)
SELECT * FROM questions WHERE question_text REGEXP '^[А-Я]';
SELECT * FROM players WHERE email REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
```

### Логические операторы

```sql
-- AND
SELECT * FROM questions
WHERE points > 5 AND difficulty > 5.0;

-- OR
SELECT * FROM questions
WHERE status = 'active' OR status = 'draft';

-- NOT
SELECT * FROM questions
WHERE NOT status = 'archived';

-- Комбинация
SELECT * FROM questions
WHERE (points > 5 AND difficulty > 5.0)
   OR status = 'featured';
```

### EXISTS и NOT EXISTS

```sql
-- EXISTS - проверка существования
SELECT * FROM categories c
WHERE EXISTS (
    SELECT 1 FROM questions q
    WHERE q.category_id = c.id
    AND q.status = 'active'
);

-- NOT EXISTS
SELECT * FROM categories c
WHERE NOT EXISTS (
    SELECT 1 FROM questions q
    WHERE q.category_id = c.id
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
    q.question_text,
    c.name AS category_name,
    c.slug
FROM questions q
INNER JOIN categories c ON q.category_id = c.id;

-- LEFT JOIN (левое соединение)
SELECT
    p.username,
    p.email,
    gs.score,
    gs.status
FROM players p
LEFT JOIN game_sessions gs ON p.id = gs.player_id AND gs.status = 'in_progress';

-- RIGHT JOIN (правое соединение)
SELECT
    c.name,
    q.question_text
FROM categories c
RIGHT JOIN questions q ON c.id = q.category_id;

-- Множественное соединение
SELECT
    p.username,
    p.email,
    q.question_text,
    sa.selected_answer_id,
    sa.is_correct,
    gs.score
FROM session_answers sa
JOIN players p ON sa.session_id = gs.id
JOIN game_sessions gs ON sa.session_id = gs.id
JOIN questions q ON sa.question_id = q.id
WHERE gs.status = 'completed';

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
SELECT username, email, 'player' AS type FROM players
UNION
SELECT username, email, 'admin' AS type FROM admins;

-- UNION ALL (все строки, включая дубликаты)
SELECT question_id FROM session_answers WHERE is_correct = TRUE
UNION ALL
SELECT question_id FROM session_answers WHERE is_correct = FALSE;
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
