# Модуль 3. Синтаксис выражений SQL для определения структуры данных (DDL)

**Продолжительность:** 4 академических часа

## Содержание модуля

1. DDL-операторы
2. Операторы создания базы
3. Создание таблиц
4. Временные таблицы
5. Индексы
   - Типы индексов
   - Кластерные и некластерные индексы
   - Размер индексов (расчёт и проверка)
6. Оператор EXPLAIN
   - Синтаксис и поля вывода
   - Типы доступа (type)
   - Анализ примеров
   - EXPLAIN FORMAT=JSON и ANALYZE
7. Полнотекстовый индекс
8. Оператор модификации ALTER

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

### Кластерные и некластерные индексы

**Важное различие по способу хранения данных:**

#### Кластерный индекс (Clustered Index)

**Определение:** Индекс, который определяет физический порядок хранения данных в таблице.

```
Кластерный индекс (PRIMARY KEY):
┌─────────────────────────────────┐
│ id │ username │ email          │  ← Данные хранятся В индексе
├────┼──────────┼────────────────┤
│ 1  │ alex     │ alex@test.com  │
│ 2  │ maria    │ maria@test.com │  ← Строки отсортированы по id
│ 3  │ ivan     │ ivan@test.com  │
│ 4  │ olga     │ olga@test.com  │
└─────────────────────────────────┘
```

**Особенности:**
- Данные таблицы хранятся в структуре индекса (B-дерево)
- Листовые узлы содержат полные строки данных
- Только **ОДИН** кластерный индекс на таблицу (данные не могут быть отсортированы по-разному физически)
- В InnoDB **PRIMARY KEY всегда кластерный**
- Быстрый доступ к данным (не нужно дополнительное обращение к таблице)

**В InnoDB:**
```sql
CREATE TABLE players (
    id INT PRIMARY KEY,  -- ← Кластерный индекс (данные сортируются по id)
    username VARCHAR(50),
    email VARCHAR(100)
) ENGINE=InnoDB;

-- Физический порядок строк будет по id
```

**Если нет PRIMARY KEY:**
1. InnoDB использует первый UNIQUE NOT NULL индекс
2. Если нет UNIQUE — создаётся скрытый кластерный индекс (GEN_CLUST_INDEX)

#### Некластерный индекс (Non-Clustered Index)

**Определение:** Индекс, который хранится отдельно от данных таблицы.

```
Некластерный индекс (INDEX на username):
┌─────────────────────┐      ┌─────────────────────────────────┐
│ username │ id      │      │ id │ username │ email          │
├──────────┼─────────┤      ├────┼──────────┼────────────────┤
│ alex     │ 1       │──────│ 1  │ alex     │ alex@test.com  │
│ ivan     │ 3       │──────│ 2  │ maria    │ maria@test.com │
│ maria    │ 2       │──────│ 3  │ ivan     │ ivan@test.com  │
│ olga     │ 4       │──────│ 4  │ olga     │ olga@test.com  │
└─────────────────────┘      └─────────────────────────────────┘
   Индекс                         Таблица (кластерный по id)
```

**Особенности:**
- Хранится отдельно от данных таблицы
- Листовые узлы содержат значения индекса + ссылку на строку (id)
- Может быть **множество** некластерных индексов на таблицу
- Требует дополнительного обращения к таблице (lookup)
- В InnoDB все индексы кроме PRIMARY KEY — некластерные

**В InnoDB:**
```sql
CREATE TABLE players (
    id INT PRIMARY KEY,  -- Кластерный
    username VARCHAR(50),
    email VARCHAR(100),
    INDEX idx_username (username)  -- ← Некластерный индекс
) ENGINE=InnoDB;
```

#### Сравнение кластерного и некластерного

| Характеристика | Кластерный | Некластерный |
|---------------|------------|--------------|
| **Количество** | Только 1 | Много |
| **Хранение** | Данные в индексе | Отдельно от данных |
| **Скорость SELECT** | Быстрее (нет lookup) | Медленнее (нужен lookup) |
| **Скорость INSERT** | Медленнее (сортировка) | Быстрее |
| **Скорость UPDATE ключа** | Медленная (пересортировка) | Быстрая |
| **Размер** | Размер таблицы | Дополнительно 10-20% |
| **В InnoDB** | PRIMARY KEY | Все остальные |

#### Как это работает в MySQL

**InnoDB (движок по умолчанию):**

