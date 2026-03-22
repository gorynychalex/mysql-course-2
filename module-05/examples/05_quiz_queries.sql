-- ============================================================================
-- Module 5: UNION, Subqueries, EXISTS, Views - Quiz Theme
-- ============================================================================

DROP DATABASE IF EXISTS quiz_queries_db;
CREATE DATABASE quiz_queries_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quiz_queries_db;

-- ----------------------------------------------------------------------------
-- 1. Создание структуры
-- ----------------------------------------------------------------------------

CREATE TABLE categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id INT UNSIGNED NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (parent_id) REFERENCES categories(id)
) ENGINE=InnoDB;

CREATE TABLE questions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    question_text TEXT NOT NULL,
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    points DECIMAL(5,2) DEFAULT 1.00,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB;

CREATE TABLE answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    question_id INT UNSIGNED NOT NULL,
    answer_text VARCHAR(500) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE players (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    total_score INT DEFAULT 0,
    games_played INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

CREATE TABLE admins (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    role ENUM('super', 'moderator', 'editor') DEFAULT 'editor',
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE banned_users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    reason VARCHAR(255),
    banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. Тестовые данные
-- ----------------------------------------------------------------------------

INSERT INTO categories (name, parent_id, is_active) VALUES
('Programming', NULL, TRUE),
('Databases', 1, TRUE),
('SQL', 2, TRUE),
('MySQL', 3, TRUE),
('Web Development', NULL, TRUE),
('Frontend', 5, TRUE),
('Backend', 5, TRUE),
('Inactive Category', NULL, FALSE);

INSERT INTO questions (category_id, question_text, difficulty, points, status) VALUES
(3, 'Что означает SQL?', 'easy', 1.00, 'published'),
(3, 'Какой оператор выбирает данные?', 'easy', 1.00, 'published'),
(4, 'Порт MySQL по умолчанию?', 'easy', 1.00, 'published'),
(4, 'Движок по умолчанию в MySQL 8?', 'medium', 2.00, 'published'),
(1, 'Что такое переменная?', 'easy', 1.00, 'published'),
(6, 'Что такое HTML?', 'easy', 1.00, 'published'),
(7, 'Что такое API?', 'medium', 2.00, 'published'),
(3, 'Что такое JOIN?', 'medium', 2.00, 'draft'),
(4, 'Что такое транзакция?', 'hard', 3.00, 'draft'),
(2, 'Что такое нормализация?', 'hard', 3.00, 'archived');

INSERT INTO answers (question_id, answer_text, is_correct) VALUES
(1, 'Structured Query Language', TRUE),
(1, 'Simple Question Language', FALSE),
(2, 'SELECT', TRUE),
(2, 'INSERT', FALSE),
(3, '3306', TRUE),
(3, '3307', FALSE),
(4, 'InnoDB', TRUE),
(4, 'MyISAM', FALSE);

INSERT INTO players (username, email, total_score, games_played) VALUES
('player1', 'p1@test.com', 100, 10),
('player2', 'p2@test.com', 250, 25),
('player3', 'p3@test.com', 50, 5),
('player4', 'p4@test.com', 300, 30),
('player5', 'p5@test.com', 0, 0);

INSERT INTO game_sessions (player_id, category_id, score, status) VALUES
(1, 3, 10, 'completed'),
(1, 4, 15, 'completed'),
(2, 3, 20, 'completed'),
(2, 3, 25, 'active'),
(3, 6, 5, 'completed'),
(4, 3, 30, 'completed'),
(4, 4, 35, 'active');

INSERT INTO admins (username, email, role) VALUES
('admin1', 'admin1@test.com', 'super'),
('admin2', 'admin2@test.com', 'moderator'),
('editor1', 'editor1@test.com', 'editor');

INSERT INTO banned_users (username, reason) VALUES
('cheater1', 'Использование читов'),
('spammer1', 'Спам в чате');

-- ----------------------------------------------------------------------------
-- 3. UNION и UNION ALL
-- ----------------------------------------------------------------------------

-- Объединение пользователей из разных таблиц
SELECT username, email, 'player' AS user_type, registered_at AS created_date 
FROM players WHERE is_active = TRUE
UNION ALL
SELECT username, email, 'admin' AS user_type, NOW() AS created_date 
FROM admins WHERE is_active = TRUE
ORDER BY created_date DESC;

-- Поиск по всем сущностям
SELECT id, name AS entity_name, 'category' AS type FROM categories WHERE is_active = TRUE
UNION ALL
SELECT id, question_text, 'question' FROM questions WHERE status = 'published'
UNION ALL
SELECT id, username, 'player' FROM players WHERE is_active = TRUE
ORDER BY type, entity_name;

-- UNION с вычислениями
SELECT category_id, COUNT(*) AS cnt, 'questions' AS type FROM questions GROUP BY category_id
UNION ALL
SELECT category_id, COUNT(*) AS cnt, 'sessions' AS type FROM game_sessions GROUP BY category_id
ORDER BY category_id, type;

-- ----------------------------------------------------------------------------
-- 4. Подзапросы IN, NOT IN
-- ----------------------------------------------------------------------------

-- Вопросы с определёнными категориями
SELECT * FROM questions 
WHERE category_id IN (SELECT id FROM categories WHERE name LIKE '%SQL%');

-- Игроки без активных сессий
SELECT * FROM players 
WHERE id NOT IN (SELECT DISTINCT player_id FROM game_sessions WHERE status = 'active');

-- Категории без вопросов
SELECT * FROM categories 
WHERE id NOT IN (SELECT DISTINCT category_id FROM questions);

-- Вопросы с очками выше среднего
SELECT * FROM questions 
WHERE points > (SELECT AVG(points) FROM questions WHERE status = 'published');

-- ----------------------------------------------------------------------------
-- 5. Подзапросы с ANY, SOME, ALL
-- ----------------------------------------------------------------------------

-- Вопросы дороже любого вопроса из категории 3
SELECT * FROM questions 
WHERE points > SOME (SELECT points FROM questions WHERE category_id = 3);

-- Вопросы дороже всех вопросов из категории 6
SELECT * FROM questions 
WHERE points > ALL (SELECT points FROM questions WHERE category_id = 6);

-- Вопросы с очками как минимальные в категории 4
SELECT * FROM questions 
WHERE points >= (SELECT MIN(points) FROM questions WHERE category_id = 4);

-- ----------------------------------------------------------------------------
-- 6. EXISTS и NOT EXISTS
-- ----------------------------------------------------------------------------

-- Категории с вопросами
SELECT * FROM categories c
WHERE EXISTS (
    SELECT 1 FROM questions q WHERE q.category_id = c.id
);

-- Категории без вопросов
SELECT * FROM categories c
WHERE NOT EXISTS (
    SELECT 1 FROM questions q WHERE q.category_id = c.id
);

-- Игроки с завершёнными сессиями
SELECT * FROM players p
WHERE EXISTS (
    SELECT 1 FROM game_sessions gs 
    WHERE gs.player_id = p.id AND gs.status = 'completed'
);

-- Игроки без сессий
SELECT * FROM players p
WHERE NOT EXISTS (
    SELECT 1 FROM game_sessions gs WHERE gs.player_id = p.id
);

-- Вопросы без правильных ответов
SELECT * FROM questions q
WHERE NOT EXISTS (
    SELECT 1 FROM answers a WHERE a.question_id = q.id AND a.is_correct = TRUE
);

-- ----------------------------------------------------------------------------
-- 7. Коррелированные подзапросы
-- ----------------------------------------------------------------------------

-- Статистика по категориям
SELECT 
    c.name,
    (SELECT COUNT(*) FROM questions q WHERE q.category_id = c.id) AS question_count,
    (SELECT COUNT(*) FROM questions q WHERE q.category_id = c.id AND q.status = 'published') AS published_count,
    (SELECT AVG(points) FROM questions q WHERE q.category_id = c.id) AS avg_points
FROM categories c;

-- Статистика по игрокам
SELECT 
    p.username,
    (SELECT COUNT(*) FROM game_sessions gs WHERE gs.player_id = p.id) AS total_sessions,
    (SELECT SUM(score) FROM game_sessions gs WHERE gs.player_id = p.id) AS total_score,
    (SELECT AVG(score) FROM game_sessions gs WHERE gs.player_id = p.id AND gs.status = 'completed') AS avg_score
FROM players p;

-- ----------------------------------------------------------------------------
-- 8. Подзапросы в FROM
-- ----------------------------------------------------------------------------

-- Статистика из подзапроса
SELECT 
    category_name,
    question_count,
    avg_points
FROM (
    SELECT 
        c.name AS category_name,
        COUNT(q.id) AS question_count,
        AVG(q.points) AS avg_points
    FROM categories c
    LEFT JOIN questions q ON c.id = q.category_id
    GROUP BY c.id
) AS stats
WHERE question_count > 1
ORDER BY avg_points DESC;

-- Ранжирование игроков
SELECT 
    username,
    total_score,
    games_played,
    ROUND(total_score / games_played, 2) AS avg_per_game,
    @rank := @rank + 1 AS rank
FROM players, (SELECT @rank := 0) r
WHERE games_played > 0
ORDER BY avg_per_game DESC;

-- ----------------------------------------------------------------------------
-- 9. Представления (VIEW)
-- ----------------------------------------------------------------------------

-- Представление: Опубликованные вопросы с ответами
CREATE OR REPLACE VIEW v_published_questions AS
SELECT 
    q.id,
    q.question_text,
    c.name AS category_name,
    q.difficulty,
    q.points,
    q.created_at
FROM questions q
JOIN categories c ON q.category_id = c.id
WHERE q.status = 'published';

-- Представление: Вопросы с ответами
CREATE OR REPLACE VIEW v_questions_with_answers AS
SELECT 
    q.id AS question_id,
    q.question_text,
    q.difficulty,
    a.id AS answer_id,
    a.answer_text,
    a.is_correct
FROM questions q
LEFT JOIN answers a ON q.id = a.question_id
ORDER BY q.id, a.id;

-- Представление: Статистика игроков
CREATE OR REPLACE VIEW v_player_stats AS
SELECT 
    p.id,
    p.username,
    p.email,
    p.total_score,
    p.games_played,
    ROUND(p.total_score / NULLIF(p.games_played, 0), 2) AS avg_score_per_game,
    (SELECT COUNT(*) FROM game_sessions gs WHERE gs.player_id = p.id AND gs.status = 'completed') AS completed_games,
    (SELECT COUNT(*) FROM game_sessions gs WHERE gs.player_id = p.id AND gs.status = 'active') AS active_games
FROM players p
WHERE p.is_active = TRUE;

-- Представление: Активные сессии
CREATE OR REPLACE VIEW v_active_sessions AS
SELECT 
    gs.id,
    p.username,
    c.name AS category_name,
    gs.started_at,
    gs.score,
    TIMESTAMPDIFF(MINUTE, gs.started_at, NOW()) AS minutes_active
FROM game_sessions gs
JOIN players p ON gs.player_id = p.id
LEFT JOIN categories c ON gs.category_id = c.id
WHERE gs.status = 'active';

-- Представление: Топ игроков
CREATE OR REPLACE VIEW v_top_players AS
SELECT 
    id,
    username,
    total_score,
    games_played
FROM players
WHERE is_active = TRUE
ORDER BY total_score DESC
LIMIT 10;

-- Использование представлений
SELECT * FROM v_published_questions WHERE difficulty = 'easy';
SELECT * FROM v_player_stats ORDER BY total_score DESC;
SELECT * FROM v_active_sessions;

-- Объединение представлений
SELECT 
    ps.username,
    ps.total_score,
    ps.avg_score_per_game,
    COUNT(vs.id) AS currently_active_sessions
FROM v_player_stats ps
LEFT JOIN v_active_sessions vs ON ps.username = vs.username
GROUP BY ps.id;

-- ----------------------------------------------------------------------------
-- 10. Ограничения представлений
-- ----------------------------------------------------------------------------

-- Нельзя обновлять представление с GROUP BY
-- CREATE VIEW v_category_counts AS
-- SELECT category_id, COUNT(*) AS cnt FROM questions GROUP BY category_id;
-- UPDATE v_category_counts SET cnt = 100; -- ОШИБКА!

-- Можно обновлять простое представление
-- UPDATE v_top_players SET total_score = 999 WHERE id = 1; -- Работает

-- ----------------------------------------------------------------------------
-- 11. Управление представлениями
-- ----------------------------------------------------------------------------

-- Показать создания представления
SHOW CREATE VIEW v_player_stats;

-- Показать все представления
SHOW FULL TABLES WHERE TABLE_TYPE = 'VIEW';

-- Обновить представление
CREATE OR REPLACE VIEW v_player_stats AS
SELECT 
    p.id,
    p.username,
    p.email,
    p.total_score,
    p.games_played,
    p.is_active,
    ROUND(p.total_score / NULLIF(p.games_played, 0), 2) AS avg_score_per_game
FROM players p;

-- Удалить представление
-- DROP VIEW IF EXISTS v_temp_view;

-- ----------------------------------------------------------------------------
-- Очистка
-- ----------------------------------------------------------------------------
-- DROP DATABASE quiz_queries_db;
