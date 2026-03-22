-- ============================================================================
-- Module 6: Stored Procedures, Functions, Triggers - Quiz Theme
-- ============================================================================

DROP DATABASE IF EXISTS quiz_routines_db;
CREATE DATABASE quiz_routines_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quiz_routines_db;

-- ----------------------------------------------------------------------------
-- 1. Создание структуры
-- ----------------------------------------------------------------------------

CREATE TABLE categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE questions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    question_text TEXT NOT NULL,
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    points DECIMAL(5,2) DEFAULT 1.00,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    view_count INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
    best_score INT DEFAULT 0,
    current_streak INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_game_at TIMESTAMP NULL
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

CREATE TABLE audit_log (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50),
    record_id INT,
    action ENUM('INSERT', 'UPDATE', 'DELETE'),
    old_values TEXT,
    new_values TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(50)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. Тестовые данные
-- ----------------------------------------------------------------------------

INSERT INTO categories (name) VALUES 
('SQL Basics'), ('Database Design'), ('MySQL Admin'), ('Security');

INSERT INTO questions (category_id, question_text, difficulty, points, status) VALUES
(1, 'Что означает SQL?', 'easy', 1.00, 'published'),
(1, 'Какой оператор выбирает данные?', 'easy', 1.00, 'published'),
(2, 'Что такое нормализация?', 'medium', 2.00, 'published'),
(3, 'Порт MySQL по умолчанию?', 'easy', 1.00, 'published'),
(4, 'Что такое SQL-инъекция?', 'hard', 3.00, 'published');

INSERT INTO answers (question_id, answer_text, is_correct) VALUES
(1, 'Structured Query Language', TRUE),
(1, 'Simple Question Language', FALSE),
(2, 'SELECT', TRUE),
(2, 'INSERT', FALSE);

INSERT INTO players (username, email, total_score, games_played, best_score) VALUES
('player1', 'p1@test.com', 100, 10, 50),
('player2', 'p2@test.com', 250, 25, 80),
('player3', 'p3@test.com', 50, 5, 30);

INSERT INTO game_sessions (player_id, category_id, score, status) VALUES
(1, 1, 10, 'completed'),
(1, 1, 15, 'completed'),
(2, 1, 20, 'completed'),
(2, 2, 25, 'active');

-- ----------------------------------------------------------------------------
-- 3. Хранимые процедуры
-- ----------------------------------------------------------------------------

DELIMITER //

-- Процедура: Получить вопрос с ответами
CREATE PROCEDURE get_question_with_answers(IN q_id INT)
BEGIN
    SELECT q.*, c.name AS category_name 
    FROM questions q
    JOIN categories c ON q.category_id = c.id
    WHERE q.id = q_id;
    
    SELECT * FROM answers WHERE question_id = q_id ORDER BY id;
END//

-- Процедура: Статистика игрока
CREATE PROCEDURE get_player_stats(IN p_id INT)
BEGIN
    DECLARE total_sessions INT;
    DECLARE avg_score DECIMAL(10,2);
    
    SELECT COUNT(*) INTO total_sessions 
    FROM game_sessions WHERE player_id = p_id;
    
    SELECT AVG(score) INTO avg_score 
    FROM game_sessions WHERE player_id = p_id AND status = 'completed';
    
    SELECT 
        p.*,
        total_sessions AS total_sessions,
        IFNULL(avg_score, 0) AS avg_score;
    
    SELECT 
        c.name AS category,
        COUNT(gs.id) AS games_count,
        SUM(gs.score) AS total_score
    FROM game_sessions gs
    JOIN categories c ON gs.category_id = c.id
    WHERE gs.player_id = p_id
    GROUP BY c.id;
END//

