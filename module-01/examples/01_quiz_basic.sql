-- ============================================================================
-- Module 1: Basic SQL Examples - Quiz Theme
-- ============================================================================
-- Примеры базовых SQL-команд на основе темы "Викторина: Вопрос - варианты ответов"
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Создание базы данных для викторины
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS quiz_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE quiz_db;

-- ----------------------------------------------------------------------------
-- 2. Создание таблицы вопросов
-- ----------------------------------------------------------------------------
CREATE TABLE questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_text TEXT NOT NULL,
    category VARCHAR(50),
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 3. Создание таблицы вариантов ответов
-- ----------------------------------------------------------------------------
CREATE TABLE answers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_id INT NOT NULL,
    answer_text VARCHAR(500) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- 4. Вставка данных - вопросы по MySQL
-- ----------------------------------------------------------------------------
INSERT INTO questions (question_text, category, difficulty) VALUES
('Какой оператор используется для выбора данных из базы данных?', 'SQL Basics', 'easy'),
('Что означает аббревиатура SQL?', 'SQL Basics', 'easy'),
('Какой тип хранилища MySQL поддерживает транзакции?', 'Storage Engines', 'medium'),
('Какой порт используется по умолчанию для MySQL?', 'Configuration', 'easy'),
('Какая команда используется для создания новой базы данных?', 'DDL', 'easy'),
('Что такое первичный ключ?', 'Database Design', 'medium'),
('Какой оператор используется для обновления данных?', 'DML', 'easy'),
('Что такое JOIN в SQL?', 'Queries', 'medium'),
('Какая утилита используется для резервного копирования MySQL?', 'Administration', 'medium'),
('Что такое индекс в базе данных?', 'Performance', 'hard');

-- ----------------------------------------------------------------------------
-- 5. Вставка вариантов ответов
-- ----------------------------------------------------------------------------
INSERT INTO answers (question_id, answer_text, is_correct) VALUES
-- Вопрос 1
(1, 'SELECT', TRUE),
(1, 'INSERT', FALSE),
(1, 'UPDATE', FALSE),
(1, 'CREATE', FALSE),

-- Вопрос 2
(2, 'Structured Query Language', TRUE),
(2, 'Simple Question Language', FALSE),
(2, 'System Query Logic', FALSE),
(2, 'Standard Question List', FALSE),

-- Вопрос 3
(3, 'InnoDB', TRUE),
(3, 'MyISAM', FALSE),
(3, 'MEMORY', FALSE),
(3, 'ARCHIVE', FALSE),

-- Вопрос 4
(4, '3306', TRUE),
(4, '3307', FALSE),
(4, '5432', FALSE),
(4, '1433', FALSE),

-- Вопрос 5
(5, 'CREATE DATABASE', TRUE),
(5, 'NEW DATABASE', FALSE),
(5, 'MAKE DATABASE', FALSE),
(5, 'ADD DATABASE', FALSE),

-- Вопрос 6
(6, 'Уникальный идентификатор записи', TRUE),
(6, 'Ключ для шифрования данных', FALSE),
(6, 'Пароль для доступа к таблице', FALSE),
(6, 'Индекс для ускорения поиска', FALSE),

-- Вопрос 7
(7, 'UPDATE', TRUE),
(7, 'CHANGE', FALSE),
(7, 'MODIFY', FALSE),
(7, 'ALTER', FALSE),

-- Вопрос 8
(8, 'Оператор для объединения таблиц', TRUE),
(8, 'Функция для сложения чисел', FALSE),
(8, 'Тип данных для строк', FALSE),
(8, 'Команда для соединения с сервером', FALSE),

-- Вопрос 9
(9, 'mysqldump', TRUE),
(9, 'mysqlbackup', FALSE),
(9, 'mysqlcopy', FALSE),
(9, 'dbexport', FALSE),

-- Вопрос 10
(10, 'Структура для ускорения поиска данных', TRUE),
(10, 'Список всех таблиц в базе', FALSE),
(10, 'Резервная копия данных', FALSE),
(10, 'Пользователь с правами доступа', FALSE);

-- ----------------------------------------------------------------------------
-- 6. Базовые запросы для демонстрации
-- ----------------------------------------------------------------------------

-- Показать все вопросы
SELECT * FROM questions;

-- Показать вопросы по категории
SELECT * FROM questions WHERE category = 'SQL Basics';

-- Показать вопросы по сложности
SELECT * FROM questions WHERE difficulty = 'easy';

-- Показать все варианты ответов для вопроса
SELECT q.question_text, a.answer_text, a.is_correct
FROM questions q
JOIN answers a ON q.id = a.question_id
WHERE q.id = 1;

-- Показать правильные ответы
SELECT q.question_text, a.answer_text
FROM questions q
JOIN answers a ON q.id = a.question_id
WHERE a.is_correct = TRUE;

-- Подсчитать количество вопросов по категориям
SELECT category, COUNT(*) as question_count
FROM questions
GROUP BY category;

-- Подсчитать количество вариантов ответов для каждого вопроса
SELECT q.question_text, COUNT(a.id) as answer_count
FROM questions q
LEFT JOIN answers a ON q.id = a.question_id
GROUP BY q.id;

-- ----------------------------------------------------------------------------
-- 7. Модификация структуры таблицы
-- ----------------------------------------------------------------------------

-- Добавить новый столбец
ALTER TABLE questions ADD COLUMN points INT DEFAULT 1;

-- Изменить тип данных
ALTER TABLE questions MODIFY COLUMN points DECIMAL(3,1) DEFAULT 1.0;

-- Добавить индекс
CREATE INDEX idx_category ON questions(category);
CREATE INDEX idx_difficulty ON questions(difficulty);

-- ----------------------------------------------------------------------------
-- 8. Обновление данных
-- ----------------------------------------------------------------------------

-- Обновить очки для сложных вопросов
UPDATE questions SET points = 3.0 WHERE difficulty = 'hard';
UPDATE questions SET points = 2.0 WHERE difficulty = 'medium';

-- ----------------------------------------------------------------------------
-- 9. Удаление данных
-- ----------------------------------------------------------------------------

-- Удалить неправильные варианты ответов (для примера)
-- DELETE FROM answers WHERE is_correct = FALSE;

-- ----------------------------------------------------------------------------
-- 10. Экспорт и импорт данных
-- ----------------------------------------------------------------------------

-- Команды для выполнения в терминале:

-- Экспорт базы данных:
-- mysqldump -u root -p quiz_db > quiz_backup.sql

-- Импорт базы данных:
-- mysql -u root -p quiz_db < quiz_backup.sql

-- Экспорт в CSV:
-- SELECT * FROM questions INTO OUTFILE '/tmp/questions.csv'
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

-- ----------------------------------------------------------------------------
-- 11. Просмотр информации о базе данных
-- ----------------------------------------------------------------------------

-- Показать все базы данных
SHOW DATABASES;

-- Показать таблицы текущей базы
SHOW TABLES;

-- Показать структуру таблицы
DESCRIBE questions;
DESCRIBE answers;

-- Показать созданные индексы
SHOW INDEX FROM questions;

-- Показать переменные сервера
SHOW VARIABLES LIKE 'port';
SHOW VARIABLES LIKE 'datadir';

-- Показать статус сервера
STATUS;

-- ----------------------------------------------------------------------------
-- 12. Очистка (для повторного использования)
-- ----------------------------------------------------------------------------

-- DROP DATABASE quiz_db;
