-- ============================================================================
-- Init Script for Docker MariaDB Container - Data
-- ============================================================================
-- Этот скрипт выполняется автоматически при первом запуске контейнера
-- Файлы в /docker-entrypoint-initdb.d/ выполняются в алфавитном порядке
-- ============================================================================
-- Совместимость: MariaDB 10.11+, MySQL 8.0+
-- ============================================================================

USE quiz_db;

-- ----------------------------------------------------------------------------
-- 1. Вставка тестовых данных - Категории
-- ----------------------------------------------------------------------------
INSERT INTO categories (name, slug, description, sort_order) VALUES
('SQL Basics', 'sql-basics', 'Основные понятия и команды SQL', 1),
('Database Design', 'database-design', 'Проектирование баз данных и нормализация', 2),
('MariaDB Administration', 'mariadb-admin', 'Администрирование сервера MariaDB', 3),
('Data Types', 'data-types', 'Типы данных в MariaDB/MySQL', 4),
('Security', 'security', 'Безопасность и управление доступом', 5),
('Performance', 'performance', 'Оптимизация и производительность', 6);

-- ----------------------------------------------------------------------------
-- 2. Вставка тестовых данных - Вопросы
-- ----------------------------------------------------------------------------
INSERT INTO questions (category_id, question_text, question_type, difficulty, points, status) VALUES
-- SQL Basics
(1, 'Какой оператор используется для выбора данных из таблицы?', 'single', 'easy', 1.00, 'published'),
(1, 'Что означает аббревиатура SQL?', 'single', 'easy', 1.00, 'published'),
(1, 'Какая команда используется для создания таблицы?', 'single', 'easy', 1.00, 'published'),
-- Database Design
(2, 'Что такое нормализация базы данных?', 'text', 'medium', 2.00, 'published'),
(2, 'Какая нормальная форма устраняет транзитивные зависимости?', 'single', 'medium', 2.00, 'published'),
(2, 'Что такое первичный ключ?', 'single', 'easy', 1.00, 'published'),
-- MariaDB Administration
(3, 'Какой порт используется по умолчанию для MariaDB?', 'single', 'easy', 1.00, 'published'),
(3, 'Какая утилита используется для резервного копирования?', 'single', 'medium', 2.00, 'published'),
(3, 'Какой движок используется по умолчанию в MariaDB?', 'single', 'medium', 2.00, 'published'),
-- Data Types
(4, 'Какой тип данных подходит для хранения точных десятичных значений?', 'single', 'medium', 2.00, 'published'),
(4, 'Какой тип данных использовать для хранения даты и времени?', 'single', 'easy', 1.00, 'published'),
-- Security
(5, 'Какая команда предоставляет права пользователю?', 'single', 'medium', 2.00, 'published'),
(5, 'Что такое SQL-инъекция?', 'text', 'hard', 3.00, 'published'),
(5, 'Как создать пользователя в MariaDB?', 'single', 'medium', 2.00, 'published'),
-- Performance
(6, 'Что такое индекс в базе данных?', 'single', 'medium', 2.00, 'published'),
(6, 'Какая команда показывает план выполнения запроса?', 'single', 'easy', 1.00, 'published');

-- ----------------------------------------------------------------------------
-- 3. Вставка тестовых данных - Ответы
-- ----------------------------------------------------------------------------
INSERT INTO answers (question_id, answer_text, display_order, is_correct, explanation) VALUES
-- Вопрос 1: SELECT operator
(1, 'SELECT', 1, TRUE, 'SELECT — оператор для выборки данных'),
(1, 'INSERT', 2, FALSE, 'INSERT используется для вставки новых записей'),
(1, 'UPDATE', 3, FALSE, 'UPDATE обновляет существующие записи'),
(1, 'CREATE', 4, FALSE, 'CREATE создаёт новые объекты БД'),