-- Процедура: Регистрация ответа в сессии
CREATE PROCEDURE submit_answer(
    IN p_session_id INT,
    IN p_question_id INT,
    IN p_answer_id INT,
    IN p_response_time INT,
    OUT p_is_correct BOOLEAN,
    OUT p_points_earned DECIMAL(5,2)
)
BEGIN
    DECLARE v_correct_answer_id INT;
    DECLARE v_question_points DECIMAL(5,2);
    
    -- Получаем правильный ответ
    SELECT id INTO v_correct_answer_id 
    FROM answers 
    WHERE question_id = p_question_id AND is_correct = TRUE;
    
    -- Получаем очки за вопрос
    SELECT points INTO v_question_points 
    FROM questions WHERE id = p_question_id;
    
    -- Проверяем правильность
    IF p_answer_id = v_correct_answer_id THEN
        SET p_is_correct = TRUE;
        SET p_points_earned = v_question_points;
    ELSE
        SET p_is_correct = FALSE;
        SET p_points_earned = 0;
    END IF;
    
    -- Сохраняем ответ
    INSERT INTO session_answers (
        session_id, question_id, is_correct, points_earned, response_time_seconds
    ) VALUES (
        p_session_id, p_question_id, p_is_correct, p_points_earned, p_response_time
    );
    
    -- Обновляем счёт сессии
    UPDATE game_sessions 
    SET score = score + p_points_earned
    WHERE id = p_session_id;
    
    -- Увеличиваем счётчик просмотров
    UPDATE questions SET view_count = view_count + 1 WHERE id = p_question_id;
END//

-- Процедура: Завершение сессии
CREATE PROCEDURE finish_session(IN p_session_id INT)
BEGIN
    DECLARE v_player_id INT;
    DECLARE v_final_score INT;
    
    SELECT player_id, score INTO v_player_id, v_final_score
    FROM game_sessions WHERE id = p_session_id;
    
    UPDATE game_sessions 
    SET status = 'completed', ended_at = NOW()
    WHERE id = p_session_id;
    
    UPDATE players 
    SET 
        total_score = total_score + v_final_score,
        games_played = games_played + 1,
        best_score = GREATEST(best_score, v_final_score),
        last_game_at = NOW()
    WHERE id = v_player_id;
END//

-- Процедура с INOUT параметром
CREATE PROCEDURE increment_streak(INOUT p_streak INT)
BEGIN
    SET p_streak = p_streak + 1;
END//

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 4. Хранимые функции
-- ----------------------------------------------------------------------------

DELIMITER //

