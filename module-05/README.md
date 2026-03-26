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

**Синтаксис UNION:**
```sql
-- Базовый синтаксис
SELECT columns FROM table1
UNION [ALL | DISTINCT]
SELECT columns FROM table2
[UNION [ALL | DISTINCT] SELECT columns FROM table3 ...]
[ORDER BY column [ASC|DESC]]
[LIMIT [offset,] row_count];
```

**Параметры:**
- `UNION` — объединить результаты с удалением дубликатов (по умолчанию DISTINCT)
- `UNION ALL` — объединить все строки, включая дубликаты (быстрее)
- `UNION DISTINCT` — явно указать удаление дубликатов
- `ORDER BY` — сортировка итогового результата
- `LIMIT` — ограничение количества строк в результате

**Требования к UNION:**
- Одинаковое количество столбцов в каждом SELECT
- Совместимые типы данных соответствующих столбцов
- Псевдонимы столбцов берутся из первого SELECT
- Порядок столбцов должен совпадать

**Производительность:**
- `UNION ALL` быстрее, так как не удаляет дубликаты
- `UNION` требует сортировки для удаления дубликатов
- Используйте `UNION ALL`, если дубликатов нет или они не важны

### Примеры UNION

---

## 2. Подзапросы

**Синтаксис подзапросов:**
```sql
-- Подзапрос в WHERE
SELECT columns FROM table
WHERE column [NOT] IN (SELECT column FROM table WHERE condition);

WHERE column [operator] (SELECT column FROM table);
-- operator: =, !=, <, <=, >, >=, ANY, SOME, ALL

-- Подзапрос в FROM (производная таблица)
SELECT outer_columns
FROM (SELECT inner_columns FROM table WHERE condition) AS alias
WHERE outer_condition;

-- Подзапрос в SELECT (скалярный подзапрос)
SELECT
    column,
    (SELECT aggregate_function(column) FROM table WHERE condition) AS alias
FROM table;

-- Коррелированный подзапрос
SELECT outer_columns
FROM table AS outer
WHERE EXISTS (
    SELECT 1 FROM table AS inner
    WHERE inner.foreign_key = outer.primary_key
);
```

**Типы подзапросов:**
- **Одиночный** — возвращает одно значение (скалярный)
- **Строковый** — возвращает одну строку
- **Табличный** — возвращает таблицу
- **Коррелированный** — зависит от внешнего запроса
- **Некоррелированный** — выполняется один раз

**Параметры:**
- `IN` — проверка вхождения в список значений
- `NOT IN` — проверка отсутствия в списке
- `ANY/SOME` — сравнение с любым значением из списка
- `ALL` — сравнение со всеми значениями
- `EXISTS` — проверка существования строк
- `NOT EXISTS` — проверка отсутствия строк

**Производительность:**
- Коррелированные подзапросы выполняются для каждой строки внешнего запроса
- Часто можно заменить на JOIN для лучшей производительности
- EXISTS быстрее IN для больших наборов данных

### Подзапросы в WHERE

```sql
-- IN: значение в списке
SELECT * FROM questions
WHERE category_id IN (SELECT id FROM categories WHERE slug LIKE 'hist%');

-- NOT IN: значение не в списке
SELECT * FROM players
WHERE id NOT IN (SELECT DISTINCT player_id FROM game_sessions WHERE status = 'completed');

-- Сравнение с подзапросом
SELECT * FROM questions
WHERE points > (SELECT AVG(points) FROM questions);

-- ANY/SOME: сравнение с любым значением
SELECT * FROM questions
WHERE points > SOME (SELECT points FROM questions WHERE category_id = 1);

-- ALL: сравнение со всеми значениями
SELECT * FROM questions
WHERE points > ALL (SELECT points FROM questions WHERE category_id = 1);
```

### Подзапросы в FROM

```sql
-- Подзапрос как таблица
SELECT
    category_name,
    avg_difficulty
FROM (
    SELECT
        c.name AS category_name,
        AVG(q.difficulty) AS avg_difficulty
    FROM questions q
    JOIN categories c ON q.category_id = c.id
    GROUP BY c.id
) AS category_stats
WHERE avg_difficulty > 5.0;
```

