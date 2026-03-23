-- ============================================================================
-- Init Script for Docker MariaDB Container - Schema
-- ============================================================================
-- Этот скрипт выполняется автоматически при первом запуске контейнера
-- Файлы в /docker-entrypoint-initdb.d/ выполняются в алфавитном порядке
-- ============================================================================
-- Совместимость: MariaDB 10.11+, MySQL 8.0+
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

-- Категории вопросов (с иерархией)
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

-- Вопросы викторины
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

-- Игроки (участники викторины)
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

-- Ответы в сессии (журнал ответов игрока)
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
-- 3. Создание представлений (VIEW)
-- ----------------------------------------------------------------------------

-- Представление: Сводка по вопросам
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

-- Представление: Статистика игроков
CREATE OR REPLACE VIEW v_player_stats AS
SELECT 
    p.id,
    p.username,
    p.first_name,
    p.last_name,
    p.total_score,
    p.games_played,
    p.accuracy,
    p.country_code,
    COUNT(DISTINCT gs.id) AS sessions_count,
    MAX(gs.final_score) AS best_session_score
FROM players p
LEFT JOIN game_sessions gs ON p.id = gs.player_id
WHERE p.is_active = TRUE
GROUP BY p.id, p.username, p.first_name, p.last_name, 
         p.total_score, p.games_played, p.accuracy, p.country_code;

-- ----------------------------------------------------------------------------
-- 4. Информационное сообщение о создании схемы
-- ----------------------------------------------------------------------------

SELECT '========================================' AS '';
SELECT 'MariaDB Quiz Database - Schema Created' AS '';
SELECT '========================================' AS '';
SELECT '' AS '';
SELECT 'Tables created:' AS '';
SELECT TABLE_NAME AS table_name
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'quiz_db' 
ORDER BY TABLE_NAME;

SELECT '' AS '';
SELECT 'Views created:' AS '';
SELECT TABLE_NAME AS view_name
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'quiz_db' 
ORDER BY TABLE_NAME;

SELECT '' AS '';
SELECT 'Next step: Run 02_quiz_data.sql to insert sample data' AS '';
SELECT '========================================' AS '';

-- ============================================================================
-- Конец скрипта создания схемы
-- ============================================================================
