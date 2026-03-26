# Модуль 3. Синтаксис выражений SQL для определения структуры данных (DDL)

**Продолжительность:** 4 академических часа

## Содержание модуля

1. DDL-операторы
2. Операторы создания базы
3. Создание таблиц
4. Временные таблицы
5. Индексы
   - Типы индексов
   - Размер индексов (расчёт и проверка)
   - Оптимизация запросов с индексами (EXPLAIN)
6. Полнотекстовый индекс
7. Оператор модификации ALTER

---

## 1. DDL-операторы

### Что такое DDL?

**DDL (Data Definition Language)** — язык определения данных, подмножество SQL для создания и модификации структуры базы данных.

### Основные DDL-операторы

| Оператор | Описание | Пример |
|----------|----------|--------|
| **CREATE** | Создание объекта | CREATE TABLE |
| **ALTER** | Изменение объекта | ALTER TABLE |
| **DROP** | Удаление объекта | DROP TABLE |
| **TRUNCATE** | Очистка таблицы | TRUNCATE TABLE |
| **RENAME** | Переименование | RENAME TABLE |
| **CREATE OR REPLACE** | Создание или замена | CREATE OR REPLACE VIEW |

### Особенности DDL

```sql
-- DDL-операторы автоматически фиксируют транзакции
-- Нельзя откатить изменения без резервной копии

BEGIN;
CREATE TABLE test (id INT);
-- После выполнения CREATE транзакция автоматически зафиксирована
ROLLBACK; -- Не отменит CREATE TABLE
```

---

## 2. Операторы создания базы данных

### CREATE DATABASE

```sql
-- Базовый синтаксис
CREATE DATABASE database_name;

-- С указанием кодировки
CREATE DATABASE quiz_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Если база не существует
CREATE DATABASE IF NOT EXISTS quiz_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
```

### Параметры кодировки

| Параметр | Описание | Рекомендация |
|----------|----------|--------------|
| **CHARACTER SET** | Набор символов | utf8mb4 |
| **COLLATE** | Правила сравнения | utf8mb4_unicode_ci |

### Популярные кодировки

```sql
--_utf8mb4_ (рекомендуется)
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci    -- Универсальная
COLLATE utf8mb4_general_ci    -- Быстрее, менее точная
COLLATE utf8mb4_bin           -- Двоичное сравнение

-- Для конкретных языков
COLLATE utf8mb4_ru_0900_ai_ci -- Русский (MySQL 8.0+)
COLLATE utf8mb4_en_0900_ai_ci -- Английский
```

### Просмотр информации о базах данных

```sql
-- Показать все базы
SHOW DATABASES;

-- Показать создание базы
SHOW CREATE DATABASE quiz_db;

-- Использовать базу
USE quiz_db;

-- Текущая база
SELECT DATABASE();
```

### Удаление базы данных

```sql
-- Удаление базы
DROP DATABASE database_name;

-- Удаление с проверкой существования
DROP DATABASE IF EXISTS database_name;
```

---

## 3. Создание таблиц

### Базовый синтаксис CREATE TABLE

```sql
CREATE TABLE [IF NOT EXISTS] table_name (
    column1_name datatype [UNSIGNED] [DEFAULT value] [NOT NULL] [UNIQUE] [COMMENT 'text'],
    column2_name datatype [constraints],
    ...
    [PRIMARY KEY (column)],
    [INDEX index_name (column)],
    [FOREIGN KEY (column) REFERENCES other_table(column)],
    [UNIQUE KEY (column)]
) [ENGINE=storage_engine] [DEFAULT CHARSET=charset] [COLLATE=collation] [COMMENT='table comment'];
```

**Параметры:**
- `IF NOT EXISTS` — создать только если таблица не существует
- `ENGINE` — движок таблицы (InnoDB, MyISAM, MEMORY, ARCHIVE)
- `DEFAULT CHARSET` — кодировка по умолчанию (utf8mb4)
- `COLLATE` — правила сравнения (utf8mb4_unicode_ci)
- `COMMENT` — описание таблицы
- `PRIMARY KEY` — первичный ключ
- `INDEX` — индекс для ускорения поиска
- `FOREIGN KEY` — внешний ключ для связей
- `UNIQUE KEY` — уникальное ограничение

