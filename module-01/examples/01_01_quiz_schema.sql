-- ============================================================================
-- Module 1: Quiz Database Schema and Data
-- ============================================================================
-- Создание схемы базы данных и наполнение тестовыми данными
-- Тема: "Викторина: Вопрос - варианты ответов"
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Создание базы данных
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS quiz_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE quiz_db;

-- ----------------------------------------------------------------------------
-- 2. Создание таблиц
-- ----------------------------------------------------------------------------

-- Таблица вопросов
CREATE TABLE questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_text TEXT NOT NULL,
    category VARCHAR(50),
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Вопросы викторины';

-- Таблица вариантов ответов
CREATE TABLE answers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_id INT NOT NULL,
    answer_text VARCHAR(500) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Варианты ответов';

-- ----------------------------------------------------------------------------
-- 3. Вставка данных - вопросы по MySQL
-- ----------------------------------------------------------------------------
INSERT INTO questions (question_text, category, difficulty) VALUES
-- Вопросы по SQL Basics
('Какой оператор используется для выбора данных из базы данных?', 'SQL Basics', 'easy'),
('Что означает аббревиатура SQL?', 'SQL Basics', 'easy'),
-- Вопросы по Storage Engines
('Какой тип хранилища MySQL поддерживает транзакции?', 'Storage Engines', 'medium'),
-- Вопросы по Configuration
('Какой порт используется по умолчанию для MySQL?', 'Configuration', 'easy'),
-- Вопросы по DDL
('Какая команда используется для создания новой базы данных?', 'DDL', 'easy'),
-- Вопросы по Database Design
('Что такое первичный ключ?', 'Database Design', 'medium'),
-- Вопросы по DML
('Какой оператор используется для обновления данных?', 'DML', 'easy'),
-- Вопросы по Queries
('Что такое JOIN в SQL?', 'Queries', 'medium'),
-- Вопросы по Administration
('Какая утилита используется для резервного копирования MySQL?', 'Administration', 'medium'),
-- Вопросы по Performance
('Что такое индекс в базе данных?', 'Performance', 'hard');

-- ----------------------------------------------------------------------------
-- 4. Вставка вариантов ответов
-- ----------------------------------------------------------------------------
INSERT INTO answers (question_id, answer_text, is_correct) VALUES
-- Вопрос 1: SELECT operator
(1, 'SELECT', TRUE),
(1, 'INSERT', FALSE),
(1, 'UPDATE', FALSE),
(1, 'CREATE', FALSE),

-- Вопрос 2: SQL abbreviation
(2, 'Structured Query Language', TRUE),
(2, 'Simple Question Language', FALSE),
(2, 'System Query Logic', FALSE),
(2, 'Standard Question List', FALSE),

-- Вопрос 3: Transaction storage engine
(3, 'InnoDB', TRUE),
(3, 'MyISAM', FALSE),
(3, 'MEMORY', FALSE),
(3, 'ARCHIVE', FALSE),

-- Вопрос 4: MySQL default port
(4, '3306', TRUE),
(4, '3307', FALSE),
(4, '5432', FALSE),
(4, '1433', FALSE),

-- Вопрос 5: CREATE DATABASE command
(5, 'CREATE DATABASE', TRUE),
(5, 'NEW DATABASE', FALSE),
(5, 'MAKE DATABASE', FALSE),
(5, 'ADD DATABASE', FALSE),

-- Вопрос 6: Primary key
(6, 'Уникальный идентификатор записи', TRUE),
(6, 'Ключ для шифрования данных', FALSE),
(6, 'Пароль для доступа к таблице', FALSE),
(6, 'Индекс для ускорения поиска', FALSE),

-- Вопрос 7: UPDATE operator
(7, 'UPDATE', TRUE),
(7, 'CHANGE', FALSE),
(7, 'MODIFY', FALSE),
(7, 'ALTER', FALSE),

-- Вопрос 8: JOIN
(8, 'Оператор для объединения таблиц', TRUE),
(8, 'Функция для сложения чисел', FALSE),
(8, 'Тип данных для строк', FALSE),
(8, 'Команда для соединения с сервером', FALSE),

-- Вопрос 9: Backup utility
(9, 'mysqldump', TRUE),
(9, 'mysqlbackup', FALSE),
(9, 'mysqlcopy', FALSE),
(9, 'dbexport', FALSE),

-- Вопрос 10: Index
(10, 'Структура для ускорения поиска данных', TRUE),
(10, 'Список всех таблиц в базе', FALSE),
(10, 'Резервная копия данных', FALSE),
(10, 'Пользователь с правами доступа', FALSE);

-- ----------------------------------------------------------------------------
-- 5. Проверка созданных данных
-- ----------------------------------------------------------------------------

-- Показать количество записей
SELECT 
    'questions' AS table_name, 
    COUNT(*) AS row_count 
FROM questions
UNION ALL
SELECT 
    'answers' AS table_name, 
    COUNT(*) AS row_count 
FROM answers;

-- Показать структуру таблиц
DESCRIBE questions;
DESCRIBE answers;

-- ============================================================================
-- Файл завершён. База данных создана и наполнена данными.
-- Для выполнения запросов используйте файл 01_02_quiz_queries.sql
-- ============================================================================