```sql
CREATE TABLE questions (
    id INT PRIMARY KEY,        -- Кластерный индекс
    category_id INT,
    question_text TEXT,
    difficulty ENUM('easy', 'medium', 'hard'),
    points DECIMAL(5,2),
    
    INDEX idx_category (category_id),     -- Некластерный
    INDEX idx_difficulty (difficulty),    -- Некластерный
    FULLTEXT INDEX ft_question (question_text)  -- Некластерный
) ENGINE=InnoDB;
```

**Структура хранения:**

```
Кластерный индекс (PRIMARY KEY):
┌──────────────────────────────────────────────┐
│ id (ключ) │ category_id │ question_text │... │  ← Данные здесь
├───────────┼─────────────┼───────────────┼────┤
│ 1         │ 1           │ "Что такое... │... │
│ 2         │ 1           │ "Какой опер...│... │
│ 3         │ 2           │ "Что такое... │... │
└──────────────────────────────────────────────┘

Некластерный индекс (idx_category):
┌───────────────┬────┐      ┌────────────────────┐
│ category_id   │ id │──────│ PRIMARY KEY (id)   │  ← Ссылка на кластерный
├───────────────┼────┤      ├────────────────────┤
│ 1             │ 1  │      │ id=1: данные...    │
│ 1             │ 2  │      │ id=2: данные...    │
│ 2             │ 3  │      │ id=3: данные...    │
└───────────────┴────┘      └────────────────────┘
```

**Поиск по некластерному индексу:**

```sql
SELECT * FROM questions WHERE category_id = 1;
```

1. Находим `category_id = 1` в некластерном индексе
2. Получаем `id = 1, 2`
3. Идём в кластерный индекс по `id`
4. Получаем полные строки

**Это называется "Index Lookup" или "Bookmark Lookup"**

#### Покрытие индекса (Covering Index)

**Определение:** Некластерный индекс, который содержит ВСЕ данные для запроса.

```sql
-- Создаём покрывающий индекс
CREATE INDEX idx_covering ON questions (category_id, difficulty, points);

-- Запрос использует только индекс (без обращения к таблице!)
EXPLAIN SELECT category_id, difficulty, points 
FROM questions 
WHERE category_id = 1;
-- Extra: Using index (все данные в некластерном индексе!)
```

**Преимущества:**
- Не нужно обращаться к кластерному индексу
- Все данные уже в некластерном индексе
- Максимальная производительность

#### MyISAM (устаревший движок)

В MyISAM **все индексы некластерные**:

```sql
CREATE TABLE questions_myisam (
    id INT PRIMARY KEY,
    question_text TEXT
) ENGINE=MyISAM;  -- Все индексы некластерные
```

**Структура:**
```
Индексы (.MYI)         Данные (.MYD)
┌───────────┬────┐     ┌────────────────────┐
│ id        │ptr │────▶│ ptr: данные...     │
└───────────┴────┘     └────────────────────┘
```

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

---

## 5.3. Оператор EXPLAIN — Анализ запросов

### Что такое EXPLAIN?

**EXPLAIN** — оператор для анализа плана выполнения запроса без его фактического выполнения.

**Назначение:**
- Показать, как MySQL выполняет запрос
- Определить используемые индексы
- Найти узкие места производительности
- Оптимизировать медленные запросы

### Синтаксис EXPLAIN

```sql
-- Базовый синтаксис
EXPLAIN select_statement;

-- С указанием таблиц
EXPLAIN table_name;

-- Расширенный формат (MySQL 5.7+, MariaDB 10.1+)
EXPLAIN FORMAT=JSON select_statement;

-- С выполнением запроса (MySQL 8.0.18+)
EXPLAIN ANALYZE select_statement;

-- Для удалённого сервера (MySQL 8.0+)
EXPLAIN FORMAT=TREE select_statement;
```

**Параметры:**
- `FORMAT=TABULAR` — табличный формат (по умолчанию)
- `FORMAT=JSON` — JSON с детальной статистикой
- `FORMAT=TREE` — древовидный формат (MySQL 8.0+)
- `ANALYZE` — выполнить запрос с профилированием

**Важно:** В MariaDB 10.10+ используется отдельная команда `ANALYZE`:

```sql
-- MariaDB 10.10+
ANALYZE SELECT * FROM players;
ANALYZE FORMAT=JSON SELECT * FROM players;
ANALYZE FORMAT=BOX SELECT * FROM players;  -- ASCII-графика
ANALYZE FORMAT=TREE SELECT * FROM players;
```