### Пример создания таблицы

```sql
CREATE TABLE questions (
    -- Первичный ключ
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    -- Обязательные поля
    question_text VARCHAR(500) NOT NULL,
    category_id INT UNSIGNED NOT NULL,

    -- Необязательные поля
    question_type VARCHAR(50),
    explanation TEXT,

    -- Числовые поля
    points INT UNSIGNED DEFAULT 1,
    difficulty DECIMAL(3,1) DEFAULT 1.0,

    -- Дата и время
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Статусы
    status ENUM('active', 'inactive', 'draft', 'archived') DEFAULT 'active',
    is_published BOOLEAN DEFAULT FALSE,

    -- Индексы
    INDEX idx_question_text (question_text),
    INDEX idx_category (category_id),
    INDEX idx_status (status),
    INDEX idx_difficulty (difficulty),
    FULLTEXT INDEX ft_question_text (question_text)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Таблица вопросов викторины';
```

### Ограничения столбцов (Constraints)

| Ограничение | Описание | Пример |
|-------------|----------|--------|
| **NOT NULL** | Не может быть NULL | column VARCHAR(50) NOT NULL |
| **NULL** | Может быть NULL | column VARCHAR(50) NULL |
| **DEFAULT** | Значение по умолчанию | column INT DEFAULT 0 |
| **UNIQUE** | Уникальное значение | column VARCHAR(50) UNIQUE |
| **PRIMARY KEY** | Первичный ключ | column INT PRIMARY KEY |
| **AUTO_INCREMENT** | Автоинкремент | column INT AUTO_INCREMENT |
| **REFERENCES** | Внешний ключ | column INT REFERENCES other(id) |
| **CHECK** | Проверка условия | column INT CHECK (column > 0) |

### Типы таблиц (Storage Engines)

| Движок | Описание | Применение |
|--------|----------|------------|
| **InnoDB** | Транзакционный, FK | По умолчанию, OLTP |
| **MyISAM** | Быстрый, нет транзакций | Чтение, устарел |
| **MEMORY** | В памяти, быстро | Временные данные |
| **ARCHIVE** | Архивирование | Логи, история |
| **CSV** | CSV файлы | Импорт/экспорт |

---

## 4. Временные таблицы

### Что такое временные таблицы?

**Временные таблицы** существуют только в течение сессии подключения и автоматически удаляются при закрытии соединения.

### Создание временной таблицы

**Синтаксис CREATE TEMPORARY TABLE:**
```sql
CREATE [TEMPORARY] TABLE [IF NOT EXISTS] table_name (
    column_definitions
) [ENGINE=storage_engine];

CREATE TEMPORARY TABLE [IF NOT EXISTS] table_name AS SELECT ...;
```

**Параметры:**
- `TEMPORARY` — создать временную таблицу (удаляется после завершения сессии)
- `IF NOT EXISTS` — создать только если таблица не существует
- `AS SELECT` — создать таблицу на основе результата запроса

**Особенности временных таблиц:**
- Видны только в текущей сессии (подключении)
- Автоматически удаляются при закрытии соединения
- Можно создать таблицу с тем же именем в разных сессиях
- Полезны для промежуточных вычислений

```sql
-- Создание временной таблицы
CREATE TEMPORARY TABLE temp_results (
    id INT,
    value DECIMAL(10,2),
    calculated_at TIMESTAMP
);

-- Использование
INSERT INTO temp_results VALUES (1, 100.50, NOW());
SELECT * FROM temp_results;

-- Временная таблица удалится автоматически при закрытии соединения
```

### Явное удаление временной таблицы

```sql
DROP TEMPORARY TABLE IF EXISTS temp_results;
```

### Пример использования

```sql
-- Создание временной таблицы с результатами
CREATE TEMPORARY TABLE player_stats AS
SELECT
    p.id,
    p.username,
    p.email,
    COUNT(gs.id) AS games_count,
    SUM(gs.score) AS total_score
FROM players p
LEFT JOIN game_sessions gs ON p.id = gs.player_id
GROUP BY p.id;

-- Использование
SELECT * FROM player_stats WHERE games_count > 5;

-- Таблица удалится автоматически
```

### Преимущества временных таблиц