-- Функция: Расчёт возраста игрока
CREATE FUNCTION get_player_level(p_score INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE level VARCHAR(20);
    
    IF p_score >= 1000 THEN
        SET level = 'Master';
    ELSEIF p_score >= 500 THEN
        SET level = 'Expert';
    ELSEIF p_score >= 100 THEN
        SET level = 'Intermediate';
    ELSE
        SET level = 'Beginner';
    END IF;
    
    RETURN level;
END//

-- Функция: Форматирование времени ответа
CREATE FUNCTION format_response_time(p_seconds INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE result VARCHAR(20);
    
    IF p_seconds < 60 THEN
        SET result = CONCAT(p_seconds, ' сек');
    ELSEIF p_seconds < 3600 THEN
        SET result = CONCAT(FLOOR(p_seconds / 60), ' мин ', p_seconds % 60, ' сек');
    ELSE
        SET result = CONCAT(FLOOR(p_seconds / 3600), ' ч ', 
                           FLOOR((p_seconds % 3600) / 60), ' мин');
    END IF;
    
    RETURN result;
END//

-- Функция: Процент правильных ответов
CREATE FUNCTION calculate_accuracy(p_player_id INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_correct INT;
    DECLARE v_total INT;
    
    SELECT COUNT(*) INTO v_correct
    FROM session_answers sa
    JOIN game_sessions gs ON sa.session_id = gs.id
    WHERE gs.player_id = p_player_id AND sa.is_correct = TRUE;
    
    SELECT COUNT(*) INTO v_total
    FROM session_answers sa
    JOIN game_sessions gs ON sa.session_id = gs.id
    WHERE gs.player_id = p_player_id;
    
    IF v_total = 0 THEN
        RETURN 0.00;
    END IF;
    
    RETURN (v_correct * 100.0) / v_total;
END//

-- Функция: Дней с регистрации
CREATE FUNCTION days_since_registration(p_registered_at TIMESTAMP)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN DATEDIFF(NOW(), p_registered_at);
END//

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 5. Триггеры
-- ----------------------------------------------------------------------------

DELIMITER //

-- Триггер: Логирование изменений вопросов
CREATE TRIGGER questions_before_update
BEFORE UPDATE ON questions
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name, record_id, action, old_values, new_values, changed_by
    ) VALUES (
        'questions', OLD.id, 'UPDATE',
        CONCAT('question_text:', OLD.question_text, ',status:', OLD.status),
        CONCAT('question_text:', NEW.question_text, ',status:', NEW.status),
        'system'
    );
END//

-- Триггер: Автоматическая установка статуса при публикации
CREATE TRIGGER questions_before_insert
BEFORE INSERT ON questions
FOR EACH ROW
BEGIN
    -- Если вопрос лёгкий, автоматически публиковать
    IF NEW.difficulty = 'easy' AND NEW.status = 'draft' THEN
        SET NEW.status = 'published';
    END IF;
END//

-- Триггер: Обновление статистики после ответа
CREATE TRIGGER session_answers_after_insert
AFTER INSERT ON session_answers
FOR EACH ROW
BEGIN
    DECLARE v_session_id INT;
    DECLARE v_player_id INT;
    
    -- Обновляем серию правильных ответов
    IF NEW.is_correct = TRUE THEN
        UPDATE players p
        JOIN game_sessions gs ON p.id = gs.player_id
        SET p.current_streak = p.current_streak + 1
        WHERE gs.id = NEW.session_id;
    ELSE
        UPDATE players p
        JOIN game_sessions gs ON p.id = gs.player_id
        SET p.current_streak = 0
        WHERE gs.id = NEW.session_id;
    END IF;
END//

-- Триггер: Архивация удалённых игроков
CREATE TABLE players_archive (
    id INT UNSIGNED,
    username VARCHAR(50),
    email VARCHAR(100),
    total_score INT,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER players_after_delete
AFTER DELETE ON players
FOR EACH ROW
BEGIN
    INSERT INTO players_archive (id, username, email, total_score)
    VALUES (OLD.id, OLD.username, OLD.email, OLD.total_score);
END//

-- Триггер: Проверка целостности при завершении сессии
CREATE TRIGGER game_sessions_before_update
BEFORE UPDATE ON game_sessions
FOR EACH ROW
BEGIN
    -- Нельзя изменить счёт завершённой сессии
    IF OLD.status = 'completed' AND NEW.score != OLD.score THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify completed session score';
    END IF;
END//

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 6. Демонстрация использования
-- ----------------------------------------------------------------------------

-- Вызов процедуры
CALL get_question_with_answers(1);
CALL get_player_stats(1);

-- Вызов функции
SELECT 
    username,
    total_score,
    get_player_level(total_score) AS level,
    calculate_accuracy(id) AS accuracy,
    days_since_registration(registered_at) AS days_registered
FROM players;

-- Тест процедуры с OUT параметрами
CALL submit_answer(1, 1, 1, 15, @is_correct, @points);
SELECT @is_correct, @points;

-- Завершение сессии
CALL finish_session(1);

-- ----------------------------------------------------------------------------
-- 7. Просмотр ROUTINES
-- ----------------------------------------------------------------------------

-- Показать все процедуры
SHOW PROCEDURE STATUS WHERE Db = 'quiz_routines_db';

-- Показать все функции
SHOW FUNCTION STATUS WHERE Db = 'quiz_routines_db';

-- Показать создание процедуры
SHOW CREATE PROCEDURE get_player_stats;

-- Показать создание функции
SHOW CREATE FUNCTION get_player_level;

-- Показать триггеры
SHOW TRIGGERS;

-- ----------------------------------------------------------------------------
-- 8. Работа с датой и временем (примеры для библиотеки)
-- ----------------------------------------------------------------------------

-- Примеры функций даты
SELECT 
    NOW() AS current_datetime,
    CURDATE() AS current_date,
    DATE_ADD(NOW(), INTERVAL 7 DAY) AS due_date,
    DATEDIFF('2024-12-31', NOW()) AS days_left,
    DATE_FORMAT(NOW(), '%d.%m.%Y %H:%i') AS formatted;

-- Расчёт просрочки
SELECT 
    '2024-01-01' AS due_date,
    '2024-01-15' AS return_date,
    DATEDIFF('2024-01-15', '2024-01-01') AS days_overdue,
    GREATEST(0, DATEDIFF('2024-01-15', '2024-01-01')) * 10 AS fine_amount;

-- ----------------------------------------------------------------------------
-- Очистка
-- ----------------------------------------------------------------------------
-- DROP DATABASE quiz_routines_db;