### Поля вывода EXPLAIN

```sql
EXPLAIN SELECT p.username, p.email, COUNT(gs.id) AS games_count
FROM players p
JOIN game_sessions gs ON p.id = gs.player_id
WHERE p.total_score > 1000
  AND gs.status = 'completed'
GROUP BY p.id
HAVING games_count > 5
ORDER BY games_count DESC
LIMIT 10;
```

**Пример вывода:**

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|----|-------------|-------|------|---------------|-----|---------|-----|------|----------|-------|
| 1 | SIMPLE | p | range | idx_score | idx_score | 5 | NULL | 50000 | 100.00 | Using where; Using temporary; Using filesort |
| 1 | SIMPLE | gs | ref | idx_player,idx_status | idx_player | 5 | p.id | 10 | 10.00 | Using where |

### Подробное описание полей

#### 1. id

**Описание:** Номер последовательности выполнения SELECT.

**Значения:**
- Одинаковый `id` — таблицы обрабатываются в порядке сверху вниз
- Разный `id` — вложенные запросы (подзапросы)
- `NULL` — объединение результатов (UNION)

```sql
-- Пример с подзапросом
EXPLAIN SELECT * FROM players 
WHERE id IN (SELECT player_id FROM game_sessions WHERE score > 100);
```

```
| id | select_type    | table         |
|----|----------------|---------------|
| 1  | PRIMARY        | players       |  ← Внешний запрос
| 2  | SUBQUERY       | game_sessions |  ← Подзапрос
```

#### 2. select_type

**Описание:** Тип SELECT запроса.

| Значение | Описание | Пример |
|----------|----------|--------|
| **SIMPLE** | Простой SELECT без UNION и подзапросов | `SELECT * FROM table` |
| **PRIMARY** | Внешний запрос | `SELECT ... FROM (SELECT ...) AS sub` |
| **SUBQUERY** | Подзапрос в SELECT | `SELECT (SELECT COUNT(*) FROM ...) AS cnt` |
| **DERIVED** | Подзапрос в FROM | `SELECT * FROM (SELECT ...) AS sub` |
| **UNION** | Второй или последующий SELECT в UNION | `SELECT ... UNION SELECT ...` |
| **UNION RESULT** | Результат UNION | `SELECT ... UNION SELECT ...` |

```sql
-- UNION пример
EXPLAIN SELECT id FROM players WHERE total_score > 1000
UNION
SELECT id FROM players WHERE games_played > 50;
```

```
| id | select_type    | table   |
|----|----------------|---------|
| 1  | PRIMARY        | players |
| 2  | UNION          | players |
| NULL | UNION RESULT | NULL    |
```

#### 3. table

**Описание:** Имя таблицы (или псевдоним).

```sql
EXPLAIN SELECT p.username FROM players p;
```

```
| table |
|-------|
| p     |  ← Псевдоним
```

#### 4. type (ВАЖНО!)

**Описание:** Тип соединения/доступа к данным. **Один из самых важных показателей!**

**От лучшего к худшему:**

| Type | Описание | Пример |
|------|----------|--------|
| **system** | Таблица содержит одну строку | `SELECT * FROM single_row_table` |
| **const** | Константа (1 строка по PRIMARY/UNIQUE) | `WHERE id = 1` |
| **eq_ref** | Уникальный ключ (1 строка на комбинацию) | `JOIN по PRIMARY KEY` |
| **ref** | Не уникальный индекс (несколько строк) | `WHERE username = 'alex'` |
| **fulltext** | Полнотекстовый поиск | `MATCH() AGAINST()` |
| **ref_or_null** | ref + проверка на NULL | `WHERE col = 'val' OR col IS NULL` |
| **index_merge** | Объединение нескольких индексов | `WHERE col1 = 1 OR col2 = 2` |
| **range** | Диапазон по индексу | `WHERE id BETWEEN 1 AND 100` |
| **index** | Полное сканирование индекса | `SELECT COUNT(*) FROM table` |
| **ALL** | Полное сканирование таблицы ❌ | `WHERE LOWER(username) = 'alex'` |

**Рекомендации:**
- ✅ **Хорошо:** system, const, eq_ref, ref, range
- ⚠️ **Допустимо:** index (для COUNT, MIN, MAX)
- ❌ **Плохо:** ALL (особенно на больших таблицах)