- Автоматическая очистка
- Не занимают место после сессии
- Можно создавать с тем же именем в разных сессиях
- Ускоряют сложные запросы

---

## 5. Индексы

### Что такое индекс?

**Индекс** — структура данных для ускорения поиска строк в таблице.

### Типы индексов

| Тип | Описание | Синтаксис |
|-----|----------|-----------|
| **PRIMARY KEY** | Первичный ключ | PRIMARY KEY (col) |
| **UNIQUE** | Уникальный индекс | UNIQUE KEY (col) |
| **INDEX** | Обычный индекс | INDEX (col) |
| **FULLTEXT** | Полнотекстовый | FULLTEXT (col) |
| **SPATIAL** | Пространственный | SPATIAL (col) |
| **COMPOSITE** | Составной индекс | INDEX (col1, col2) |

### Создание индексов

**Синтаксис CREATE INDEX:**
```sql
-- Создание индекса в существующей таблице
CREATE [UNIQUE|FULLTEXT|SPATIAL] INDEX index_name
ON table_name (column1 [ASC|DESC], column2 [ASC|DESC], ...)
[USING BTREE|HASH]
[ALGORITHM=DEFAULT|INPLACE|COPY];

-- Создание индекса при создании таблицы
CREATE TABLE table_name (
    ...
    INDEX index_name (column),
    UNIQUE KEY unique_name (column),
    FULLTEXT INDEX ft_name (column)
);

-- Удаление индекса
DROP INDEX index_name ON table_name;
```

**Параметры:**
- `UNIQUE` — уникальное значение (запрет дубликатов)
- `FULLTEXT` — полнотекстовый индекс для поиска по тексту
- `SPATIAL` — пространственный индекс для GIS данных
- `USING BTREE` — B-дерево (по умолчанию, для диапазонных запросов)
- `USING HASH` — хэш-индекс (для точных совпадений)
- `ALGORITHM` — алгоритм создания (INPLACE — без блокировки, COPY — с копированием)
- `ASC/DESC` — порядок сортировки (по возрастанию/убыванию)

**Когда создавать индексы:**
- ✅ Столбцы в WHERE
- ✅ Столбцы в JOIN
- ✅ Столбцы в ORDER BY
- ✅ Столбцы в GROUP BY
- ✅ Внешние ключи

**Когда НЕ создавать:**
- ❌ Таблицы с частыми INSERT/UPDATE/DELETE
- ❌ Столбцы с низкой селективностью (пол, статус)
- ❌ Маленькие таблицы

```sql
-- При создании таблицы
CREATE TABLE players (
    id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    username VARCHAR(50),
    total_score INT,
    games_played INT,

    INDEX idx_username (username),
    INDEX idx_score (total_score)
);

-- Добавление индекса после создания
CREATE INDEX idx_email ON players(email);

-- Уникальный индекс
CREATE UNIQUE INDEX idx_unique_email ON players(email);

-- Составной индекс (для запросов с несколькими условиями)
CREATE INDEX idx_player_stats ON players(username, total_score);

-- Полнотекстовый индекс для поиска по вопросам
CREATE FULLTEXT INDEX ft_question ON questions(question_text);
```

### Просмотр индексов

```sql
-- Показать индексы таблицы
SHOW INDEX FROM players;

-- Альтернатива
SHOW INDEXES FROM players;
SHOW KEYS FROM players;

-- Подробная информация из INFORMATION_SCHEMA
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    CARDINALITY,
    INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'quiz_db'
ORDER BY TABLE_NAME, INDEX_NAME;
```

### Удаление индексов

```sql
-- Удаление по имени
DROP INDEX idx_email ON players;

-- Через ALTER TABLE
ALTER TABLE players DROP INDEX idx_email;

-- Удаление PRIMARY KEY
ALTER TABLE players DROP PRIMARY KEY;
```

---

## 5.1. Размер индексов

### Формула расчёта

```
Размер индекса = Размер_ключа × Количество_строк × Коэффициент_дерева

Для B-дерева коэффициент = 1.2 - 1.5 (накладные расходы)
```

### Пример расчёта для таблицы викторины