-- Вопрос 2: SQL abbreviation
(2, 'Structured Query Language', 1, TRUE, 'SQL расшифровывается как Structured Query Language'),
(2, 'Simple Question Language', 2, FALSE, 'Неверная расшифровка'),
(2, 'System Query Logic', 3, FALSE, 'Неверная расшифровка'),
(2, 'Standard Question List', 4, FALSE, 'Неверная расшифровка'),

-- Вопрос 3: CREATE TABLE
(3, 'CREATE TABLE', 1, TRUE, 'CREATE TABLE создаёт новую таблицу'),
(3, 'NEW TABLE', 2, FALSE, 'Такой команды нет'),
(3, 'ADD TABLE', 3, FALSE, 'Такой команды нет'),
(3, 'MAKE TABLE', 4, FALSE, 'Такой команды нет'),

-- Вопрос 4: Normalization (text answer)
(4, 'Процесс организации данных для уменьшения избыточности', 1, TRUE, 'Нормализация устраняет избыточность и улучшает целостность'),

-- Вопрос 5: 3NF
(5, 'Третья нормальная форма (3NF)', 1, TRUE, '3NF устраняет транзитивные зависимости'),
(5, 'Вторая нормальная форма (2NF)', 2, FALSE, '2NF устраняет частичные зависимости'),
(5, 'Первая нормальная форма (1NF)', 3, FALSE, '1NF требует атомарности значений'),
(5, 'Четвёртая нормальная форма (4NF)', 4, FALSE, '4NF устраняет многозначные зависимости'),

-- Вопрос 6: Primary key
(6, 'Уникальный идентификатор строки таблицы', 1, TRUE, 'Первичный ключ уникально идентифицирует каждую строку'),
(6, 'Ключ шифрования данных', 2, FALSE, 'Первичный ключ не используется для шифрования'),
(6, 'Пароль для доступа к таблице', 3, FALSE, 'Это не пароль'),
(6, 'Индекс для ускорения поиска', 4, FALSE, 'Хотя PK создаёт индекс, это не его основная функция'),

-- Вопрос 7: MariaDB port
(7, '3306', 1, TRUE, 'Порт 3306 используется по умолчанию для MariaDB и MySQL'),
(7, '3307', 2, FALSE, 'Это альтернативный порт'),
(7, '5432', 3, FALSE, 'Это порт PostgreSQL'),
(7, '1433', 4, FALSE, 'Это порт MS SQL Server'),

-- Вопрос 8: Backup utility
(8, 'mysqldump', 1, TRUE, 'mysqldump — утилита для создания дампа БД'),
(8, 'mariadb-backup', 2, TRUE, 'mariadb-backup — утилита для бэкапа в MariaDB'),
(8, 'mysqlcopy', 3, FALSE, 'Такой утилиты нет'),
(8, 'dbexport', 4, FALSE, 'Такой утилиты нет'),

-- Вопрос 9: Default engine
(9, 'InnoDB', 1, TRUE, 'InnoDB — движок по умолчанию в MariaDB 10.11+'),
(9, 'Aria', 2, FALSE, 'Aria используется для временных таблиц'),
(9, 'MyISAM', 3, FALSE, 'MyISAM устарел'),
(9, 'ColumnStore', 4, FALSE, 'ColumnStore для аналитики'),

-- Вопрос 10: DECIMAL type
(10, 'DECIMAL', 1, TRUE, 'DECIMAL хранит точные десятичные значения'),
(10, 'FLOAT', 2, FALSE, 'FLOAT — приближённое значение'),
(10, 'DOUBLE', 3, FALSE, 'DOUBLE — приближённое значение'),
(10, 'REAL', 4, FALSE, 'REAL — приближённое значение'),

-- Вопрос 11: DATETIME
(11, 'DATETIME или TIMESTAMP', 1, TRUE, 'Оба типа хранят дату и время'),
(11, 'DATE', 2, FALSE, 'DATE хранит только дату'),
(11, 'TIME', 3, FALSE, 'TIME хранит только время'),
(11, 'YEAR', 4, FALSE, 'YEAR хранит только год'),