**Примеры:**

```sql
-- const (отлично)
EXPLAIN SELECT * FROM players WHERE id = 1;
-- type: const

-- ref (хорошо)
EXPLAIN SELECT * FROM players WHERE username = 'alex';
-- type: ref

-- range (хорошо)
EXPLAIN SELECT * FROM players WHERE total_score > 1000;
-- type: range

-- ALL (плохо)
EXPLAIN SELECT * FROM players WHERE YEAR(created_at) = 2024;
-- type: ALL (функция в WHERE)
```

#### 5. possible_keys

**Описание:** Индексы, которые **могут** быть использованы.

```sql
EXPLAIN SELECT * FROM players WHERE username = 'alex' AND total_score > 1000;
```

```
| possible_keys        |
|----------------------|
| idx_username,idx_score |
```

**Если NULL:** Нет подходящих индексов — создайте!

#### 6. key

**Описание:** Индекс, который **фактически** используется.

```sql
EXPLAIN SELECT * FROM players WHERE username = 'alex';
```

```
| key        |
|------------|
| idx_username |
```

**Если NULL:** Индекс не используется — проверьте запрос!

#### 7. key_len

**Описание:** Длина используемой части индекса в байтах.

**Расчёт:**
- `INT` = 4 байта
- `BIGINT` = 8 байт
- `VARCHAR(N)` = N × 3 + 2 байта (utf8mb4)
- `NULL` = +1 байт

```sql
CREATE INDEX idx_composite ON players (username, total_score);
-- username VARCHAR(50) = 50×3 + 2 = 152 байта
-- total_score INT = 4 байта
-- NULL не разрешён = 0 байт

EXPLAIN SELECT * FROM players WHERE username = 'alex' AND total_score > 1000;
```

```
| key_len |
|---------|
| 156     |  ← 152 + 4 = используется весь индекс
```

**Если key_len меньше ожидаемого:** Используется только часть индекса!

#### 8. ref

**Описание:** Столбцы или константы для сравнения с индексом.

```sql
EXPLAIN SELECT p.*, gs.score 
FROM players p
JOIN game_sessions gs ON p.id = gs.player_id
WHERE p.username = 'alex';
```

```
| table | ref                    |
|-------|------------------------|
| p     | const                  |  ← Константа
| gs    | p.id                   |  ← Столбец из другой таблицы |
```

**Значения:**
- `const` — сравнение с константой
- `table.column` — сравнение со столбцом
- `func` — результат функции

#### 9. rows (ВАЖНО!)

**Описание:** Оцениваемое количество строк для проверки.

```sql
EXPLAIN SELECT * FROM players WHERE username = 'alex';
```

```
| rows |
|------|
| 1    |  ← Ожидается 1 строка (уникальный индекс)
```

```sql
EXPLAIN SELECT * FROM players WHERE total_score > 1000;
```

```
| rows  |
|-------|
| 50000 |  ← Ожидается 50000 строк (диапазон)
```

**Чем меньше, тем лучше!**

#### 10. filtered

**Описание:** Процент строк, прошедших фильтрацию (MySQL 5.7+).

```sql
EXPLAIN SELECT * FROM players WHERE username = 'alex' AND total_score > 1000;
```

```
| rows | filtered |
|------|----------|
| 100  | 10.00    |  ← 10% строк пройдут фильтр
```

**Расчёт:** `rows × filtered / 100` = фактическое количество строк

#### 11. Extra (ВАЖНО!)

**Описание:** Дополнительная информация о выполнении.

| Значение | Описание | Хорошо/Плохо |
|----------|----------|--------------|
| **Using index** | Все данные в индексе (Covering Index) | ✅ Отлично |
| **Using where** | Фильтрация по WHERE | ✅ Нормально |
| **Using index condition** | Индекс используется для фильтрации | ✅ Хорошо |
| **Using temporary** | Временная таблица для GROUP BY/SORT | ⚠️ Плохо |
| **Using filesort** | Сортировка вне индекса | ⚠️ Плохо |
| **Using join buffer** | Буфер для JOIN без индекса | ❌ Очень плохо |
| **Impossible WHERE** | WHERE всегда ложен | ⚠️ Проверьте логику |
| **Distinct** | Оптимизация DISTINCT | ✅ Нормально |
| **Not exists** | Оптимизация NOT EXISTS | ✅ Нормально |