```sql
-- Таблица questions
-- question_text VARCHAR(500) — средний размер 100 символов = 100 байт
-- Количество вопросов: 100,000

-- Индекс по question_text:
-- 100 байт × 100,000 × 1.2 = 12 MB

-- Таблица players
-- username VARCHAR(50) — средний размер 20 символов = 20 байт
-- email VARCHAR(100) — средний размер 30 символов = 30 байт
-- Количество игроков: 1,000,000

-- Индекс по username:
-- 20 байт × 1,000,000 × 1.2 = 24 MB

-- Составной индекс (username, email):
-- (20 + 30) байт × 1,000,000 × 1.2 = 60 MB
```

### Реальные размеры индексов

| Тип индекса | Столбцы | Строк | Размер |
|-------------|---------|-------|--------|
| PRIMARY KEY | INT | 1 млн | 4 MB |
| UNIQUE | VARCHAR(50) | 1 млн | 50-60 MB |
| INDEX | VARCHAR(100) | 1 млн | 100-120 MB |
| COMPOSITE | 2×VARCHAR(50) | 1 млн | 100-120 MB |
| FULLTEXT | TEXT(1000) | 1 млн | 500 MB - 1 GB |

### Проверка размера индексов

```sql
-- Способ 1: Через INFORMATION_SCHEMA.TABLES
SELECT 
    TABLE_NAME,
    ROUND(DATA_LENGTH / 1024 / 1024, 2) AS data_size_mb,
    ROUND(INDEX_LENGTH / 1024 / 1024, 2) AS index_size_mb,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS total_mb,
    ROUND(INDEX_LENGTH * 100.0 / DATA_LENGTH, 2) AS index_ratio_percent
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'quiz_db'
ORDER BY total_mb DESC;

-- Способ 2: Детальная информация по индексам
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    ROUND(STAT_VALUE * @@innodb_page_size / 1024 / 1024, 2) AS size_mb
FROM mysql.innodb_index_stats
WHERE database_name = 'quiz_db'
  AND stat_name = 'size'
ORDER BY size_mb DESC;

-- Способ 3: Через SHOW TABLE STATUS
SHOW TABLE STATUS FROM quiz_db;
```

### Рекомендации по размеру индексов

| Размер БД | Рекомендуемый размер индексов |
|-----------|-------------------------------|
| < 1 GB | 10-20% от размера данных |
| 1-10 GB | 20-30% от размера данных |
| 10-100 GB | 30-50% от размера данных |
| > 100 GB | Индивидуальный расчёт |

### Селективность индекса

```sql
-- Селективность = Уникальные значения / Всего строк
-- Высокая селективность (> 0.3) — хороший кандидат для индекса

-- Пример для username (высокая селективность)
SELECT 
    COUNT(DISTINCT username) * 1.0 / COUNT(*) AS selectivity,
    COUNT(DISTINCT username) AS unique_values,
    COUNT(*) AS total_rows
FROM players;
-- Результат: 0.95 (отлично!)

-- Пример для status (низкая селективность)
SELECT 
    COUNT(DISTINCT status) * 1.0 / COUNT(*) AS selectivity,
    COUNT(DISTINCT status) AS unique_values,
    COUNT(*) AS total_rows
FROM game_sessions;
-- Результат: 0.003 (плохо, не стоит создавать индекс)
```

---

## 5.2. Оптимизация запросов с индексами

### EXPLAIN — анализ запросов

```sql
-- Базовый EXPLAIN
EXPLAIN SELECT * FROM players WHERE username = 'alex';

-- Расширенный EXPLAIN (MySQL 5.7+)
EXPLAIN FORMAT=JSON SELECT * FROM players WHERE username = 'alex';

-- EXPLAIN с выполнением (MySQL 8.0.18+)
EXPLAIN ANALYZE SELECT * FROM players WHERE username = 'alex';
```

### Поля EXPLAIN

```sql
EXPLAIN SELECT p.username, p.email, COUNT(gs.id) AS games
FROM players p
JOIN game_sessions gs ON p.id = gs.player_id
WHERE p.total_score > 1000
GROUP BY p.id
HAVING games > 5
ORDER BY games DESC
LIMIT 10;
```

