-- ============================================================================
-- Module 8: Optimization and Maintenance - Quiz Theme
-- ============================================================================

DROP DATABASE IF EXISTS quiz_optimize_db;
CREATE DATABASE quiz_optimize_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quiz_optimize_db;

-- ----------------------------------------------------------------------------
-- 1. Создание структуры для оптимизации
-- ----------------------------------------------------------------------------

CREATE TABLE categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

CREATE TABLE questions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    question_text TEXT NOT NULL,
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    points DECIMAL(5,2) DEFAULT 1.00,
    view_count INT UNSIGNED DEFAULT 0,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    INDEX idx_category (category_id),
    INDEX idx_difficulty (difficulty),
    INDEX idx_status (status),
    FULLTEXT INDEX ft_question (question_text)
) ENGINE=InnoDB;

CREATE TABLE answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    question_id INT UNSIGNED NOT NULL,
    answer_text VARCHAR(500) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    display_order TINYINT DEFAULT 1,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_question (question_id),
    INDEX idx_correct (is_correct)
) ENGINE=InnoDB;

CREATE TABLE players (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash CHAR(60) NOT NULL,
    total_score INT DEFAULT 0,
    games_played INT DEFAULT 0,
    best_score INT DEFAULT 0,
    accuracy DECIMAL(5,2) DEFAULT 0.00,
    country_code CHAR(2) DEFAULT 'RU',
    is_active BOOLEAN DEFAULT TRUE,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_score (total_score DESC),
    INDEX idx_country (country_code)
) ENGINE=InnoDB;

CREATE TABLE game_sessions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    player_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    score INT DEFAULT 0,
    status ENUM('active', 'completed', 'abandoned') DEFAULT 'active',
    device_info VARCHAR(255),
    ip_address VARCHAR(45),
    FOREIGN KEY (player_id) REFERENCES players(id),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    INDEX idx_player (player_id),
    INDEX idx_status (status),
    INDEX idx_started (started_at)
) ENGINE=InnoDB;

CREATE TABLE session_answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id INT UNSIGNED NOT NULL,
    question_id INT UNSIGNED NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    points_earned DECIMAL(5,2) DEFAULT 0,
    response_time_seconds INT,
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES game_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id),
    INDEX idx_session (session_id),
    INDEX idx_question (question_id)
) ENGINE=InnoDB;

-- Таблица для аудита
CREATE TABLE audit_log (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50),
    record_id INT,
    action ENUM('INSERT', 'UPDATE', 'DELETE'),
    old_values JSON,
    new_values JSON,
    user_name VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_table (table_name),
    INDEX idx_changed (changed_at)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. Генерация тестовых данных
-- ----------------------------------------------------------------------------

-- Категории
INSERT INTO categories (name, description, is_active) VALUES
('SQL Basics', 'Основы SQL', TRUE),
('Database Design', 'Проектирование БД', TRUE),
('MySQL Admin', 'Администрирование', TRUE),
('Security', 'Безопасность', TRUE),
('Performance', 'Производительность', TRUE),
('Inactive Category', 'Неактивная', FALSE);

-- Вопросы (генерируем много для тестов)
INSERT INTO questions (category_id, question_text, difficulty, points, status)
SELECT 
    FLOOR(1 + RAND() * 5) AS category_id,
    CONCAT('Вопрос номер ', seq, ': Что означает SQL?') AS question_text,
    ELT(FLOOR(1 + RAND() * 3), 'easy', 'medium', 'hard') AS difficulty,
    ROUND(RAND() * 3 + 1, 2) AS points,
    ELT(FLOOR(1 + RAND() * 3), 'draft', 'published', 'archived') AS status
FROM (
    SELECT @row := @row + 1 AS seq 
    FROM information_schema.COLUMNS c1, information_schema.COLUMNS c2, 
    (SELECT @row := 0) r
    LIMIT 1000
) AS numbers;

-- Ответы
INSERT INTO answers (question_id, answer_text, is_correct, display_order)
SELECT 
    q.id,
    CONCAT('Вариант ', seq, ' для вопроса ', q.id),
    seq = 1,
    seq
FROM questions q
CROSS JOIN (SELECT 1 AS seq UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) AS nums;

-- Игроки
INSERT INTO players (username, email, total_score, games_played, country_code)
SELECT 
    CONCAT('player', seq),
    CONCAT('player', seq, '@test.com'),
    FLOOR(RAND() * 1000),
    FLOOR(RAND() * 100),
    ELT(FLOOR(1 + RAND() * 5), 'RU', 'US', 'DE', 'FR', 'CN')
FROM (
    SELECT @row2 := @row2 + 1 AS seq 
    FROM information_schema.COLUMNS c1, information_schema.COLUMNS c2,
    (SELECT @row2 := 0) r
    LIMIT 500
) AS numbers;