**Примеры:**

```sql
-- Using index (отлично)
EXPLAIN SELECT username FROM players WHERE username = 'alex';
-- Extra: Using index

-- Using temporary; Using filesort (плохо)
EXPLAIN SELECT username, COUNT(*) 
FROM players 
GROUP BY username 
ORDER BY COUNT(*) DESC;
-- Extra: Using temporary; Using filesort

-- Using where; Using index condition (хорошо)
EXPLAIN SELECT * FROM players WHERE total_score > 1000;
-- Extra: Using where; Using index condition
```

### Примеры анализа запросов

#### Пример 1: Простой SELECT с индексом

```sql
EXPLAIN SELECT * FROM players WHERE id = 1;
```

**Вывод:**

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|----|-------------|-------|------|---------------|-----|---------|-----|------|----------|-------|
| 1 | SIMPLE | players | const | PRIMARY | PRIMARY | 4 | const | 1 | 100.00 | NULL |

**Анализ:**
- ✅ `type: const` — отличный доступ по PRIMARY KEY
- ✅ `rows: 1` — ожидается 1 строка
- ✅ `key: PRIMARY` — используется первичный ключ
- **Вывод:** Запрос оптимизирован идеально

#### Пример 2: SELECT с диапазоном

```sql
EXPLAIN SELECT * FROM players WHERE total_score > 1000;
```

**Вывод:**

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|----|-------------|-------|------|---------------|-----|---------|-----|------|----------|-------|
| 1 | SIMPLE | players | range | idx_score | idx_score | 5 | NULL | 50000 | 100.00 | Using where |

**Анализ:**
- ✅ `type: range` — хороший диапазон по индексу
- ⚠️ `rows: 50000` — много строк, но это диапазон
- ✅ `key: idx_score` — используется индекс
- **Вывод:** Запрос оптимизирован хорошо

#### Пример 3: SELECT без индекса (ПЛОХО)

```sql
EXPLAIN SELECT * FROM players WHERE YEAR(created_at) = 2024;
```

**Вывод:**

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|----|-------------|-------|------|---------------|-----|---------|-----|------|----------|-------|
| 1 | SIMPLE | players | ALL | NULL | NULL | NULL | NULL | 1000000 | 10.00 | Using where |

**Анализ:**
- ❌ `type: ALL` — полное сканирование таблицы!
- ❌ `possible_keys: NULL` — нет подходящих индексов
- ❌ `key: NULL` — индекс не используется
- ❌ `rows: 1000000` — сканируем миллион строк!
- **Проблема:** Функция `YEAR()` в WHERE предотвращает использование индекса
- **Решение:**

```sql
-- Создаём индекс
CREATE INDEX idx_created ON players(created_at);

-- Переписываем запрос
SELECT * FROM players 
WHERE created_at >= '2024-01-01' 
  AND created_at < '2025-01-01';
```

**После оптимизации:**

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|----|-------------|-------|------|---------------|-----|---------|-----|------|----------|-------|
| 1 | SIMPLE | players | range | idx_created | idx_created | 5 | NULL | 100000 | 100.00 | Using where |

- ✅ `type: range` — диапазон по индексу
- ✅ `rows: 100000` — в 10 раз меньше строк
- **Улучшение:** В 10 раз быстрее!

#### Пример 4: JOIN с индексами

```sql
EXPLAIN SELECT p.username, gs.score
FROM players p
JOIN game_sessions gs ON p.id = gs.player_id
WHERE p.total_score > 1000;
```

**Вывод:**

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|----|-------------|-------|------|---------------|-----|---------|-----|------|----------|-------|
| 1 | SIMPLE | p | range | idx_score | idx_score | 5 | NULL | 50000 | 100.00 | Using where |
| 1 | SIMPLE | gs | ref | idx_player | idx_player | 5 | p.id | 10 | 100.00 | Using where |

**Анализ:**
- ✅ `p.type: range` — диапазон по индексу
- ✅ `gs.type: ref` — соединение по индексу
- ✅ `gs.ref: p.id` — используется связь
- ✅ `gs.rows: 10` — мало строк на соединение
- **Вывод:** JOIN оптимизирован хорошо

#### Пример 5: GROUP BY с проблемами

```sql
EXPLAIN SELECT username, COUNT(*) AS games
FROM game_sessions gs
JOIN players p ON gs.player_id = p.id
GROUP BY p.username
ORDER BY games DESC
LIMIT 10;
```