| Поле | Значение | Описание |
|------|----------|----------|
| **id** | 1 | Номер SELECT в запросе |
| **select_type** | SIMPLE | Тип SELECT (SIMPLE, PRIMARY, SUBQUERY) |
| **table** | players | Таблица |
| **type** | ref | Тип соединения (см. ниже) |
| **possible_keys** | idx_username | Возможные индексы |
| **key** | idx_username | Используемый индекс |
| **key_len** | 202 | Длина используемого ключа (байты) |
| **ref** | const | Столбцы/константы для сравнения |
| **rows** | 1 | Оцениваемое количество строк |
| **filtered** | 100.00 | Процент отфильтрованных строк |
| **Extra** | Using index | Дополнительная информация |

### Типы доступа (type) — от лучшего к худшему

| Type | Описание | Пример |
|------|----------|--------|
| **system** | Одна строка в таблице | PRIMARY KEY с одним значением |
| **const** | Константа (1 строка) | WHERE id = 1 (PRIMARY KEY) |
| **eq_ref** | Уникальный ключ | JOIN по PRIMARY KEY |
| **ref** | Не уникальный индекс | WHERE username = 'alex' |
| **fulltext** | Полнотекстовый поиск | MATCH() AGAINST() |
| **range** | Диапазон по индексу | WHERE id BETWEEN 1 AND 100 |
| **index** | Полное сканирование индекса | SELECT COUNT(*) FROM table |
| **ALL** | Полное сканирование таблицы ❌ | WHERE LOWER(username) = 'alex' |

### Примеры оптимизации запросов

#### ❌ Плохо: функция в WHERE

```sql
-- Полное сканирование (type: ALL)
EXPLAIN SELECT * FROM players 
WHERE YEAR(created_at) = 2024;

-- ✅ Решение: диапазон дат
EXPLAIN SELECT * FROM players 
WHERE created_at >= '2024-01-01' 
  AND created_at < '2025-01-01';
-- type: range (использует индекс)
```

#### ❌ Плохо: LIKE с wildcard в начале

```sql
-- Полное сканирование (type: ALL)
EXPLAIN SELECT * FROM players 
WHERE username LIKE '%alex%';

-- ✅ Решение 1: FULLTEXT индекс
CREATE FULLTEXT INDEX ft_username ON players(username);

EXPLAIN SELECT * FROM players 
WHERE MATCH(username) AGAINST('alex' IN NATURAL LANGUAGE MODE);
-- type: fulltext

-- ✅ Решение 2: LIKE с префиксом
EXPLAIN SELECT * FROM players 
WHERE username LIKE 'alex%';
-- type: range (использует обычный индекс)
```

#### ❌ Плохо: OR без индексов

```sql
-- type: ALL
EXPLAIN SELECT * FROM questions 
WHERE difficulty = 'easy' OR view_count > 100;

-- ✅ Решение: UNION
EXPLAIN SELECT * FROM questions WHERE difficulty = 'easy'
UNION
SELECT * FROM questions WHERE view_count > 100;
-- type: ref / range (использует индексы)
```

#### ✅ Хорошо: Covering Index (Покрывающий индекс)

```sql
-- Создаём покрывающий индекс
CREATE INDEX idx_covering ON players(username, email, total_score);

-- Запрос использует только индекс (без обращения к таблице)
EXPLAIN SELECT username, email, total_score 
FROM players 
WHERE username = 'alex';
-- Extra: Using index (все данные в индексе!)
```

**Преимущества Covering Index:**
- Не нужно обращаться к таблице
- Все данные в индексе
- Максимальная производительность

#### ✅ Хорошо: Composite Index (Составной индекс)

```sql
-- Составной индекс для частого запроса
CREATE INDEX idx_score_category ON questions(category_id, difficulty);

-- Запрос использует индекс (порядок важен!)
EXPLAIN SELECT * FROM questions 
WHERE category_id = 5 AND difficulty = 'medium';
-- type: ref

-- ❌ Не использует индекс (нарушен порядок)
EXPLAIN SELECT * FROM questions 
WHERE difficulty = 'medium';
-- type: ALL
```

**Правило левой руки для составных индексов:**
```sql
-- Индекс: (A, B, C)

-- ✅ Работает:
WHERE A = 1
WHERE A = 1 AND B = 2
WHERE A = 1 AND B = 2 AND C = 3

-- ❌ Не работает:
WHERE B = 2            -- нет A
WHERE C = 3            -- нет A
WHERE B = 2 AND C = 3  -- нет A
```

