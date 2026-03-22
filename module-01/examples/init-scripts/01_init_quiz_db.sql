-- ============================================================================
-- Init Script for Docker MySQL Container
-- ============================================================================
-- Этот скрипт выполняется автоматически при первом запуске контейнера
-- Файлы в /docker-entrypoint-initdb.d/ выполняются в алфавитном порядке
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Создание базы данных для викторины
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS quiz_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE quiz_db;

-- ----------------------------------------------------------------------------
-- 2. Создание таблиц
-- ----------------------------------------------------------------------------

-- Категории вопросов
CREATE TABLE IF NOT EXISTS categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id INT UNSIGNED NULL,
    sort_order TINYINT UNSIGNED DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_parent (parent_id),
    INDEX idx_sort (sort_order),
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Категории вопросов';

-- Вопросы
CREATE TABLE IF NOT EXISTS questions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    question_text TEXT NOT NULL,
    question_type ENUM('single', 'multiple', 'true_false', 'text') DEFAULT 'single',
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    points DECIMAL(5,2) DEFAULT 1.00,
    time_limit_seconds SMALLINT UNSIGNED DEFAULT 30,
    explanation TEXT,
    status ENUM('draft', 'review', 'published', 'archived') DEFAULT 'draft',
    view_count INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_category (category_id),
    INDEX idx_difficulty (difficulty),
    INDEX idx_status (status),
    FULLTEXT INDEX ft_question_text (question_text),
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Вопросы викторины';

-- Варианты ответов
CREATE TABLE IF NOT EXISTS answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    question_id INT UNSIGNED NOT NULL,
    answer_text VARCHAR(500) NOT NULL,
    display_order TINYINT UNSIGNED DEFAULT 0,
    is_correct BOOLEAN DEFAULT FALSE,
    explanation TEXT,
    
    INDEX idx_question (question_id),
    INDEX idx_correct (is_correct),
    UNIQUE KEY unique_question_order (question_id, display_order),
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Варианты ответов';

-- Игроки
CREATE TABLE IF NOT EXISTS players (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash CHAR(60) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    country_code CHAR(2) DEFAULT 'RU',
    total_score INT UNSIGNED DEFAULT 0,
    games_played MEDIUMINT UNSIGNED DEFAULT 0,
    best_score INT UNSIGNED DEFAULT 0,
    accuracy DECIMAL(5,2) DEFAULT 0.00,
    current_streak SMALLINT UNSIGNED DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP NULL,
    
    UNIQUE INDEX idx_username (username),
    UNIQUE INDEX idx_email (email),
    INDEX idx_score (total_score DESC),
    INDEX idx_country (country_code)
) ENGINE=InnoDB COMMENT='Игроки';

-- Игровые сессии
CREATE TABLE IF NOT EXISTS game_sessions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    player_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED,
    session_uuid CHAR(36) NOT NULL UNIQUE,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    final_score INT UNSIGNED DEFAULT 0,
    correct_answers SMALLINT UNSIGNED DEFAULT 0,
    total_questions SMALLINT UNSIGNED DEFAULT 0,
    status ENUM('active', 'paused', 'completed', 'abandoned') DEFAULT 'active',
    
    INDEX idx_player (player_id),
    INDEX idx_started (started_at),
    INDEX idx_status (status),
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Игровые сессии';

-- Ответы в сессии
CREATE TABLE IF NOT EXISTS session_answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id INT UNSIGNED NOT NULL,
    question_id INT UNSIGNED NOT NULL,
    selected_answer_id INT UNSIGNED,
    response_time_seconds SMALLINT UNSIGNED,
    earned_points DECIMAL(5,2) DEFAULT 0.00,
    is_correct BOOLEAN DEFAULT FALSE,
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_session (session_id),
    INDEX idx_question (question_id),
    UNIQUE KEY unique_session_question (session_id, question_id),
    FOREIGN KEY (session_id) REFERENCES game_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE RESTRICT,
    FOREIGN KEY (selected_answer_id) REFERENCES answers(id) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Ответы в сессиях';