-- Сессии
INSERT INTO game_sessions (player_id, category_id, score, status, started_at)
SELECT 
    FLOOR(1 + RAND() * 500),
    FLOOR(1 + RAND() * 5),
    FLOOR(RAND() * 100),
    ELT(FLOOR(1 + RAND() * 3), 'active', 'completed', 'abandoned'),
    DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY)
FROM (
    SELECT @row3 := @row3 + 1 AS seq 
    FROM information_schema.COLUMNS c1, information_schema.COLUMNS c2,
    (SELECT @row3 := 0) r
    LIMIT 2000
) AS numbers;

-- ----------------------------------------------------------------------------
-- 3. EXPLAIN - анализ запросов
-- ----------------------------------------------------------------------------

-- Базовый EXPLAIN
EXPLAIN SELECT * FROM questions WHERE category_id = 1;

-- EXPLAIN с JOIN
EXPLAIN SELECT 
    q.question_text,
    c.name AS category_name,
    COUNT(a.id) AS answer_count
FROM questions q
JOIN categories c ON q.category_id = c.id
LEFT JOIN answers a ON q.id = a.question_id
WHERE q.status = 'published'
GROUP BY q.id;

-- EXPLAIN FORMAT=JSON
EXPLAIN FORMAT=JSON 
SELECT * FROM players WHERE total_score > 500;

-- Проблема: полный scan без индекса
EXPLAIN SELECT * FROM game_sessions WHERE status = 'completed';

-- Решение: индекс уже создан, проверяем
EXPLAIN SELECT * FROM game_sessions WHERE status = 'completed';

-- Проблема: LIKE с wildcard в начале
EXPLAIN SELECT * FROM players WHERE email LIKE '%@gmail.com';

-- Решение: FULLTEXT индекс
-- ALTER TABLE players ADD FULLTEXT INDEX ft_email (email);

-- ----------------------------------------------------------------------------
-- 4. Оптимизация запросов
-- ----------------------------------------------------------------------------

-- Плохо: SELECT *
EXPLAIN SELECT * FROM questions WHERE category_id = 1;

-- Хорошо: конкретные столбцы
EXPLAIN SELECT id, question_text, difficulty FROM questions WHERE category_id = 1;

-- Плохо: функция в WHERE
EXPLAIN SELECT * FROM game_sessions WHERE YEAR(started_at) = 2024;

-- Хорошо: диапазон дат
EXPLAIN SELECT * FROM game_sessions 
WHERE started_at >= '2024-01-01' AND started_at < '2025-01-01';

-- Плохо: OR без индексов
EXPLAIN SELECT * FROM questions WHERE difficulty = 'easy' OR view_count > 100;

-- Хорошо: UNION
EXPLAIN SELECT * FROM questions WHERE difficulty = 'easy'
UNION
SELECT * FROM questions WHERE view_count > 100;

-- Использование covering index
EXPLAIN SELECT id, category_id, status FROM questions WHERE category_id = 1;

-- ----------------------------------------------------------------------------
-- 5. Профилирование
-- ----------------------------------------------------------------------------

-- Включение профилирования
SET profiling = 1;

-- Выполнение запросов
SELECT COUNT(*) FROM questions WHERE status = 'published';
SELECT COUNT(*) FROM questions WHERE difficulty = 'hard';
SELECT AVG(points) FROM questions WHERE category_id = 1;

-- Просмотр профиля
SHOW PROFILES;

-- Детальный профиль
SHOW PROFILE FOR QUERY 1;
SHOW PROFILE CPU, BLOCK IO FOR QUERY 1;
SHOW PROFILE MEMORY FOR QUERY 1;

-- Отключение профилирования
SET profiling = 0;

-- ----------------------------------------------------------------------------
-- 6. Статистика и мониторинг
-- ----------------------------------------------------------------------------

-- Размер таблиц
SELECT 
    TABLE_NAME,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS size_mb,
    TABLE_ROWS,
    AVG_ROW_LENGTH
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'quiz_optimize_db'
ORDER BY size_mb DESC;

-- Статистика индексов
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    SEQ_IN_INDEX,
    COLUMN_NAME,
    CARDINALITY,
    INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'quiz_optimize_db'
ORDER BY TABLE_NAME, INDEX_NAME;

-- Переменные сервера
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE 'query_cache_size';

-- Статус сервера
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Queries';
SHOW STATUS LIKE 'Slow_queries';

-- ----------------------------------------------------------------------------
-- 7. Резервное копирование (команды для bash)
-- ----------------------------------------------------------------------------

-- Команды для выполнения в терминале:

-- Резервная копия базы
-- mysqldump -u root -p quiz_optimize_db > backup.sql

