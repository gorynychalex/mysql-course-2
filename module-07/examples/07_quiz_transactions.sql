-- ============================================================================
-- Module 7: Transactions and Storage Engines - Quiz Theme
-- ============================================================================

DROP DATABASE IF EXISTS quiz_transactions_db;
CREATE DATABASE quiz_transactions_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quiz_transactions_db;

-- ----------------------------------------------------------------------------
-- 1. Создание структуры (InnoDB)
-- ----------------------------------------------------------------------------

CREATE TABLE categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    total_questions INT UNSIGNED DEFAULT 0,
    total_games INT UNSIGNED DEFAULT 0,
    INDEX idx_name (name)
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
    FOREIGN KEY (category_id) REFERENCES categories(id),
    INDEX idx_category (category_id),
    INDEX idx_status (status)
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
    current_streak INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_score (total_score DESC)
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
    FOREIGN KEY (category_id) REFERENCES categories(id),
    INDEX idx_player_status (player_id, status)
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
    FOREIGN KEY (question_id) REFERENCES questions(id)
) ENGINE=InnoDB;

-- Таблица для логирования транзакций
CREATE TABLE transaction_log (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transaction_type VARCHAR(50),
    player_id INT,
    old_score INT,
    new_score INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Таблица для демонстрации блокировок
CREATE TABLE counters (
    id INT PRIMARY KEY,
    counter_value INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO counters VALUES (1, 0, NOW());

-- ----------------------------------------------------------------------------
-- 2. Тестовые данные
-- ----------------------------------------------------------------------------

INSERT INTO categories (name, total_questions, total_games) VALUES
('SQL Basics', 0, 0),
('Database Design', 0, 0),
('MySQL Admin', 0, 0);

INSERT INTO questions (category_id, question_text, difficulty, points, status) VALUES
(1, 'Что означает SQL?', 'easy', 1.00, 'published'),
(1, 'Какой оператор выбирает данные?', 'easy', 1.00, 'published'),
(2, 'Что такое нормализация?', 'medium', 2.00, 'published'),
(3, 'Порт MySQL по умолчанию?', 'easy', 1.00, 'published');

INSERT INTO answers (question_id, answer_text, is_correct) VALUES
(1, 'Structured Query Language', TRUE),
(1, 'Simple Question Language', FALSE),
(2, 'SELECT', TRUE),
(2, 'INSERT', FALSE);

INSERT INTO players (username, email, total_score, games_played) VALUES
('player1', 'p1@test.com', 100, 10),
('player2', 'p2@test.com', 250, 25);

-- ----------------------------------------------------------------------------
-- 3. Транзакции - базовые примеры
-- ----------------------------------------------------------------------------

-- Пример 1: Простая транзакция
START TRANSACTION;

UPDATE players SET total_score = total_score + 10 WHERE id = 1;
INSERT INTO transaction_log (transaction_type, player_id, old_score, new_score)
SELECT 'score_update', 1, 100, 110;

COMMIT;

-- Пример 2: Транзакция с откатом
START TRANSACTION;

UPDATE players SET total_score = total_score + 100 WHERE id = 1;

-- Проверка условия
IF (SELECT total_score FROM players WHERE id = 1) > 500 THEN
    COMMIT;
ELSE
    ROLLBACK;
END IF;

-- Пример 3: Транзакция с обработкой ошибок
START TRANSACTION;

-- Обработчик ошибок
-- В реальном коде используется DECLARE CONTINUE HANDLER

UPDATE players SET games_played = games_played + 1 WHERE id = 1;

-- Фиксация или откат в зависимости от результата
COMMIT;

-- ----------------------------------------------------------------------------
-- 4. Точки сохранения (SAVEPOINT)
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Первая операция
INSERT INTO players (username, email, total_score) 
VALUES ('temp_player', 'temp@test.com', 0);

SAVEPOINT after_player_insert;

-- Вторая операция
INSERT INTO game_sessions (player_id, score, status)
VALUES (LAST_INSERT_ID(), 0, 'active');

SAVEPOINT after_session_insert;

-- Третья операция (может вызвать ошибку)
-- INSERT INTO game_sessions (player_id, score) VALUES (99999, 0); -- Ошибка FK

-- Откат к точке сохранения
-- ROLLBACK TO SAVEPOINT after_session_insert;

-- Или откат к другой точке
-- ROLLBACK TO SAVEPOINT after_player_insert;

-- Или полная фиксация
COMMIT;

-- ----------------------------------------------------------------------------
-- 5. Блокировки таблиц
-- ----------------------------------------------------------------------------

-- Явная блокировка таблиц
LOCK TABLES 
    players WRITE,
    game_sessions WRITE,
    categories READ;

-- Критическая секция
UPDATE players SET total_score = total_score + 5 WHERE id = 1;

INSERT INTO game_sessions (player_id, score, status) VALUES (1, 5, 'completed');

UPDATE categories SET total_games = total_games + 1 WHERE id = 1;

UNLOCK TABLES;

-- ----------------------------------------------------------------------------
-- 6. Именованные блокировки (GET_LOCK)
-- ----------------------------------------------------------------------------

-- Получение блокировки
SELECT GET_LOCK('player_1_update', 10) AS lock_acquired;

-- Если блокировка получена (1)
-- Выполняем критическую операцию
UPDATE players SET total_score = total_score + 1 WHERE id = 1;

-- Освобождение блокировки
SELECT RELEASE_LOCK('player_1_update');

-- Проверка статуса блокировки
SELECT IS_USED_LOCK('player_1_update') AS lock_status;
SELECT IS_FREE_LOCK('player_1_update_2') AS is_free;

-- ----------------------------------------------------------------------------
-- 7. Демонстрация проблем параллелизма
-- ----------------------------------------------------------------------------

-- Проблема: Гонка данных (Race Condition)
-- Сессия 1:
START TRANSACTION;
SELECT counter_value FROM counters WHERE id = 1; -- Получает 0
-- Сессия 2 (параллельно):
-- START TRANSACTION;
-- SELECT counter_value FROM counters WHERE id = 1; -- Также получает 0
-- UPDATE counters SET counter_value = counter_value + 1 WHERE id = 1; -- Устанавливает 1
-- COMMIT;
-- Сессия 1 (продолжает):
-- UPDATE counters SET counter_value = counter_value + 1 WHERE id = 1; -- Устанавливает 1 (должно быть 2!)
-- COMMIT;

-- Решение: Блокировка SELECT ... FOR UPDATE
START TRANSACTION;
SELECT counter_value FROM counters WHERE id = 1 FOR UPDATE;
-- Теперь другая сессия не сможет прочитать эту строку до COMMIT
UPDATE counters SET counter_value = counter_value + 1 WHERE id = 1;
COMMIT;

-- ----------------------------------------------------------------------------
-- 8. Уровни изоляции
-- ----------------------------------------------------------------------------

-- Просмотр текущего уровня
SELECT @@transaction_isolation AS current_isolation;
SELECT @@tx_isolation AS current_isolation_old;

-- Установка уровня для сессии
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Установка уровня для следующей транзакции
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

START TRANSACTION;
-- ... операции ...
COMMIT;

-- Глобальная установка (требует SUPER привилегии)
-- SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- ----------------------------------------------------------------------------
-- 9. Сравнение движков
-- ----------------------------------------------------------------------------

-- Таблица с InnoDB (транзакционная)
CREATE TABLE innodb_demo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Таблица с MyISAM (без транзакций)
CREATE TABLE myisam_demo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=MyISAM;

-- Таблица с MEMORY (быстрая, временная)
CREATE TABLE memory_demo (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data VARCHAR(100)
) ENGINE=MEMORY;

-- Проверка движков таблиц
SELECT TABLE_NAME, ENGINE, TABLE_ROWS 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'quiz_transactions_db';

-- ----------------------------------------------------------------------------
-- 10. Транзакционная процедура
-- ----------------------------------------------------------------------------

DELIMITER //

CREATE PROCEDURE complete_game_session(
    IN p_session_id INT,
    IN p_player_id INT,
    IN p_score INT,
    IN p_category_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Блокировка строки игрока
    SELECT total_score FROM players WHERE id = p_player_id FOR UPDATE;
    
    -- Обновление сессии
    UPDATE game_sessions 
    SET status = 'completed', 
        ended_at = NOW(), 
        score = p_score
    WHERE id = p_session_id;
    
    -- Обновление статистики игрока
    UPDATE players 
    SET total_score = total_score + p_score,
        games_played = games_played + 1
    WHERE id = p_player_id;
    
    -- Обновление статистики категории
    UPDATE categories 
    SET total_games = total_games + 1
    WHERE id = p_category_id;
    
    -- Логирование
    INSERT INTO transaction_log (
        transaction_type, player_id, old_score, new_score
    )
    SELECT 
        'game_complete',
        p_player_id,
        total_score - p_score,
        total_score
    FROM players WHERE id = p_player_id;
    
    COMMIT;
END//

DELIMITER ;

-- Вызов процедуры
CALL complete_game_session(1, 1, 25, 1);

-- ----------------------------------------------------------------------------
-- 11. Оптимизация InnoDB
-- ----------------------------------------------------------------------------

-- Просмотр настроек InnoDB
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW VARIABLES LIKE 'innodb_log_file_size';
SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';
SHOW VARIABLES LIKE 'innodb_flush_method';

-- Рекомендации для production:
-- innodb_buffer_pool_size = 70-80% от доступной RAM
-- innodb_flush_log_at_trx_commit = 1 (максимальная безопасность)
-- innodb_flush_log_at_trx_commit = 2 (лучшая производительность)

-- ----------------------------------------------------------------------------
-- 12. Мониторинг транзакций
-- ----------------------------------------------------------------------------

-- Активные транзакции
SELECT * FROM INFORMATION_SCHEMA.INNODB_TRX;

-- Блокировки
SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCKS;
SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCK_WAITS;

-- Метрики InnoDB
SHOW STATUS LIKE 'Innodb_row_lock%';
SHOW STATUS LIKE 'Innodb_deadlocks';

-- ----------------------------------------------------------------------------
-- Очистка
-- ----------------------------------------------------------------------------
-- DROP DATABASE quiz_transactions_db;