### Подзапросы в SELECT

```sql
-- Скалярный подзапрос
SELECT
    q.question_text,
    (SELECT COUNT(*) FROM session_answers sa WHERE sa.question_id = q.id) AS answer_count,
    (SELECT AVG(is_correct) FROM session_answers sa WHERE sa.question_id = q.id) AS correct_rate
FROM questions q;
```

### Коррелированные подзапросы

```sql
-- Подзапрос зависит от внешнего запроса
SELECT
    p.username,
    p.email,
    (SELECT COUNT(*) FROM game_sessions gs WHERE gs.player_id = p.id) AS total_games
FROM players p;

-- С EXISTS
SELECT * FROM players p
WHERE EXISTS (
    SELECT 1 FROM game_sessions gs
    WHERE gs.player_id = p.id
    AND gs.score > 1000
);
```

---

## 3. Оператор EXISTS

**Синтаксис EXISTS:**
```sql
-- Проверка существования строк
SELECT columns FROM table
WHERE [NOT] EXISTS (
    SELECT 1 FROM related_table
    WHERE related_table.foreign_key = table.primary_key
    [AND additional_conditions]
);
```

**Параметры:**
- `EXISTS` — возвращает TRUE если подзапрос вернул хотя бы одну строку
- `NOT EXISTS` — возвращает TRUE если подзапрос не вернул ни одной строки
- `SELECT 1` — стандартный паттерн, выбираем константу (не важно что выбирать)

**Особенности:**
- EXISTS возвращает BOOLEAN (TRUE/FALSE)
- Подзапрос выполняется для каждой строки внешнего запроса
- Обычно быстрее чем IN для больших наборов данных
- Полезен для проверки связей между таблицами

**EXISTS vs IN:**
- `EXISTS` — проверка существования, быстрее на больших данных
- `IN` — проверка вхождения, лучше для маленьких списков
- `NOT EXISTS` — проверка отсутствия, быстрее чем `NOT IN`

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
-- Игроки с активными сессиями
SELECT * FROM players p
WHERE EXISTS (
    SELECT 1 FROM game_sessions gs
    WHERE gs.player_id = p.id
    AND gs.status = 'in_progress'
);

-- Категории без вопросов
SELECT * FROM categories c
WHERE NOT EXISTS (
    SELECT 1 FROM questions q WHERE q.category_id = c.id
);

-- Игроки без игровых сессий
SELECT * FROM players p
WHERE NOT EXISTS (
    SELECT 1 FROM game_sessions gs WHERE gs.player_id = p.id
);
```

---

## 4. Представления (VIEW)

**Синтаксис CREATE VIEW:**
```sql
-- Создание представления
CREATE [OR REPLACE]
[ALGORITHM = {UNDEFINED | MERGE | TEMPTABLE}]
[DEFINER = {user | CURRENT_USER}]
[SQL SECURITY {DEFINER | INVOKER}]
VIEW view_name [(column_list)]
AS select_statement
[WITH [CASCADED | LOCAL] CHECK OPTION];

-- Обновление представления
CREATE OR REPLACE VIEW view_name AS select_statement;

-- Удаление представления
DROP VIEW [IF EXISTS] view_name [, view_name ...];

-- Показать создание представления
SHOW CREATE VIEW view_name;