-- Только структура
-- mysqldump -u root -p --no-data quiz_optimize_db > structure.sql

-- Только данные
-- mysqldump -u root -p --no-create-info quiz_optimize_db > data.sql

-- С сжатием
-- mysqldump -u root -p quiz_optimize_db | gzip > backup.sql.gz

-- Восстановление
-- mysql -u root -p quiz_optimize_db < backup.sql

-- ----------------------------------------------------------------------------
-- 8. Управление пользователями
-- ----------------------------------------------------------------------------

-- Создание пользователей
CREATE USER IF NOT EXISTS 'quiz_reader'@'localhost' IDENTIFIED BY 'read_password';
CREATE USER IF NOT EXISTS 'quiz_writer'@'localhost' IDENTIFIED BY 'write_password';
CREATE USER IF NOT EXISTS 'quiz_admin'@'localhost' IDENTIFIED BY 'admin_password';

-- Предоставление прав
GRANT SELECT ON quiz_optimize_db.* TO 'quiz_reader'@'localhost';
GRANT SELECT, INSERT, UPDATE ON quiz_optimize_db.* TO 'quiz_writer'@'localhost';
GRANT ALL PRIVILEGES ON quiz_optimize_db.* TO 'quiz_admin'@'localhost';

-- Применение изменений
FLUSH PRIVILEGES;

-- Просмотр прав
SHOW GRANTS FOR 'quiz_reader'@'localhost';
SHOW GRANTS FOR 'quiz_writer'@'localhost';
SHOW GRANTS FOR 'quiz_admin'@'localhost';

-- Отзыв прав
-- REVOKE UPDATE ON quiz_optimize_db.* FROM 'quiz_writer'@'localhost';

-- Удаление пользователя
-- DROP USER 'quiz_reader'@'localhost';

-- ----------------------------------------------------------------------------
-- 9. Экспорт данных
-- ----------------------------------------------------------------------------

-- Экспорт в CSV (требует FILE привилегию)
-- SELECT * FROM categories 
-- INTO OUTFILE '/tmp/categories.csv'
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n';

-- Экспорт в XML (через командную строку)
-- mysql -u root -p -X -e "SELECT * FROM categories" quiz_optimize_db > categories.xml

-- Экспорт в HTML (через командную строку)
-- mysql -u root -p -H -e "SELECT * FROM categories" quiz_optimize_db > categories.html

-- Генерация JSON (MySQL 5.7+)
SELECT JSON_OBJECT(
    'id', id,
    'name', name,
    'questions', (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT('id', q.id, 'text', q.question_text)
        )
        FROM questions q 
        WHERE q.category_id = c.id AND q.status = 'published'
    )
) AS category_json
FROM categories c
WHERE c.is_active = TRUE;

-- ----------------------------------------------------------------------------
-- 10. Оптимизация таблицы
-- ----------------------------------------------------------------------------

-- Анализ таблицы
ANALYZE TABLE questions;
ANALYZE TABLE players;

-- Проверка таблицы
CHECK TABLE questions;

-- Оптимизация таблицы
OPTIMIZE TABLE questions;
OPTIMIZE TABLE game_sessions;

-- Восстановление таблицы (если повреждена)
-- REPAIR TABLE table_name;

-- ----------------------------------------------------------------------------
-- 11. Создание представлений для оптимизации
-- ----------------------------------------------------------------------------

-- Представление для частого запроса
CREATE OR REPLACE VIEW v_published_questions AS
SELECT 
    q.id,
    q.question_text,
    q.difficulty,
    q.points,
    c.name AS category_name,
    COUNT(a.id) AS answer_count
FROM questions q
JOIN categories c ON q.category_id = c.id
LEFT JOIN answers a ON q.id = a.question_id
WHERE q.status = 'published'
GROUP BY q.id;

-- Использование представления
SELECT * FROM v_published_questions WHERE difficulty = 'easy';

-- ----------------------------------------------------------------------------
-- 12. Рекомендации по оптимизации
-- ----------------------------------------------------------------------------

-- 1. Используйте EXPLAIN для анализа запросов
-- 2. Создавайте индексы на полях WHERE, JOIN, ORDER BY
-- 3. Избегайте SELECT *
-- 4. Используйте LIMIT для больших результатов
-- 5. Кэшируйте результаты частых запросов
-- 6. Настройте innodb_buffer_pool_size (70-80% RAM)
-- 7. Включите slow_query_log
-- 8. Регулярно делайте OPTIMIZE TABLE
-- 9. Используйте соединения вместо подзапросов
-- 10. Нормализуйте данные, но не чрезмерно

-- ----------------------------------------------------------------------------
-- Очистка
-- ----------------------------------------------------------------------------
-- DROP DATABASE quiz_optimize_db;