-- ----------------------------------------------------------------------------
-- 3. Тестовые данные
-- ----------------------------------------------------------------------------

-- Категории
INSERT INTO categories (name, slug, description, sort_order) VALUES
('SQL Basics', 'sql-basics', 'Основные понятия и команды SQL', 1),
('Database Design', 'database-design', 'Проектирование баз данных и нормализация', 2),
('MySQL Administration', 'mysql-admin', 'Администрирование сервера MySQL', 3),
('Data Types', 'data-types', 'Типы данных в MySQL', 4),
('Security', 'security', 'Безопасность и управление доступом', 5);

-- Вопросы
INSERT INTO questions (category_id, question_text, question_type, difficulty, points, status) VALUES
(1, 'Какой оператор используется для выбора данных из таблицы?', 'single_choice', 'easy', 1.00, 'published'),
(1, 'Что означает аббревиатура SQL?', 'single_choice', 'easy', 1.00, 'published'),
(1, 'Какая команда используется для создания таблицы?', 'single_choice', 'easy', 1.00, 'published'),
(2, 'Что такое нормализация базы данных?', 'text_input', 'medium', 2.00, 'published'),
(2, 'Какая нормальная форма устраняет транзитивные зависимости?', 'single_choice', 'medium', 2.00, 'published'),
(3, 'Какой порт используется по умолчанию для MySQL?', 'single_choice', 'easy', 1.00, 'published'),
(3, 'Какая утилита используется для резервного копирования?', 'single_choice', 'medium', 2.00, 'published'),
(4, 'Какой тип данных подходит для хранения точных десятичных значений?', 'single_choice', 'medium', 2.00, 'published'),
(5, 'Какая команда предоставляет права пользователю?', 'single_choice', 'medium', 2.00, 'published'),
(5, 'Что такое SQL-инъекция?', 'text_input', 'hard', 3.00, 'published');

-- Ответы
INSERT INTO answers (question_id, answer_text, display_order, is_correct) VALUES
-- Вопрос 1
(1, 'SELECT', 1, TRUE),
(1, 'INSERT', 2, FALSE),
(1, 'UPDATE', 3, FALSE),
(1, 'CREATE', 4, FALSE),
-- Вопрос 2
(2, 'Structured Query Language', 1, TRUE),
(2, 'Simple Question Language', 2, FALSE),
(2, 'System Query Logic', 3, FALSE),
(2, 'Standard Question List', 4, FALSE),
-- Вопрос 3
(3, 'CREATE TABLE', 1, TRUE),
(3, 'NEW TABLE', 2, FALSE),
(3, 'ADD TABLE', 3, FALSE),
(3, 'MAKE TABLE', 4, FALSE),
-- Вопрос 4
(4, 'Процесс организации данных для уменьшения избыточности', 1, TRUE),
(4, 'Создание резервных копий', 2, FALSE),
(4, 'Шифрование данных', 3, FALSE),
(4, 'Оптимизация запросов', 4, FALSE),
-- Вопрос 5
(5, 'Третья нормальная форма (3NF)', 1, TRUE),
(5, 'Вторая нормальная форма (2NF)', 2, FALSE),
(5, 'Первая нормальная форма (1NF)', 3, FALSE),
(5, 'Четвёртая нормальная форма (4NF)', 4, FALSE),
-- Вопрос 6
(6, '3306', 1, TRUE),
(6, '3307', 2, FALSE),
(6, '5432', 3, FALSE),
(6, '1433', 4, FALSE),
-- Вопрос 7
(7, 'mysqldump', 1, TRUE),
(7, 'mysqlbackup', 2, FALSE),
(7, 'mysqlcopy', 3, FALSE),
(7, 'dbexport', 4, FALSE),
-- Вопрос 8
(8, 'DECIMAL', 1, TRUE),
(8, 'FLOAT', 2, FALSE),
(8, 'DOUBLE', 3, FALSE),
(8, 'REAL', 4, FALSE),
-- Вопрос 9
(9, 'GRANT', 1, TRUE),
(9, 'ALLOW', 2, FALSE),
(9, 'PERMIT', 3, FALSE),
(9, 'AUTHORIZE', 4, FALSE),
-- Вопрос 10 (текстовый, без вариантов)
(10, 'Уязвимость, позволяющая выполнить вредоносный SQL-код', 1, TRUE);

