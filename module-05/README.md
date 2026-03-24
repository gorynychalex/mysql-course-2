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
-- Объединение списков игроков
SELECT username, email, 'player' AS type FROM players
UNION
SELECT username, email, 'admin' AS type FROM admins
ORDER BY email;

-- Поиск по нескольким таблицам
SELECT question_id, 'session' AS source, created_at AS date FROM session_answers
UNION ALL
SELECT question_id, 'practice' AS source, created_at AS date FROM practice_answers
ORDER BY date DESC;

-- UNION с разным количеством столбцов
SELECT id, question_text, category_id, NULL AS reason FROM questions
UNION ALL
SELECT id, question_text, category_id, ban_reason FROM banned_questions;
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