-- Вопрос 12: GRANT
(12, 'GRANT', 1, TRUE, 'GRANT предоставляет привилегии'),
(12, 'ALLOW', 2, FALSE, 'Такой команды нет'),
(12, 'PERMIT', 3, FALSE, 'Такой команды нет'),
(12, 'AUTHORIZE', 4, FALSE, 'Такой команды нет'),

-- Вопрос 13: SQL injection (text answer)
(13, 'Уязвимость для выполнения вредоносного SQL-кода', 1, TRUE, 'SQL-инъекция позволяет выполнить вредоносный код'),

-- Вопрос 14: CREATE USER
(14, 'CREATE USER', 1, TRUE, 'CREATE USER создаёт нового пользователя'),
(14, 'ADD USER', 2, FALSE, 'Такой команды нет'),
(14, 'NEW USER', 3, FALSE, 'Такой команды нет'),
(14, 'MAKE USER', 4, FALSE, 'Такой команды нет'),

-- Вопрос 15: Index
(15, 'Структура для ускорения поиска данных', 1, TRUE, 'Индекс ускоряет поиск по таблице'),
(15, 'Список всех таблиц в базе', 2, FALSE, 'Это не список таблиц'),
(15, 'Резервная копия данных', 3, FALSE, 'Это не резервная копия'),
(15, 'Пользователь с правами доступа', 4, FALSE, 'Это не пользователь'),

-- Вопрос 16: EXPLAIN
(16, 'EXPLAIN', 1, TRUE, 'EXPLAIN показывает план выполнения запроса'),
(16, 'DESCRIBE', 2, FALSE, 'DESCRIBE показывает структуру таблицы'),
(16, 'SHOW PLAN', 3, FALSE, 'Такой команды нет в MariaDB'),
(16, 'ANALYZE', 4, FALSE, 'ANALYZE обновляет статистику');

-- ----------------------------------------------------------------------------
-- 4. Вставка тестовых данных - Игроки
-- ----------------------------------------------------------------------------
INSERT INTO players (username, email, password_hash, first_name, last_name, country_code, total_score, games_played, best_score, accuracy) VALUES
('alex_quiz', 'alex@example.com', '*HASH_ALEX*', 'Alex', 'Johnson', 'US', 150, 10, 50, 75.00),
('maria_pro', 'maria@example.com', '*HASH_MARIA*', 'Maria', 'Garcia', 'ES', 280, 25, 80, 85.50),
('ivan_mysql', 'ivan@example.com', '*HASH_IVAN*', 'Ivan', 'Petrov', 'RU', 95, 8, 35, 65.00),
('olga_db', 'olga@example.com', '*HASH_OLGA*', 'Olga', 'Smith', 'GB', 320, 30, 90, 90.25),
('dmitry_sql', 'dmitry@example.com', '*HASH_DMITRY*', 'Dmitry', 'Lee', 'KR', 45, 3, 20, 55.00),
('anna_mariadb', 'anna@example.com', '*HASH_ANNA*', 'Anna', 'Mueller', 'DE', 200, 18, 65, 80.00);

