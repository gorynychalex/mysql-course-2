-- ============================================================================
-- Module 2: Database Design Examples - Quiz Theme
-- ============================================================================
-- Примеры проектирования базы данных для викторины с вопросами и ответами
-- Демонстрация типов данных, нормализации, ключей и связей
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Создание базы данных с правильной кодировкой
-- ----------------------------------------------------------------------------
DROP DATABASE IF EXISTS quiz_design_db;

CREATE DATABASE IF NOT EXISTS quiz_design_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE quiz_design_db;

-- ----------------------------------------------------------------------------
-- 2. Демонстрация типов данных
-- ----------------------------------------------------------------------------

-- Таблица категорий вопросов с разными типами данных
CREATE TABLE categories (
    -- Числовой тип: INT с автоинкрементом
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Строковый тип: VARCHAR для названия
    name VARCHAR(100) NOT NULL,
    
    -- Текстовый тип: TEXT для описания
    description TEXT,
    
    -- ENUM для уровня сложности категории
    default_difficulty ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner',
    
    -- Цвет для отображения в интерфейсе (CHAR фиксированной длины)
    color_code CHAR(7) DEFAULT '#3498db',
    
    -- DECIMAL для веса категории в подсчёте очков
    weight DECIMAL(3,2) DEFAULT 1.00,
    
    -- Логическое значение (TINYINT(1) или BOOLEAN)
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Дата и время
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Индексы
    INDEX idx_name (name),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица вопросов
CREATE TABLE questions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Ссылка на категорию
    category_id INT UNSIGNED NOT NULL,
    
    -- Текст вопроса
    question_text TEXT NOT NULL,
    
    -- Тип вопроса
    question_type ENUM('single_choice', 'multiple_choice', 'true_false', 'text_input') 
        DEFAULT 'single_choice',
    
    -- Сложность вопроса
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    
    -- Баллы за правильный ответ
    points DECIMAL(4,2) DEFAULT 1.00,
    
    -- Время на ответ в секундах (SMALLINT достаточно)
    time_limit_seconds SMALLINT UNSIGNED DEFAULT 30,
    
    -- Статус вопроса
    status ENUM('draft', 'review', 'published', 'archived') DEFAULT 'draft',
    
    -- Метаданные
    created_by INT UNSIGNED,
    reviewed_by INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Внешний ключ
    FOREIGN KEY (category_id) REFERENCES categories(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Индексы для ускорения поиска
    INDEX idx_category (category_id),
    INDEX idx_difficulty (difficulty),
    INDEX idx_status (status),
    FULLTEXT INDEX ft_question_text (question_text)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица вариантов ответов
CREATE TABLE answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Ссылка на вопрос
    question_id INT UNSIGNED NOT NULL,
    
    -- Текст ответа
    answer_text VARCHAR(500) NOT NULL,
    
    -- Порядок отображения
    display_order TINYINT UNSIGNED DEFAULT 0,
    
    -- Правильный ли ответ
    is_correct BOOLEAN DEFAULT FALSE,
    
    -- Объяснение ответа (для обучения)
    explanation TEXT,
    
    -- Внешний ключ с каскадным удалением
    FOREIGN KEY (question_id) REFERENCES questions(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    -- Уникальность порядка для каждого вопроса
    UNIQUE KEY unique_question_order (question_id, display_order),
    
    INDEX idx_correct (is_correct)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица пользователей (игроков)
CREATE TABLE players (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Уникальный логин
    username VARCHAR(50) NOT NULL UNIQUE,
    
    -- Email для восстановления
    email VARCHAR(100) NOT NULL UNIQUE,
    
    -- Хэш пароля (фиксированная длина для bcrypt)
    password_hash CHAR(60) NOT NULL,
    
    -- Дата рождения
    birth_date DATE,
    
    -- Страна
    country_code CHAR(2) DEFAULT 'RU',
    
    -- Общий рейтинг
    total_score INT UNSIGNED DEFAULT 0,
    
    -- Количество игр
    games_played MEDIUMINT UNSIGNED DEFAULT 0,
    
    -- Средняя точность (DECIMAL)
    accuracy DECIMAL(5,2) DEFAULT 0.00,
    
    -- Дата регистрации
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Последний вход
    last_login_at TIMESTAMP NULL,
    
    -- Статус аккаунта
    is_active BOOLEAN DEFAULT TRUE,
    is_banned BOOLEAN DEFAULT FALSE,
    
    -- Индексы
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_score (total_score DESC),
    INDEX idx_country (country_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица игровых сессий (связь M:N между игроками и вопросами)
CREATE TABLE game_sessions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Игрок
    player_id INT UNSIGNED NOT NULL,
    
    -- Название сессии/викторины
    session_name VARCHAR(100),
    
    -- Дата начала
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Дата окончания
    ended_at TIMESTAMP NULL,
    
    -- Итоговый счёт
    final_score INT UNSIGNED DEFAULT 0,
    
    -- Количество правильных ответов
    correct_answers_count SMALLINT UNSIGNED DEFAULT 0,
    
    -- Общее количество вопросов
    total_questions SMALLINT UNSIGNED DEFAULT 0,
    
    -- Статус сессии
    status ENUM('active', 'paused', 'completed', 'abandoned') DEFAULT 'active',
    
    -- Внешний ключ
    FOREIGN KEY (player_id) REFERENCES players(id)
        ON DELETE CASCADE,
    
    INDEX idx_player (player_id),
    INDEX idx_started (started_at),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица ответов игрока в сессии (junction table)
CREATE TABLE session_answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    -- Ссылка на сессию
    session_id INT UNSIGNED NOT NULL,
    
    -- Ссылка на вопрос
    question_id INT UNSIGNED NOT NULL,
    
    -- Выбранный ответ (может быть NULL для текстового ввода)
    selected_answer_id INT UNSIGNED,
    
    -- Текстовый ответ игрока (если вопрос с вводом текста)
    player_text_answer VARCHAR(500),
    
    -- Время ответа в секундах
    response_time_seconds SMALLINT UNSIGNED,
    
    -- Полученные очки
    earned_points DECIMAL(4,2) DEFAULT 0.00,
    
    -- Правильный ли ответ
    is_correct BOOLEAN DEFAULT FALSE,
    
    -- Время ответа
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Внешние ключи
    FOREIGN KEY (session_id) REFERENCES game_sessions(id)
        ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id)
        ON DELETE RESTRICT,
    FOREIGN KEY (selected_answer_id) REFERENCES answers(id)
        ON DELETE SET NULL,
    
    -- Уникальность: один ответ на вопрос в сессии
    UNIQUE KEY unique_session_question (session_id, question_id),
    
    INDEX idx_session (session_id),
    INDEX idx_question (question_id),
    INDEX idx_correct (is_correct)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 3. Заполнение тестовыми данными
-- ----------------------------------------------------------------------------

INSERT INTO categories (name, description, default_difficulty, color_code, weight) VALUES
('SQL Basics', 'Основные понятия SQL и базовые команды', 'beginner', '#3498db', 1.00),
('Database Design', 'Проектирование баз данных и нормализация', 'intermediate', '#e74c3c', 1.50),
('MySQL Server', 'Администрирование и настройка MySQL', 'advanced', '#2ecc71', 2.00),
('Data Types', 'Типы данных MySQL и их использование', 'beginner', '#f39c12', 1.00),
('Security', 'Безопасность и управление доступом', 'intermediate', '#9b59b6', 1.50);

INSERT INTO questions (category_id, question_text, question_type, difficulty, points, time_limit_seconds, status) VALUES
(1, 'Какой оператор используется для выбора данных из таблицы?', 'single_choice', 'easy', 1.00, 30, 'published'),
(1, 'Что означает аббревиатура SQL?', 'single_choice', 'easy', 1.00, 30, 'published'),
(2, 'Какая нормальная форма устраняет транзитивные зависимости?', 'single_choice', 'medium', 2.00, 45, 'published'),
(2, 'Что такое первичный ключ?', 'single_choice', 'easy', 1.00, 30, 'published'),
(3, 'Какой порт используется по умолчанию для MySQL?', 'single_choice', 'easy', 1.00, 30, 'published'),
(3, 'Какая команда используется для создания резервной копии?', 'single_choice', 'medium', 2.00, 45, 'published'),
(4, 'Какой тип данных подходит для хранения точных десятичных значений?', 'single_choice', 'medium', 2.00, 45, 'published'),
(4, 'Какой тип данных использовать для хранения даты и времени?', 'single_choice', 'easy', 1.00, 30, 'published'),
(5, 'Какая команда предоставляет права пользователю?', 'single_choice', 'medium', 2.00, 45, 'published'),
(5, 'Что такое SQL-инъекция?', 'text_input', 'hard', 3.00, 60, 'published');

INSERT INTO answers (question_id, answer_text, display_order, is_correct, explanation) VALUES
-- Вопрос 1
(1, 'SELECT', 1, TRUE, 'SELECT — оператор для выборки данных из таблицы'),
(1, 'INSERT', 2, FALSE, 'INSERT используется для вставки новых записей'),
(1, 'UPDATE', 3, FALSE, 'UPDATE обновляет существующие записи'),
(1, 'CREATE', 4, FALSE, 'CREATE создаёт новые объекты БД'),

-- Вопрос 2
(2, 'Structured Query Language', 1, TRUE, 'SQL расшифровывается как Structured Query Language'),
(2, 'Simple Question Language', 2, FALSE, 'Неверная расшифровка'),
(2, 'System Query Logic', 3, FALSE, 'Неверная расшифровка'),
(2, 'Standard Question List', 4, FALSE, 'Неверная расшифровка'),

-- Вопрос 3
(3, 'Третья нормальная форма (3NF)', 1, TRUE, '3NF устраняет транзитивные зависимости'),
(3, 'Вторая нормальная форма (2NF)', 2, FALSE, '2NF устраняет частичные зависимости'),
(3, 'Первая нормальная форма (1NF)', 3, FALSE, '1NF требует атомарности значений'),
(3, 'Четвёртая нормальная форма (4NF)', 4, FALSE, '4NF устраняет многозначные зависимости'),

-- Вопрос 4
(4, 'Уникальный идентификатор строки таблицы', 1, TRUE, 'Первичный ключ уникально идентифицирует каждую строку'),
(4, 'Ключ шифрования данных', 2, FALSE, 'Первичный ключ не используется для шифрования'),
(4, 'Пароль для доступа к таблице', 3, FALSE, 'Это не пароль'),
(4, 'Индекс для ускорения поиска', 4, FALSE, 'Хотя PK создаёт индекс, это не его основная функция'),

-- Вопрос 5
(5, '3306', 1, TRUE, 'Порт 3306 используется по умолчанию'),
(5, '3307', 2, FALSE, 'Это альтернативный порт'),
(5, '5432', 3, FALSE, 'Это порт PostgreSQL'),
(5, '1433', 4, FALSE, 'Это порт MS SQL Server'),

-- Вопрос 6
(6, 'mysqldump', 1, TRUE, 'mysqldump — утилита для создания дампа БД'),
(6, 'mysqlbackup', 2, FALSE, 'Такой утилиты нет в стандартной поставке'),
(6, 'mysqlcopy', 3, FALSE, 'Такой утилиты нет'),
(6, 'dbexport', 4, FALSE, 'Такой утилиты нет'),

-- Вопрос 7
(7, 'DECIMAL', 1, TRUE, 'DECIMAL хранит точные десятичные значения'),
(7, 'FLOAT', 2, FALSE, 'FLOAT — приближённое значение'),
(7, 'DOUBLE', 3, FALSE, 'DOUBLE — приближённое значение'),
(7, 'REAL', 4, FALSE, 'REAL — приближённое значение'),

-- Вопрос 8
(8, 'DATETIME или TIMESTAMP', 1, TRUE, 'Оба типа хранят дату и время'),
(8, 'DATE', 2, FALSE, 'DATE хранит только дату'),
(8, 'TIME', 3, FALSE, 'TIME хранит только время'),
(8, 'YEAR', 4, FALSE, 'YEAR хранит только год'),

-- Вопрос 9
(9, 'GRANT', 1, TRUE, 'GRANT предоставляет привилегии'),
(9, 'ALLOW', 2, FALSE, 'Такой команды нет'),
(9, 'PERMIT', 3, FALSE, 'Такой команды нет'),
(9, 'AUTHORIZE', 4, FALSE, 'Такой команды нет'),

-- Вопрос 10 (текстовый ответ, варианты не нужны)
(10, 'Уязвимость, позволяющая выполнить вредоносный SQL-код', 1, TRUE, 'SQL-инъекция — внедрение вредоносного кода');

-- ----------------------------------------------------------------------------
-- 4. Примеры запросов для демонстрации связей
-- ----------------------------------------------------------------------------

-- Запрос 1: Показать все вопросы с категориями
SELECT 
    q.id,
    q.question_text,
    c.name AS category_name,
    q.difficulty,
    q.points
FROM questions q
JOIN categories c ON q.category_id = c.id
ORDER BY c.name, q.difficulty;

-- Запрос 2: Показать вопросы со всеми вариантами ответов
SELECT 
    q.question_text,
    a.answer_text,
    a.is_correct,
    a.explanation
FROM questions q
JOIN answers a ON q.id = a.question_id
WHERE q.id = 1
ORDER BY a.display_order;

-- Запрос 3: Статистика по категориям
SELECT 
    c.name AS category,
    COUNT(q.id) AS question_count,
    AVG(q.points) AS avg_points,
    SUM(CASE WHEN q.status = 'published' THEN 1 ELSE 0 END) AS published_count
FROM categories c
LEFT JOIN questions q ON c.id = q.category_id
GROUP BY c.id, c.name
ORDER BY question_count DESC;

-- Запрос 4: Топ игроков
SELECT 
    p.username,
    p.total_score,
    p.games_played,
    p.accuracy,
    p.country_code
FROM players p
WHERE p.is_active = TRUE
ORDER BY p.total_score DESC
LIMIT 10;

-- Запрос 5: Детали игровой сессии
SELECT 
    gs.id AS session_id,
    p.username,
    gs.session_name,
    gs.final_score,
    gs.correct_answers_count,
    gs.total_questions,
    ROUND(gs.correct_answers_count * 100.0 / gs.total_questions, 2) AS accuracy_percent
FROM game_sessions gs
JOIN players p ON gs.player_id = p.id
WHERE gs.status = 'completed'
ORDER BY gs.started_at DESC;

-- Запрос 6: Анализ ответов в сессии
SELECT 
    sa.session_id,
    q.question_text,
    a.answer_text AS selected_answer,
    sa.is_correct,
    sa.earned_points,
    sa.response_time_seconds
FROM session_answers sa
JOIN questions q ON sa.question_id = q.id
LEFT JOIN answers a ON sa.selected_answer_id = a.id
WHERE sa.session_id = 1
ORDER BY sa.answered_at;

-- ----------------------------------------------------------------------------
-- 5. Демонстрация нормализации
-- ----------------------------------------------------------------------------

-- Пример денормализованной таблицы (как НЕ надо делать)
CREATE TABLE denormalized_quiz (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_text VARCHAR(500),
    category_name VARCHAR(100),  -- Избыточно: повторяется для каждого вопроса
    category_color CHAR(7),       -- Избыточно
    author_username VARCHAR(50),  -- Избыточно
    author_email VARCHAR(100),    -- Избыточно
    answer1_text VARCHAR(500),    -- Нарушение 1NF: не атомарно
    answer1_correct BOOLEAN,
    answer2_text VARCHAR(500),
    answer2_correct BOOLEAN,
    answer3_text VARCHAR(500),
    answer3_correct BOOLEAN,
    answer4_text VARCHAR(500),
    answer4_correct BOOLEAN
);

-- Проблема: при изменении категории нужно обновлять все вопросы
-- Проблема: нельзя добавить ответ без изменения структуры таблицы
-- Проблема: пустые поля для вопросов с разным количеством ответов

-- ----------------------------------------------------------------------------
-- 6. Представления (Views) для упрощения запросов
-- ----------------------------------------------------------------------------

-- Представление: Полная информация о вопросе
CREATE OR REPLACE VIEW v_question_full AS
SELECT 
    q.id,
    q.question_text,
    c.name AS category_name,
    c.color_code AS category_color,
    q.difficulty,
    q.points,
    q.time_limit_seconds,
    q.status,
    q.created_at
FROM questions q
JOIN categories c ON q.category_id = c.id;

-- Представление: Вопросы с ответами
CREATE OR REPLACE VIEW v_question_answers AS
SELECT 
    q.id AS question_id,
    q.question_text,
    q.difficulty,
    a.id AS answer_id,
    a.answer_text,
    a.is_correct,
    a.display_order
FROM questions q
JOIN answers a ON q.id = a.question_id
WHERE q.status = 'published'
ORDER BY q.id, a.display_order;

-- Использование представлений
SELECT * FROM v_question_full WHERE difficulty = 'easy';
SELECT * FROM v_question_answers WHERE question_id = 1;

-- ----------------------------------------------------------------------------
-- 7. Очистка (закомментировать для сохранения данных)
-- ----------------------------------------------------------------------------
-- DROP DATABASE quiz_design_db;