### Профилирование запросов

```sql
-- Включение профилирования
SET profiling = 1;

-- Выполнение запроса
SELECT * FROM players WHERE username = 'alex';

-- Просмотр профиля
SHOW PROFILES;
SHOW PROFILE FOR QUERY 1;

-- Детальная статистика
SHOW PROFILE CPU, BLOCK IO, MEMORY FOR QUERY 1;

-- Отключение
SET profiling = 0;
```

### Медленные запросы

```sql
-- Включение медленного лога
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;  -- секунды
SET GLOBAL slow_query_log_file = '/var/log/mysql/slow.log';

-- Проверка статуса
SHOW VARIABLES LIKE 'slow_query_log%';
SHOW VARIABLES LIKE 'long_query_time';

-- Анализ медленных запросов (в терминале)
-- mysqldumpslow /var/log/mysql/slow.log
-- pt-query-digest /var/log/mysql/slow.log
```

### Обслуживание индексов

```sql
-- Анализ таблицы (обновление статистики)
ANALYZE TABLE players;

-- Проверка таблицы
CHECK TABLE players;

-- Оптимизация таблицы (дефрагментация)
OPTIMIZE TABLE players;

-- Удаление неиспользуемого индекса
DROP INDEX idx_unused ON players;

-- Проверка дубликатов индексов
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'quiz_db'
GROUP BY TABLE_NAME, INDEX_NAME
HAVING COUNT(*) > 1;
```

---

## 6. Полнотекстовый индекс

### Что такое полнотекстовый поиск?

**FULLTEXT индекс** позволяет выполнять поиск по текстовому содержимому с учётом морфологии.

### Создание полнотекстового индекса

```sql
-- При создании таблицы
CREATE TABLE questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_text VARCHAR(500),
    explanation TEXT,
    FULLTEXT INDEX ft_question_explanation (question_text, explanation)
) ENGINE=InnoDB;

-- Добавление к существующей таблице
ALTER TABLE questions ADD FULLTEXT INDEX ft_explanation (explanation);
```

### Режимы полнотекстового поиска

```sql
-- Естественный язык (по умолчанию)
SELECT * FROM questions
WHERE MATCH(question_text, explanation) AGAINST('история война' IN NATURAL LANGUAGE MODE);

-- С расширением (слова с * )
SELECT * FROM questions
WHERE MATCH(question_text, explanation) AGAINST('истори*' IN BOOLEAN MODE);

-- Точная фраза
SELECT * FROM questions
WHERE MATCH(question_text, explanation) AGAINST('"великая отечественная"' IN BOOLEAN MODE);

-- Исключение слов
SELECT * FROM questions
WHERE MATCH(question_text, explanation) AGAINST('+история -древняя' IN BOOLEAN MODE);
```

### Операторы BOOLEAN MODE

| Оператор | Описание | Пример |
|----------|----------|--------|
| **+** | Слово должно присутствовать | +история |
| **-** | Слово должно отсутствовать | -древняя |
| **\*** | Подстановочный знак | истори* |
| **"** | Точная фраза | "великая отечественная" |
| **>** | Повысить релевантность | >важное |
| **<** | Понизить релевантность | <менееважное |
| **()** | Группировка | +(история война) |

### Настройки полнотекстового поиска

```sql
-- Минимальная длина слова (по умолчанию 4)
SHOW VARIABLES LIKE 'ft_min_word_len';

-- Стоп-слова
SHOW VARIABLES LIKE 'ft_stopword_file';

-- Для InnoDB (MySQL 5.6+)
-- Минимальная длина для InnoDB
SHOW VARIABLES LIKE 'innodb_ft_min_token_size';
```

---

## 7. Оператор модификации ALTER

### ALTER TABLE

**ALTER TABLE** — оператор для изменения структуры существующей таблицы.