-- ----------------------------------------------------------------------------
-- 5. Вставка тестовых данных - Игровые сессии
-- ----------------------------------------------------------------------------
INSERT INTO game_sessions (player_id, category_id, session_uuid, started_at, ended_at, final_score, correct_answers, total_questions, status) VALUES
(1, 1, UUID(), DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY), 10, 5, 5, 'completed'),
(1, 2, UUID(), DATE_SUB(NOW(), INTERVAL 9 DAY), DATE_SUB(NOW(), INTERVAL 9 DAY), 15, 4, 5, 'completed'),
(1, 1, UUID(), DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY), 12, 4, 5, 'completed'),
(2, 1, UUID(), DATE_SUB(NOW(), INTERVAL 8 DAY), DATE_SUB(NOW(), INTERVAL 8 DAY), 20, 5, 5, 'completed'),
(2, 3, UUID(), DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY), 25, 4, 5, 'completed'),
(2, 1, UUID(), DATE_SUB(NOW(), INTERVAL 2 DAY), NULL, 18, 4, 5, 'active'),
(3, 1, UUID(), DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY), 5, 2, 5, 'completed'),
(4, 1, UUID(), DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), 30, 5, 5, 'completed'),
(4, 2, UUID(), DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), 35, 5, 5, 'completed'),
(4, 1, UUID(), DATE_SUB(NOW(), INTERVAL 1 DAY), NULL, 28, 4, 5, 'active'),
(5, 4, UUID(), DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY), 8, 3, 5, 'completed'),
(5, 1, UUID(), DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), 6, 2, 5, 'abandoned'),
(6, 3, UUID(), DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), 22, 4, 5, 'completed'),
(6, 5, UUID(), DATE_SUB(NOW(), INTERVAL 2 DAY), NULL, 15, 3, 5, 'active');

-- ----------------------------------------------------------------------------
-- 6. Вставка тестовых данных - Ответы в сессиях
-- ----------------------------------------------------------------------------

-- Очищаем таблицу перед вставкой (на случай повторного запуска)
TRUNCATE TABLE session_answers;

-- Вставляем ответы в сессии - по одному ответу на вопрос в сессии
INSERT INTO session_answers (session_id, question_id, selected_answer_id, response_time_seconds, earned_points, is_correct)
SELECT
    gs.id AS session_id,
    q.id AS question_id,
    (SELECT a.id FROM answers a 
     WHERE a.question_id = q.id AND a.is_correct = TRUE 
     LIMIT 1) AS selected_answer_id,
    FLOOR(10 + RAND() * 20) AS response_time_seconds,
    q.points AS earned_points,
    TRUE AS is_correct
FROM game_sessions gs
JOIN questions q ON q.category_id = gs.category_id
WHERE gs.status = 'completed'
  AND q.id <= 16  -- Ограничиваем количество вопросов
ORDER BY gs.id, q.id
LIMIT 50;

-- ----------------------------------------------------------------------------
-- 7. Проверка вставленных данных
-- ----------------------------------------------------------------------------

SELECT '' AS '';
SELECT '========================================' AS '';
SELECT 'MariaDB Quiz Database - Data Loaded' AS '';
SELECT '========================================' AS '';
SELECT '' AS '';
SELECT 'Sample data inserted:' AS '';
SELECT 
    CONCAT('Categories: ', COUNT(*)) AS stats 
FROM categories
UNION ALL
SELECT CONCAT('Questions: ', COUNT(*)) FROM questions
UNION ALL
SELECT CONCAT('Answers: ', COUNT(*)) FROM answers
UNION ALL
SELECT CONCAT('Players: ', COUNT(*)) FROM players
UNION ALL
SELECT CONCAT('Game Sessions: ', COUNT(*)) FROM game_sessions
UNION ALL
SELECT CONCAT('Session Answers: ', COUNT(*)) FROM session_answers;

-- ----------------------------------------------------------------------------
-- 8. Информация для подключения
-- ----------------------------------------------------------------------------

SELECT '' AS '';
SELECT 'Connect to database:' AS '';
SELECT '  Host: localhost' AS '';
SELECT '  Port: 3306' AS '';
SELECT '  Database: quiz_db' AS '';
SELECT '  User: root (or your configured user)' AS '';
SELECT '' AS '';
SELECT 'Web Interface (Adminer):' AS '';
SELECT '  URL: http://localhost:8081' AS '';
SELECT '  Server: mariadb' AS '';
SELECT '  Username: root' AS '';
SELECT '  Password: rootpassword' AS '';
SELECT '  Database: quiz_db' AS '';
SELECT '' AS '';
SELECT '========================================' AS '';
SELECT 'Initialization complete!' AS '';
SELECT '========================================' AS '';

-- ============================================================================
-- Конец скрипта наполнения данными
-- ============================================================================
