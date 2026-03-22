-- ============================================================================
-- Module 3: DDL Examples - Quiz Theme
-- ============================================================================
-- Примеры DDL-операторов на основе темы "Викторина"
-- CREATE, ALTER, DROP, индексы, полнотекстовый поиск
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Создание базы данных с различными опциями
-- ----------------------------------------------------------------------------
DROP DATABASE IF EXISTS quiz_ddl_db;

CREATE DATABASE IF NOT EXISTS quiz_ddl_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE quiz_ddl_db;

-- ----------------------------------------------------------------------------
-- 2. Создание таблиц с различными типами данных и ограничениями
-- ----------------------------------------------------------------------------

-- Таблица категорий вопросов
CREATE TABLE IF NOT EXISTS categories (
    id INT UNSIGNED AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id INT UNSIGNED NULL,
    sort_order TINYINT UNSIGNED DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    
    -- Самоссылающийся внешний ключ для иерархии категорий
    FOREIGN KEY (parent_id) REFERENCES categories(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    INDEX idx_parent (parent_id),
    INDEX idx_sort (sort_order),
    INDEX idx_active (is_active)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Категории вопросов викторины';

-- Таблица вопросов
CREATE TABLE IF NOT EXISTS questions (
    id INT UNSIGNED AUTO_INCREMENT,
    category_id INT UNSIGNED NOT NULL,
    question_text TEXT NOT NULL,
    question_type ENUM('single', 'multiple', 'true_false', 'text') DEFAULT 'single',
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    points DECIMAL(5,2) DEFAULT 1.00,
    time_limit_seconds SMALLINT UNSIGNED DEFAULT 30,
    explanation TEXT,
    status ENUM('draft', 'review', 'published', 'archived') DEFAULT 'draft',
    created_by INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    
    FOREIGN KEY (category_id) REFERENCES categories(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    INDEX idx_category (category_id),
    INDEX idx_difficulty (difficulty),
    INDEX idx_status (status),
    INDEX idx_type (question_type),
    FULLTEXT INDEX ft_question_text (question_text)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Вопросы викторины';

-- Таблица вариантов ответов
CREATE TABLE IF NOT EXISTS answers (
    id INT UNSIGNED AUTO_INCREMENT,
    question_id INT UNSIGNED NOT NULL,
    answer_text VARCHAR(500) NOT NULL,
    display_order TINYINT UNSIGNED DEFAULT 0,
    is_correct BOOLEAN DEFAULT FALSE,
    explanation TEXT,
    
    PRIMARY KEY (id),
    
    FOREIGN KEY (question_id) REFERENCES questions(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    UNIQUE KEY unique_question_order (question_id, display_order),
    INDEX idx_correct (is_correct)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Варианты ответов';

-- Таблица игроков
CREATE TABLE IF NOT EXISTS players (
    id INT UNSIGNED AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash CHAR(60) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    birth_date DATE,
    country_code CHAR(2) DEFAULT 'RU',
    city VARCHAR(100),
    avatar_url VARCHAR(255),
    total_score INT UNSIGNED DEFAULT 0,
    games_played MEDIUMINT UNSIGNED DEFAULT 0,
    best_score INT UNSIGNED DEFAULT 0,
    accuracy DECIMAL(5,2) DEFAULT 0.00,
    current_streak SMALLINT UNSIGNED DEFAULT 0,
    best_streak SMALLINT UNSIGNED DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_banned BOOLEAN DEFAULT FALSE,
    banned_until DATE,
    ban_reason VARCHAR(255),
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP NULL,
    last_game_at TIMESTAMP NULL,
    
    PRIMARY KEY (id),
    
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_score (total_score DESC),
    INDEX idx_country (country_code),
    INDEX idx_registered (registered_at),
    INDEX idx_active_status (is_active, is_banned),
    FULLTEXT INDEX ft_name (first_name, last_name)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Игроки викторины';

-- Таблица игровых сессий
CREATE TABLE IF NOT EXISTS game_sessions (
    id INT UNSIGNED AUTO_INCREMENT,
    player_id INT UNSIGNED NOT NULL,
    session_uuid CHAR(36) NOT NULL UNIQUE,
    session_name VARCHAR(100),
    category_id INT UNSIGNED,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    final_score INT UNSIGNED DEFAULT 0,
    correct_answers SMALLINT UNSIGNED DEFAULT 0,
    total_questions SMALLINT UNSIGNED DEFAULT 0,
    accuracy_percent DECIMAL(5,2) DEFAULT 0.00,
    best_streak SMALLINT UNSIGNED DEFAULT 0,
    status ENUM('active', 'paused', 'completed', 'abandoned', 'cheated') DEFAULT 'active',
    device_info VARCHAR(255),
    ip_address VARCHAR(45),
    
    PRIMARY KEY (id),
    
    FOREIGN KEY (player_id) REFERENCES players(id)
        ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id)
        ON DELETE SET NULL,
    
    INDEX idx_player (player_id),
    INDEX idx_started (started_at),
    INDEX idx_status (status),
    INDEX idx_category_session (category_id),
    INDEX idx_uuid (session_uuid)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Игровые сессии';

-- Таблица ответов в сессии (junction table)
CREATE TABLE IF NOT EXISTS session_answers (
    id INT UNSIGNED AUTO_INCREMENT,
    session_id INT UNSIGNED NOT NULL,
    question_id INT UNSIGNED NOT NULL,
    question_number SMALLINT UNSIGNED NOT NULL,
    selected_answer_ids VARCHAR(100),
    text_answer VARCHAR(500),
    response_time_ms INT UNSIGNED,
    earned_points DECIMAL(5,2) DEFAULT 0.00,
    is_correct BOOLEAN DEFAULT FALSE,
    is_skipped BOOLEAN DEFAULT FALSE,
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    
    FOREIGN KEY (session_id) REFERENCES game_sessions(id)
        ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id)
        ON DELETE RESTRICT,
    
    UNIQUE KEY unique_session_question (session_id, question_id),
    INDEX idx_session (session_id),
    INDEX idx_question (question_id),
    INDEX idx_correct (is_correct),
    INDEX idx_answered (answered_at)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Ответы игроков в сессиях';

-- ----------------------------------------------------------------------------
-- 3. Демонстрация ALTER TABLE
-- ----------------------------------------------------------------------------

-- Добавление новых столбцов
ALTER TABLE players 
    ADD COLUMN timezone VARCHAR(50) DEFAULT 'UTC' AFTER country_code,
    ADD COLUMN language_code CHAR(2) DEFAULT 'ru' AFTER timezone,
    ADD COLUMN notification_email BOOLEAN DEFAULT TRUE AFTER language_code,
    ADD COLUMN notification_push BOOLEAN DEFAULT TRUE AFTER notification_email;

-- Изменение типа данных
ALTER TABLE questions 
    MODIFY COLUMN points DECIMAL(6,2) DEFAULT 1.00;

-- Изменение значения по умолчанию
ALTER TABLE players 
    MODIFY COLUMN accuracy DECIMAL(6,2) DEFAULT 0.00;

-- Добавление CHECK ограничения (MySQL 8.0.16+)
ALTER TABLE game_sessions 
    ADD CONSTRAINT chk_accuracy CHECK (accuracy_percent >= 0 AND accuracy_percent <= 100);

ALTER TABLE questions
    ADD CONSTRAINT chk_points CHECK (points >= 0);

-- Добавление нового индекса
ALTER TABLE players 
    ADD INDEX idx_streak (current_streak DESC);

-- Составной индекс
ALTER TABLE session_answers 
    ADD INDEX idx_session_correct (session_id, is_correct);

-- Удаление столбца (если нужно)
-- ALTER TABLE players DROP COLUMN city;

-- Переименование столбца
-- ALTER TABLE game_sessions CHANGE COLUMN session_uuid uuid CHAR(36) NOT NULL UNIQUE;

-- Переименование таблицы
-- ALTER TABLE answers RENAME TO question_answers;

-- Изменение кодировки таблицы
-- ALTER TABLE questions CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 4. Создание временных таблиц
-- ----------------------------------------------------------------------------

-- Временная таблица для статистики сессии
CREATE TEMPORARY TABLE IF NOT EXISTS temp_session_stats (
    session_id INT UNSIGNED,
    player_username VARCHAR(50),
    category_name VARCHAR(100),
    total_questions INT,
    correct_answers INT,
    accuracy DECIMAL(5,2),
    total_points DECIMAL(8,2),
    avg_response_time DECIMAL(8,2),
    completed_at TIMESTAMP
);

-- Заполнение временной таблицы
INSERT INTO temp_session_stats
SELECT 
    gs.id,
    p.username,
    c.name,
    gs.total_questions,
    gs.correct_answers,
    gs.accuracy_percent,
    gs.final_score,
    AVG(sa.response_time_ms),
    gs.ended_at
FROM game_sessions gs
JOIN players p ON gs.player_id = p.id
LEFT JOIN categories c ON gs.category_id = c.id
LEFT JOIN session_answers sa ON gs.id = sa.session_id
WHERE gs.status = 'completed'
GROUP BY gs.id;

-- Использование временной таблицы
SELECT * FROM temp_session_stats WHERE accuracy > 80;

-- ----------------------------------------------------------------------------
-- 5. Полнотекстовый поиск
-- ----------------------------------------------------------------------------

-- Вставка тестовых данных для демонстрации полнотекстового поиска
INSERT INTO categories (name, slug, description) VALUES
('SQL Basics', 'sql-basics', 'Основные понятия и команды SQL'),
('Database Design', 'database-design', 'Проектирование баз данных и нормализация'),
('MySQL Administration', 'mysql-admin', 'Администрирование сервера MySQL'),
('Data Types', 'data-types', 'Типы данных в MySQL'),
('Security', 'security', 'Безопасность и управление доступом');

INSERT INTO questions (category_id, question_text, question_type, difficulty, points, explanation, status) VALUES
(1, 'Какой оператор используется для выбора данных из таблицы?', 'single', 'easy', 1.00, 'SELECT — оператор выборки данных', 'published'),
(1, 'Что означает аббревиатура SQL?', 'single', 'easy', 1.00, 'Structured Query Language', 'published'),
(1, 'Какая команда используется для создания таблицы?', 'single', 'easy', 1.00, 'CREATE TABLE', 'published'),
(2, 'Что такое нормализация базы данных?', 'text', 'medium', 2.00, 'Процесс организации данных для уменьшения избыточности', 'published'),
(2, 'Какая нормальная форма устраняет транзитивные зависимости?', 'single', 'medium', 2.00, 'Третья нормальная форма (3NF)', 'published'),
(3, 'Какой порт используется по умолчанию для MySQL?', 'single', 'easy', 1.00, 'Порт 3306', 'published'),
(3, 'Какая утилита используется для резервного копирования?', 'single', 'medium', 2.00, 'mysqldump', 'published'),
(4, 'Какой тип данных подходит для хранения точных десятичных значений?', 'single', 'medium', 2.00, 'DECIMAL', 'published'),
(5, 'Какая команда предоставляет права пользователю?', 'single', 'medium', 2.00, 'GRANT', 'published'),
(5, 'Что такое SQL-инъекция?', 'text', 'hard', 3.00, 'Уязвимость безопасности, позволяющая выполнить вредоносный SQL-код', 'published');

INSERT INTO answers (question_id, answer_text, display_order, is_correct) VALUES
(1, 'SELECT', 1, TRUE),
(1, 'INSERT', 2, FALSE),
(1, 'UPDATE', 3, FALSE),
(1, 'CREATE', 4, FALSE),
(2, 'Structured Query Language', 1, TRUE),
(2, 'Simple Question Language', 2, FALSE),
(2, 'System Query Logic', 3, FALSE),
(2, 'Standard Question List', 4, FALSE);

-- Примеры полнотекстового поиска

-- Поиск по вопросу (естественный язык)
SELECT 
    q.id,
    q.question_text,
    c.name AS category,
    MATCH(q.question_text) AGAINST('оператор выбора' IN NATURAL LANGUAGE MODE) AS relevance
FROM questions q
JOIN categories c ON q.category_id = c.id
WHERE MATCH(q.question_text) AGAINST('оператор выбора' IN NATURAL LANGUAGE MODE)
ORDER BY relevance DESC;

-- Поиск в режиме Boolean (с операторами)
SELECT 
    q.id,
    q.question_text,
    q.explanation
FROM questions q
WHERE MATCH(q.question_text, q.explanation) AGAINST('+данных +таблица' IN BOOLEAN MODE);

-- Поиск с исключением слов
SELECT 
    q.id,
    q.question_text
FROM questions q
WHERE MATCH(q.question_text) AGAINST('+MySQL -порт' IN BOOLEAN MODE);

-- Поиск с подстановочным знаком
SELECT 
    q.id,
    q.question_text
FROM questions q
WHERE MATCH(q.question_text) AGAINST('операт*' IN BOOLEAN MODE);

-- Поиск точной фразы
SELECT 
    q.id,
    q.question_text
FROM questions q
WHERE MATCH(q.question_text) AGAINST('"база данных"' IN BOOLEAN MODE);

-- ----------------------------------------------------------------------------
-- 6. Просмотр информации о структуре
-- ----------------------------------------------------------------------------

-- Показать все таблицы
SHOW TABLES;

-- Показать создание таблицы
SHOW CREATE TABLE questions;

-- Показать столбцы таблицы
DESCRIBE questions;
DESC questions;

-- Показать полную информацию о столбцах
SHOW FULL COLUMNS FROM questions;

-- Показать индексы
SHOW INDEX FROM questions;
SHOW INDEX FROM players;

-- Показать внешние ключи
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'quiz_ddl_db'
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- Показать все индексы в базе
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    NON_UNIQUE,
    INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'quiz_ddl_db'
ORDER BY TABLE_NAME, INDEX_NAME;

-- ----------------------------------------------------------------------------
-- 7. Демонстрация DROP и TRUNCATE
-- ----------------------------------------------------------------------------

-- Создание тестовой таблицы
CREATE TABLE test_table (
    id INT PRIMARY KEY,
    value VARCHAR(50)
);

INSERT INTO test_table VALUES (1, 'test1'), (2, 'test2'), (3, 'test3');

-- TRUNCATE - быстрая очистка с сбросом AUTO_INCREMENT
TRUNCATE TABLE test_table;

-- DROP - полное удаление таблицы
DROP TABLE IF EXISTS test_table;

-- ----------------------------------------------------------------------------
-- 8. Каскадное удаление (демонстрация)
-- ----------------------------------------------------------------------------

-- При удалении вопроса, все ответы удалятся автоматически (ON DELETE CASCADE)
-- DELETE FROM questions WHERE id = 1;
-- Ответы для вопроса 1 будут удалены автоматически

-- При попытке удаления категории с вопросами будет ошибка (ON DELETE RESTRICT)
-- DELETE FROM categories WHERE id = 1; -- Ошибка!

-- ----------------------------------------------------------------------------
-- Очистка (закомментировать для сохранения данных)
-- ----------------------------------------------------------------------------
-- DROP DATABASE quiz_ddl_db;