-- Игроки
INSERT INTO players (username, email, password_hash, first_name, last_name, country_code, total_score, games_played) VALUES
('alex_quiz', 'alex@example.com', '*HASH*', 'Alex', 'Johnson', 'US', 150, 10),
('maria_pro', 'maria@example.com', '*HASH*', 'Maria', 'Garcia', 'ES', 280, 25),
('ivan_mysql', 'ivan@example.com', '*HASH*', 'Ivan', 'Petrov', 'RU', 95, 8),
('olga_db', 'olga@example.com', '*HASH*', 'Olga', 'Smith', 'GB', 320, 30),
('dmitry_sql', 'dmitry@example.com', '*HASH*', 'Dmitry', 'Lee', 'KR', 45, 3);

-- Игровые сессии
INSERT INTO game_sessions (player_id, category_id, session_uuid, final_score, correct_answers, total_questions, status) VALUES
(1, 1, UUID(), 10, 5, 5, 'completed'),
(1, 2, UUID(), 15, 4, 5, 'completed'),
(2, 1, UUID(), 20, 5, 5, 'completed'),
(2, 3, UUID(), 25, 4, 5, 'completed'),
(3, 1, UUID(), 5, 2, 5, 'completed'),
(4, 1, UUID(), 30, 5, 5, 'completed'),
(4, 2, UUID(), 35, 5, 5, 'active'),
(5, 4, UUID(), 8, 3, 5, 'abandoned');

-- Ответы в сессиях
INSERT INTO session_answers (session_id, question_id, selected_answer_id, response_time_seconds, earned_points, is_correct)
SELECT 
    gs.id,
    q.id,
    a.id,
    FLOOR(10 + RAND() * 20),
    q.points,
    TRUE
FROM game_sessions gs
CROSS JOIN questions q
JOIN answers a ON q.id = a.question_id AND a.is_correct = TRUE
WHERE gs.status = 'completed'
  AND q.category_id = gs.category_id
LIMIT 20;

-- ----------------------------------------------------------------------------
-- 4. Создание представления для демонстрации
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_question_summary AS
SELECT 
    c.name AS category_name,
    q.difficulty,
    COUNT(q.id) AS question_count,
    AVG(q.points) AS avg_points,
    SUM(q.view_count) AS total_views
FROM questions q
JOIN categories c ON q.category_id = c.id
WHERE q.status = 'published'
GROUP BY c.id, c.name, q.difficulty;

-- ----------------------------------------------------------------------------
-- 5. Приветственное сообщение
-- ----------------------------------------------------------------------------

SELECT '========================================' AS '';
SELECT 'Database initialized successfully!' AS '';
SELECT '========================================' AS '';
SELECT '' AS '';
SELECT 'Tables created:' AS '';
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'quiz_db' 
ORDER BY TABLE_NAME;

SELECT '' AS '';
SELECT 'Sample data inserted:' AS '';
SELECT 'Categories: ' || COUNT(*) FROM categories;
SELECT 'Questions: ' || COUNT(*) FROM questions;
SELECT 'Answers: ' || COUNT(*) FROM answers;
SELECT 'Players: ' || COUNT(*) FROM players;

SELECT '' AS '';
SELECT 'Connect with:' AS '';
SELECT '  mysql -h localhost -P 3306 -u root -prootpassword quiz_db' AS '';
SELECT '  phpMyAdmin: http://localhost:8080' AS '';
SELECT '========================================' AS '';