**Вывод:**

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|----|-------------|-------|------|---------------|-----|---------|-----|------|----------|-------|
| 1 | SIMPLE | gs | ALL | idx_player | NULL | NULL | NULL | 500000 | 100.00 | Using temporary; Using filesort |
| 1 | SIMPLE | p | eq_ref | PRIMARY | PRIMARY | 4 | gs.player_id | 1 | 100.00 | Using index |

**Анализ:**
- ❌ `gs.type: ALL` — полное сканирование!
- ❌ `Extra: Using temporary; Using filesort` — временная таблица и сортировка
- **Проблема:** Нет индекса для GROUP BY
- **Решение:**

```sql
-- Создаём индекс для GROUP BY
CREATE INDEX idx_player_id ON game_sessions(player_id);

-- Или покрывающий индекс
CREATE INDEX idx_player_count ON game_sessions(player_id, score);
```

### EXPLAIN FORMAT=JSON

```sql
EXPLAIN FORMAT=JSON 
SELECT * FROM players WHERE total_score > 1000;
```

**Пример вывода (сокращённо):**

```json
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "60001.20"
    },
    "table": {
      "table_name": "players",
      "access_type": "range",
      "possible_keys": ["idx_score"],
      "key": "idx_score",
      "key_length": "5",
      "used_key_parts": ["total_score"],
      "rows": 50000,
      "filtered": 100.00,
      "index_condition": "(total_score > 1000)",
      "cost_info": {
        "read_cost": "10000.00",
        "eval_cost": "50000.00",
        "prefix_cost": "60001.20"
      }
    }
  }
}
```

**Преимущества JSON формата:**
- Детальная информация о стоимости
- Использованные части индекса
- Стоимость чтения и вычислений
- Планировщик запросов

### EXPLAIN ANALYZE (MySQL 8.0.18+)

```sql
EXPLAIN ANALYZE 
SELECT * FROM players WHERE total_score > 1000;
```

**Пример вывода:**

```
-> Index range scan on players using idx_score (total_score > 1000)  
   (cost=60001.20 rows=50000) (actual time=0.500..150.250 rows=50000 loops=1)
```

**Преимущества:**
- Фактическое время выполнения
- Фактическое количество строк
- Количество циклов
- Реальная производительность

### Рекомендации по оптимизации

#### 1. Избегайте type: ALL

```sql
-- ❌ Плохо
EXPLAIN SELECT * FROM questions WHERE YEAR(created_at) = 2024;
-- type: ALL

-- ✅ Хорошо
EXPLAIN SELECT * FROM questions 
WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01';
-- type: range
```

#### 2. Создавайте индексы для WHERE

```sql
-- ❌ Нет индекса
EXPLAIN SELECT * FROM players WHERE email = 'test@example.com';
-- type: ALL, key: NULL

-- ✅ Создаём индекс
CREATE INDEX idx_email ON players(email);

EXPLAIN SELECT * FROM players WHERE email = 'test@example.com';
-- type: ref, key: idx_email
```

#### 3. Используйте Covering Index

```sql
-- ✅ Все данные в индексе
CREATE INDEX idx_covering ON players(username, email);

EXPLAIN SELECT username, email FROM players WHERE username = 'alex';
-- Extra: Using index (без обращения к таблице!)
```

#### 4. Избегайте Using temporary и Using filesort

```sql
-- ❌ Временная таблица и сортировка
EXPLAIN SELECT username, COUNT(*) 
FROM players 
GROUP BY username 
ORDER BY COUNT(*) DESC;
-- Extra: Using temporary; Using filesort

-- ✅ Индекс для GROUP BY
CREATE INDEX idx_username ON players(username);

EXPLAIN SELECT username, COUNT(*) 
FROM players 
GROUP BY username;
-- Extra: Using index for group-by
```

#### 5. Проверяйте порядок столбцов в составном индексе

```sql
CREATE INDEX idx_composite ON players (category_id, difficulty, points);

-- ✅ Использует индекс
EXPLAIN SELECT * FROM players 
WHERE category_id = 1 AND difficulty = 'easy';

-- ✅ Использует часть индекса
EXPLAIN SELECT * FROM players 
WHERE category_id = 1;

-- ❌ Не использует индекс (нарушен порядок)
EXPLAIN SELECT * FROM players 
WHERE difficulty = 'easy';
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
