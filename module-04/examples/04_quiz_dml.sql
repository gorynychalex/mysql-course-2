-- ============================================================================
-- Module 4: DML Examples - Quiz Theme
-- ============================================================================
-- CRUD-операции, выборка данных, предикаты, объединения
-- ============================================================================

DROP DATABASE IF EXISTS quiz_dml_db;
CREATE DATABASE quiz_dml_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quiz_dml_db;

-- ----------------------------------------------------------------------------
-- 1. Создание структуры базы данных
-- ----------------------------------------------------------------------------

CREATE TABLE categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE questions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    question_text TEXT NOT NULL,
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    points DECIMAL(5,2) DEFAULT 1.00,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    question_id INT UNSIGNED NOT NULL,
    answer_text VARCHAR(500) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    display_order TINYINT DEFAULT 1,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE players (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    total_score INT DEFAULT 0,
    games_played INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE game_sessions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    player_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    score INT DEFAULT 0,
    status ENUM('active', 'completed', 'abandoned') DEFAULT 'active',
    FOREIGN KEY (player_id) REFERENCES players(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE session_answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id INT UNSIGNED NOT NULL,
    question_id INT UNSIGNED NOT NULL,
    answer_id INT UNSIGNED,
    is_correct BOOLEAN DEFAULT FALSE,
    points_earned DECIMAL(5,2) DEFAULT 0,
    response_time_seconds INT,
    FOREIGN KEY (session_id) REFERENCES game_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (answer_id) REFERENCES answers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- 2. INSERT - Вставка данных
-- ----------------------------------------------------------------------------

-- Вставка категорий
INSERT INTO categories (name, description, is_active) VALUES
('SQL Basics', 'Основные операторы SQL', TRUE),
('Database Design', 'Проектирование баз данных', TRUE),
('MySQL Admin', 'Администрирование MySQL', TRUE),
('Security', 'Безопасность баз данных', TRUE),
('Performance', 'Оптимизация и производительность', FALSE);

-- Вставка вопросов
INSERT INTO questions (category_id, question_text, difficulty, points, status) VALUES
(1, 'Какой оператор выбирает данные?', 'easy', 1.00, 'published'),
(1, 'Что означает SQL?', 'easy', 1.00, 'published'),
(1, 'Как создать таблицу?', 'medium', 2.00, 'published'),
(2, 'Что такое нормализация?', 'medium', 2.00, 'published'),
(2, 'Какая форма устраняет транзитивные зависимости?', 'hard', 3.00, 'published'),
(3, 'Порт MySQL по умолчанию?', 'easy', 1.00, 'published'),
(3, 'Утилита для бэкапа?', 'medium', 2.00, 'published'),
(4, 'Что такое SQL-инъекция?', 'hard', 3.00, 'published'),
(4, 'Команда предоставления прав?', 'medium', 2.00, 'draft'),
(5, 'Что такое индекс?', 'medium', 2.00, 'published');

-- Вставка ответов (несколько для каждого вопроса)
INSERT INTO answers (question_id, answer_text, is_correct, display_order) VALUES
-- Вопрос 1
(1, 'SELECT', TRUE, 1),
(1, 'INSERT', FALSE, 2),
(1, 'UPDATE', FALSE, 3),
(1, 'CREATE', FALSE, 4),
-- Вопрос 2
(2, 'Structured Query Language', TRUE, 1),
(2, 'Simple Question Language', FALSE, 2),
(2, 'System Query Logic', FALSE, 3),
(2, 'Standard Question List', FALSE, 4),
-- Вопрос 3
(3, 'CREATE TABLE', TRUE, 1),
(3, 'NEW TABLE', FALSE, 2),
(3, 'ADD TABLE', FALSE, 3),
(3, 'MAKE TABLE', FALSE, 4),
-- Вопрос 4
(4, 'Процесс организации данных для уменьшения избыточности', TRUE, 1),
(4, 'Создание резервных копий', FALSE, 2),
(4, 'Шифрование данных', FALSE, 3),
(4, 'Оптимизация запросов', FALSE, 4),
-- Вопрос 5
(5, '3NF', TRUE, 1),
(5, '2NF', FALSE, 2),
(5, '1NF', FALSE, 3),
(5, 'BCNF', FALSE, 4),
-- Вопрос 6
(6, '3306', TRUE, 1),
(6, '3307', FALSE, 2),
(6, '5432', FALSE, 3),
(6, '1433', FALSE, 4),
-- Вопрос 7
(7, 'mysqldump', TRUE, 1),
(7, 'mysqlbackup', FALSE, 2),
(7, 'mysqlcopy', FALSE, 3),
(7, 'dbexport', FALSE, 4),
-- Вопрос 8
(8, 'Уязвимость для выполнения вредоносного SQL-кода', TRUE, 1),
(8, 'Метод шифрования', FALSE, 2),
(8, 'Тип индекса', FALSE, 3),
(8, 'Функция MySQL', FALSE, 4),
-- Вопрос 9
(9, 'GRANT', TRUE, 1),
(9, 'ALLOW', FALSE, 2),
(9, 'PERMIT', FALSE, 3),
(9, 'AUTHORIZE', FALSE, 4),
-- Вопрос 10
(10, 'Структура для ускорения поиска', TRUE, 1),
(10, 'Список таблиц', FALSE, 2),
(10, 'Резервная копия', FALSE, 3),
(10, 'Пользователь БД', FALSE, 4);

-- Вставка игроков
INSERT INTO players (username, email, total_score, games_played) VALUES
('alex_quiz', 'alex@example.com', 150, 10),
('maria_pro', 'maria@example.com', 280, 25),
('ivan_mysql', 'ivan@example.com', 95, 8),
('olga_db', 'olga@example.com', 320, 30),
('petr_sql', 'petr@example.com', 45, 3);

-- ----------------------------------------------------------------------------
-- 3. UPDATE - Обновление данных
-- ----------------------------------------------------------------------------

-- Обновление статуса категории
UPDATE categories SET is_active = TRUE WHERE id = 5;

-- Обновление очков для сложных вопросов
UPDATE questions SET points = 3.00 WHERE difficulty = 'hard';
UPDATE questions SET points = 2.00 WHERE difficulty = 'medium';

-- Обновление статуса вопроса
UPDATE questions SET status = 'published' WHERE status = 'draft';

-- Обновление статистики игрока
UPDATE players 
SET total_score = total_score + 50, games_played = games_played + 1
WHERE username = 'alex_quiz';

-- Обновление с CASE
UPDATE questions 
SET status = CASE 
    WHEN difficulty = 'easy' THEN 'published'
    WHEN difficulty = 'medium' THEN 'published'
    ELSE 'draft'
END;

-- ----------------------------------------------------------------------------
-- 4. SELECT - Выборка данных
-- ----------------------------------------------------------------------------

-- Простая выборка
SELECT * FROM categories;
SELECT name, description FROM categories WHERE is_active = TRUE;

-- Выборка с DISTINCT
SELECT DISTINCT difficulty FROM questions;

-- Выборка с вычислениями
SELECT 
    question_text,
    points,
    points * 1.1 AS points_with_bonus
FROM questions;

-- Агрегатные функции
SELECT 
    difficulty,
    COUNT(*) AS question_count,
    AVG(points) AS avg_points,
    MIN(points) AS min_points,
    MAX(points) AS max_points,
    SUM(points) AS total_points
FROM questions
GROUP BY difficulty;

-- GROUP BY с HAVING
SELECT 
    difficulty,
    COUNT(*) AS cnt
FROM questions
GROUP BY difficulty
HAVING cnt > 2;

-- ORDER BY
SELECT * FROM players ORDER BY total_score DESC LIMIT 5;

-- Выборка с LIMIT и OFFSET
SELECT * FROM questions LIMIT 5 OFFSET 0;
SELECT * FROM questions LIMIT 5, 5;

-- ----------------------------------------------------------------------------
-- 5. Предикаты
-- ----------------------------------------------------------------------------

-- Сравнение
SELECT * FROM questions WHERE points > 2;
SELECT * FROM questions WHERE points != 2;

-- BETWEEN
SELECT * FROM questions WHERE points BETWEEN 1.5 AND 2.5;

-- IN
SELECT * FROM questions WHERE difficulty IN ('easy', 'medium');
SELECT * FROM questions WHERE difficulty NOT IN ('hard');

-- LIKE
SELECT * FROM questions WHERE question_text LIKE 'Какой%';
SELECT * FROM questions WHERE question_text LIKE '%данных%';
SELECT * FROM questions WHERE question_text LIKE 'Что_____';

-- IS NULL / IS NOT NULL
SELECT * FROM game_sessions WHERE ended_at IS NULL;
SELECT * FROM game_sessions WHERE ended_at IS NOT NULL;

-- REGEXP
SELECT * FROM questions WHERE question_text REGEXP '^[КЧ]';

-- EXISTS
SELECT * FROM categories c
WHERE EXISTS (
    SELECT 1 FROM questions q WHERE q.category_id = c.id
);

SELECT * FROM categories c
WHERE NOT EXISTS (
    SELECT 1 FROM questions q WHERE q.category_id = c.id
);

-- ----------------------------------------------------------------------------
-- 6. JOIN - Объединения таблиц
-- ----------------------------------------------------------------------------

-- INNER JOIN
SELECT 
    q.question_text,
    c.name AS category_name,
    q.difficulty,
    q.points
FROM questions q
INNER JOIN categories c ON q.category_id = c.id
ORDER BY c.name, q.difficulty;

-- LEFT JOIN (все вопросы с ответами)
SELECT 
    q.id,
    q.question_text,
    a.answer_text,
    a.is_correct
FROM questions q
LEFT JOIN answers a ON q.id = a.question_id
ORDER BY q.id, a.display_order;

-- Множественное соединение
SELECT 
    q.question_text,
    c.name AS category,
    COUNT(a.id) AS answer_count,
    SUM(CASE WHEN a.is_correct THEN 1 ELSE 0 END) AS correct_answers
FROM questions q
JOIN categories c ON q.category_id = c.id
LEFT JOIN answers a ON q.id = a.question_id
GROUP BY q.id, c.name;

-- SELF JOIN (для иерархии, если бы была parent_id)
-- SELECT c.name, p.name AS parent FROM categories c LEFT JOIN categories p ON c.parent_id = p.id;

-- Игроки с их сессиями
SELECT 
    p.username,
    p.total_score,
    gs.started_at,
    gs.score AS session_score,
    gs.status
FROM players p
LEFT JOIN game_sessions gs ON p.id = gs.player_id
ORDER BY p.username, gs.started_at DESC;

-- ----------------------------------------------------------------------------
-- 7. UNION - Объединение результатов
-- ----------------------------------------------------------------------------

-- UNION для списка активных сущностей
SELECT name AS entity_name, 'category' AS type FROM categories WHERE is_active = TRUE
UNION ALL
SELECT username, 'player' FROM players WHERE is_active = TRUE
UNION ALL
SELECT question_text, 'question' FROM questions WHERE status = 'published'
ORDER BY type, entity_name;

-- ----------------------------------------------------------------------------
-- 8. DELETE - Удаление данных
-- ----------------------------------------------------------------------------

-- Удаление неактивных категорий без вопросов
DELETE FROM categories 
WHERE is_active = FALSE 
  AND id NOT IN (SELECT DISTINCT category_id FROM questions);

-- Удаление черновиков
-- DELETE FROM questions WHERE status = 'draft';

-- Удаление с JOIN (каскадное через FOREIGN KEY)
-- DELETE q, a FROM questions q 
-- LEFT JOIN answers a ON q.id = a.question_id 
-- WHERE q.id = 1;

-- ----------------------------------------------------------------------------
-- 9. INSERT ... SELECT
-- ----------------------------------------------------------------------------

-- Копирование вопросов в новую категорию
INSERT INTO questions (category_id, question_text, difficulty, points, status)
SELECT 5, question_text, difficulty, points, status
FROM questions
WHERE category_id = 1;

-- ----------------------------------------------------------------------------
-- 10. Сложные запросы для демонстрации
-- ----------------------------------------------------------------------------

-- Топ игроков с детализацией
SELECT 
    p.username,
    p.total_score,
    p.games_played,
    ROUND(p.total_score / NULLIF(p.games_played, 0), 2) AS avg_score_per_game,
    (SELECT COUNT(*) FROM game_sessions gs WHERE gs.player_id = p.id AND gs.status = 'completed') AS completed_games
FROM players p
WHERE p.is_active = TRUE
ORDER BY p.total_score DESC
LIMIT 10;

-- Статистика по категориям
SELECT 
    c.name AS category,
    COUNT(DISTINCT q.id) AS total_questions,
    COUNT(DISTINCT CASE WHEN q.status = 'published' THEN q.id END) AS published_questions,
    ROUND(AVG(q.points), 2) AS avg_points,
    COUNT(DISTINCT a.id) AS total_answers,
    COUNT(DISTINCT CASE WHEN a.is_correct THEN a.id END) AS correct_answers
FROM categories c
LEFT JOIN questions q ON c.id = q.category_id
LEFT JOIN answers a ON q.id = a.question_id
GROUP BY c.id, c.name
ORDER BY total_questions DESC;

-- Вопросы без правильных ответов (ошибка в данных)
SELECT q.id, q.question_text
FROM questions q
LEFT JOIN answers a ON q.id = a.question_id AND a.is_correct = TRUE
WHERE a.id IS NULL;

-- ----------------------------------------------------------------------------
-- 11. Транзакция для игровой сессии
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Создание новой сессии
INSERT INTO game_sessions (player_id, category_id, score, status)
VALUES (1, 1, 0, 'active');

-- Получение ID сессии
SET @session_id = LAST_INSERT_ID();

-- Добавление ответов в сессию
INSERT INTO session_answers (session_id, question_id, answer_id, is_correct, points_earned, response_time_seconds)
VALUES 
    (@session_id, 1, 1, TRUE, 1.00, 15),
    (@session_id, 2, 5, TRUE, 1.00, 20),
    (@session_id, 3, 9, FALSE, 0, 30);

-- Обновление счёта сессии
UPDATE game_sessions 
SET score = (SELECT SUM(points_earned) FROM session_answers WHERE session_id = @session_id),
    status = 'completed',
    ended_at = NOW()
WHERE id = @session_id;

-- Обновление статистики игрока
UPDATE players 
SET total_score = total_score + (SELECT SUM(points_earned) FROM session_answers WHERE session_id = @session_id),
    games_played = games_played + 1
WHERE id = 1;

COMMIT;

-- ----------------------------------------------------------------------------
-- Очистка
-- ----------------------------------------------------------------------------
-- DROP DATABASE quiz_dml_db;