-- Показать все представления
SHOW FULL TABLES WHERE TABLE_TYPE = 'VIEW';
```

**Параметры:**
- `OR REPLACE` — заменить существующее представление
- `ALGORITHM` — алгоритм выполнения:
  - `UNDEFINED` — MySQL выбирает автоматически (по умолчанию)
  - `MERGE` — сливает запрос с представлением (быстрее)
  - `TEMPTABLE` — создаёт временную таблицу (медленнее)
- `DEFINER` — пользователь от имени которого выполняется представление
- `SQL SECURITY` — чьи привилегии использовать (DEFINER или INVOKER)
- `WITH CHECK OPTION` — проверять данные при вставке/обновлении через VIEW

**Типы представлений:**
- **Простые** — один SELECT без GROUP BY, агрегатов
- **Сложные** — с JOIN, GROUP BY, агрегатными функциями
- **Обновляемые** — можно делать INSERT/UPDATE/DELETE
- **Только для чтения** — нельзя изменять данные

**Ограничения:**
- Нельзя использовать ORDER BY без LIMIT
- Нельзя использовать GROUP BY с агрегатами для обновляемых VIEW
- Нельзя использовать подзапросы в FROM
- Нельзя использовать временные таблицы

**Преимущества:**
- Упрощение сложных запросов
- Безопасность (доступ только к определённым столбцам)
- Сокрытие сложности структуры БД
- Переиспользование кода

### Создание представлений

```sql
-- Простое представление
CREATE VIEW v_active_questions AS
SELECT
    q.id,
    q.question_text,
    q.difficulty,
    q.points,
    c.name AS category_name
FROM questions q
JOIN categories c ON q.category_id = c.id
WHERE q.status = 'active';

-- Представление с группировкой
CREATE VIEW v_player_stats AS
SELECT
    p.id,
    p.username,
    p.email,
    COUNT(gs.id) AS total_games,
    SUM(gs.score) AS total_score,
    AVG(gs.score) AS avg_score
FROM players p
LEFT JOIN game_sessions gs ON p.id = gs.player_id
GROUP BY p.id;

-- Представление с вычислениями
CREATE VIEW v_completed_sessions AS
SELECT
    gs.id,
    p.username,
    p.email,
    c.name AS category_name,
    gs.score,
    gs.status,
    CASE
        WHEN gs.score > 1000 THEN 'excellent'
        WHEN gs.score > 500 THEN 'good'
        ELSE 'needs_improvement'
    END AS performance
FROM game_sessions gs
JOIN players p ON gs.player_id = p.id
JOIN categories c ON gs.category_id = c.id
WHERE gs.status = 'completed';
```

### Использование представлений

```sql
-- Запрос к представлению
SELECT * FROM v_active_questions WHERE category_name = 'История';

-- Объединение представлений
SELECT * FROM v_player_stats
JOIN v_completed_sessions ON v_player_stats.id = v_completed_sessions.player_id;
```

### Обновляемые представления

```sql
-- Представление можно обновлять, если:
-- 1. Один источник данных
-- 2. Нет GROUP BY, DISTINCT, агрегатных функций
-- 3. Нет подзапросов в SELECT

CREATE VIEW v_active_players AS
SELECT id, username, email, total_score
FROM players
WHERE is_active = TRUE;

-- Обновление через представление
UPDATE v_active_players
SET email = 'new@email.com'
WHERE id = 1;
```

---

## 5. Ограничения представлений

### Что нельзя делать в представлениях

```sql
-- ОШИБКА: нельзя с ORDER BY без LIMIT
CREATE VIEW v_questions_sorted AS
SELECT * FROM questions ORDER BY difficulty;

-- ПРАВИЛЬНО: с LIMIT
CREATE VIEW v_questions_sorted AS
SELECT * FROM questions ORDER BY difficulty LIMIT 100;

-- ОШИБКА: нельзя с GROUP BY и обновлением
CREATE VIEW v_question_stats AS
SELECT category_id, COUNT(*) AS cnt FROM questions GROUP BY category_id;
-- Нельзя UPDATE/INSERT/DELETE через это представление
```

### Материал представления

```sql
-- Обычное представление (вычисляется при запросе)
CREATE VIEW v_stats AS SELECT ...;

-- В MySQL нет материализованных представлений
-- Но можно использовать таблицы для кэширования
CREATE TABLE m_question_stats AS
SELECT category_id, COUNT(*) AS cnt FROM questions GROUP BY category_id;
```

### Управление представлениями

```sql
-- Показать создания представления
SHOW CREATE VIEW v_active_questions;

-- Обновить представление
CREATE OR REPLACE VIEW v_active_questions AS
SELECT ... новый запрос ...;

-- Удалить представление
DROP VIEW IF EXISTS v_active_questions;

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