**Базовый синтаксис ALTER TABLE:**
```sql
-- Добавление столбца
ALTER TABLE table_name
    ADD [COLUMN] column_name datatype [constraints] [FIRST|AFTER column];

-- Изменение столбца
ALTER TABLE table_name
    MODIFY [COLUMN] column_name datatype [constraints];

-- Переименование столбца
ALTER TABLE table_name
    CHANGE [COLUMN] old_name new_name datatype [constraints];

-- Удаление столбца
ALTER TABLE table_name
    DROP [COLUMN] column_name;

-- Добавление индекса/ключа
ALTER TABLE table_name
    ADD [INDEX|KEY|UNIQUE|FULLTEXT] index_name (column_list);

-- Удаление индекса/ключа
ALTER TABLE table_name
    DROP INDEX index_name;
    DROP PRIMARY KEY;
    DROP FOREIGN KEY fk_name;

-- Переименование таблицы
ALTER TABLE old_name RENAME [TO] new_name;

-- Изменение движка и кодировки
ALTER TABLE table_name
    ENGINE=engine_name,
    CONVERT TO CHARACTER SET charset COLLATE collation;
```

**Параметры:**
- `ADD COLUMN` — добавить новый столбец
- `MODIFY COLUMN` — изменить тип/ограничения столбца (без переименования)
- `CHANGE COLUMN` — переименовать столбец и/или изменить тип
- `DROP COLUMN` — удалить столбец
- `FIRST` — добавить столбец первым
- `AFTER column` — добавить столбец после указанного
- `RENAME TO` — переименовать таблицу
- `CONVERT TO CHARACTER SET` — изменить кодировку таблицы и столбцов
- `ENGINE` — изменить движок таблицы

### Добавление столбца

```sql
-- Добавить столбец в конец
ALTER TABLE questions ADD COLUMN explanation TEXT;

-- Добавить столбец в начало
ALTER TABLE questions ADD COLUMN id INT FIRST;

-- Добавить столбец после другого
ALTER TABLE questions ADD COLUMN category_id INT AFTER id;

-- Добавить столбец с ограничениями
ALTER TABLE questions ADD COLUMN difficulty DECIMAL(3,2) DEFAULT 1.00 CHECK (difficulty >= 0 AND difficulty <= 10);
```

### Изменение столбца

```sql
-- Изменить тип данных
ALTER TABLE questions MODIFY COLUMN question_text VARCHAR(1000);

-- Изменить имя и тип
ALTER TABLE questions CHANGE COLUMN question_text text_content VARCHAR(1000);

-- Добавить NOT NULL
ALTER TABLE questions MODIFY COLUMN category_id INT NOT NULL;

-- Удалить NOT NULL
ALTER TABLE questions MODIFY COLUMN explanation TEXT NULL;

-- Изменить значение по умолчанию
ALTER TABLE questions MODIFY COLUMN status ENUM('active', 'inactive') DEFAULT 'active';
```

### Удаление столбца

```sql
ALTER TABLE questions DROP COLUMN explanation;
```

### Добавление ограничений

```sql
-- Первичный ключ
ALTER TABLE questions ADD PRIMARY KEY (id);

-- Уникальный ключ
ALTER TABLE questions ADD UNIQUE KEY unique_slug (slug);

-- Внешний ключ
ALTER TABLE session_answers ADD CONSTRAINT fk_question
    FOREIGN KEY (question_id) REFERENCES questions(id);

-- Индекс
ALTER TABLE questions ADD INDEX idx_question_text (question_text);
```

### Удаление ограничений

```sql
-- Первичный ключ
ALTER TABLE questions DROP PRIMARY KEY;

-- Уникальный ключ
ALTER TABLE questions DROP INDEX unique_slug;

-- Внешний ключ
ALTER TABLE session_answers DROP FOREIGN KEY fk_question;

-- Индекс
ALTER TABLE questions DROP INDEX idx_question_text;
```

### Переименование таблицы

```sql
-- Переименовать таблицу
ALTER TABLE questions RENAME TO question_bank;

-- Несколько таблиц
ALTER TABLE old_questions RENAME TO archived_questions,
             old_answers RENAME TO archived_answers;
```

### Изменение движка и кодировки

```sql
-- Изменить движок
ALTER TABLE questions ENGINE=MyISAM;

-- Изменить кодировку
ALTER TABLE questions CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Изменить кодировку столбца
ALTER TABLE questions MODIFY question_text VARCHAR(500) CHARACTER SET utf8mb4;
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
