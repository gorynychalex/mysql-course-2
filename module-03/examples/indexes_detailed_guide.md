# Индексы в MySQL/MariaDB: Подробное руководство

## Содержание

1. [Что такое индекс и зачем он нужен](#1-что-такое-индекс-и-зачем-он-нужен)
2. [Типы индексов](#2-типы-индексов)
3. [Размер индексов](#3-размер-индексов)
4. [Оптимизация запросов с индексами](#4-оптимизация-запросов-с-индексами)
5. [Планы выполнения запросов](#5-планы-выполнения-запросов)
6. [Лучшие практики](#6-лучшие-практики)

---

## 1. Что такое индекс и зачем он нужен

### Аналогия с книгой

Индекс в базе данных — это как **предметный указатель в конце книги**:

| Без индекса | С индексом |
|-------------|------------|
| Читать всю книгу подряд | Открыть указатель → найти страницу |
| Полное сканирование таблицы | Быстрый поиск по индексу |
| O(n) — линейный поиск | O(log n) — логарифмический поиск |

### Как работает индекс

```
Таблица без индекса (полное сканирование):
┌─────────────────────────────────┐
│ id │ username │ email          │
├────┼──────────┼────────────────┤
│ 1  │ alex     │ alex@test.com  │ ← Ищем "olga"
│ 2  │ maria    │ maria@test.com │   просматриваем
│ 3  │ ivan     │ ivan@test.com  │   ВСЕ строки
│ 4  │ olga     │ olga@test.com  │   нашли!
│ 5  │ dmitry   │ dmitry@test.com│
└─────────────────────────────────┘

Таблица с индексом (быстрый поиск):
Индекс по username (B-дерево):
        ┌──────────┐
        │  maria   │
       /            \
  ┌─────┐          ┌─────┐
  │alex │          │olga │
  /   \            /   \
ivan  maria     olga  dmitry

Поиск: alex → maria → olga (3 шага вместо 5)
```

---

## 2. Типы индексов

### B-Tree (B-дерево) — по умолчанию

```sql
-- Создаётся автоматически для PRIMARY KEY и UNIQUE
CREATE INDEX idx_username ON players(username);

-- Структура B-дерева:
-- Корневой узел
--     ├── Промежуточный узел
--     │   ├── Листовой узел → данные
--     │   └── Листовой узел → данные
--     └── Промежуточный узел
--         ├── Листовой узел → данные
--         └── Листовой узел → данные
```

**Характеристики:**
- Сбалансированное дерево
- Все листовые узлы на одном уровне
- Поддерживает: =, <, >, <=, >=, BETWEEN, LIKE 'prefix%'
- Размер: O(n)

### Hash Index

```sql
-- Только для MEMORY и NDB движков
CREATE INDEX idx_hash ON players USING HASH (username);
```

**Характеристики:**
- Хэш-таблица вместо дерева
- Поддерживает только: =, <=>, IN
- Не поддерживает: <, >, BETWEEN, LIKE
- Быстрее для точных совпадений
- Размер: O(n)

### Full-Text Index

```sql
-- Для полнотекстового поиска
CREATE FULLTEXT INDEX ft_question ON questions(question_text);

-- Использование:
SELECT * FROM questions
WHERE MATCH(question_text) AGAINST('база данных' IN NATURAL LANGUAGE MODE);
```

**Характеристики:**
- Специальная структура для поиска по тексту
- Игнорирует стоп-слова
- Поддерживает морфологию (для MariaDB с плагинами)
- Размер: 100-200% от размера текста

### Spatial Index (R-дерево)

```sql
-- Для геопространственных данных
CREATE SPATIAL INDEX idx_location ON places(location);
```

**Характеристики:**
- Для GIS данных (координаты, полигоны)
- Использует R-дерево
- Размер: зависит от сложности геометрии

### Composite Index (Составной)

```sql
-- Индекс по нескольким столбцам
CREATE INDEX idx_player_game ON session_answers(player_id, game_id);
```

**Правило левой руки:**
```sql
-- Индекс: (A, B, C)

-- ✅ Работает:
WHERE A = 1
WHERE A = 1 AND B = 2
WHERE A = 1 AND B = 2 AND C = 3
WHERE A = 1 AND C = 3  -- только A

-- ❌ Не работает:
WHERE B = 2            -- нет A
WHERE C = 3            -- нет A
WHERE B = 2 AND C = 3  -- нет A
```

### Covering Index (Покрывающий)

```sql
-- Индекс покрывает все столбцы запроса
CREATE INDEX idx_covering ON players(username, email, total_score);

-- Запрос использует только индекс (без обращения к таблице)
SELECT username, email, total_score FROM players WHERE username = 'alex';
```

**Преимущества:**
- Не нужно обращаться к таблице
- Все данные в индексе
- Максимальная производительность

---

## 3. Размер индексов

### Формула расчёта размера

```
Размер индекса = Размер_ключа × Количество_строк × Коэффициент

Для B-дерева:
- Размер ключа: сумма размеров столбцов индекса
- Количество строк: COUNT(*) в таблице
- Коэффициент: 1.2 - 1.5 (накладные расходы дерева)
```

### Пример расчёта

```sql
-- Таблица players
CREATE TABLE players (
    id INT UNSIGNED,           -- 4 байта
    username VARCHAR(50),      -- 50 байт + 1 байт длина
    email VARCHAR(100),        -- 100 байт + 1 байт длина
    total_score INT            -- 4 байта
);

-- Индекс по username:
-- Средний размер username: 20 символов = 20 байт (utf8mb4)
-- Количество строк: 1,000,000
-- Размер = 20 × 1,000,000 × 1.2 = 24 MB

-- Составной индекс (username, email):
-- Средний размер: 20 + 50 = 70 байт
-- Размер = 70 × 1,000,000 × 1.2 = 84 MB
```

### Практический пример

```sql
-- Создадим тестовую таблицу
CREATE TABLE players_test (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    total_score INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Заполним 1 миллион записей
INSERT INTO players_test (username, email, total_score)
SELECT 
    CONCAT('user_', seq),
    CONCAT('user_', seq, '@example.com'),
    FLOOR(RAND() * 10000)
FROM (
    SELECT @row := @row + 1 AS seq 
    FROM information_schema.COLUMNS c1, 
         information_schema.COLUMNS c2,
         (SELECT @row := 0) r
    LIMIT 1000000
) AS numbers;

-- Проверим размер таблицы и индексов
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    ROUND(STAT_VALUE * @@innodb_page_size / 1024 / 1024, 2) AS size_mb
FROM mysql.innodb_index_stats
WHERE database_name = 'quiz_db' 
  AND table_name = 'players_test'
  AND stat_name = 'size';

-- Альтернативный способ
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    ROUND(STAT_VALUE * 16 / 1024, 2) AS size_mb  -- 16KB страница
FROM mysql.innodb_index_stats
WHERE database_name = 'quiz_db'
  AND stat_name = 'size';
```

### Реальные размеры (примеры)

| Тип индекса | Столбцы | Строк | Размер |
|-------------|---------|-------|--------|
| PRIMARY KEY | INT | 1 млн | 4 MB |
| UNIQUE | VARCHAR(50) | 1 млн | 50-60 MB |
| INDEX | VARCHAR(100) | 1 млн | 100-120 MB |
| COMPOSITE | 2×VARCHAR(50) | 1 млн | 100-120 MB |
| FULLTEXT | TEXT(1000) | 1 млн | 500 MB - 1 GB |

### Проверка размера индексов

```sql
-- Размер всех индексов в базе
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    ROUND(STAT_VALUE * @@innodb_page_size / 1024 / 1024, 2) AS size_mb
FROM mysql.innodb_index_stats
WHERE database_name = 'quiz_db'
  AND stat_name = 'size'
ORDER BY size_mb DESC;

-- Размер через INFORMATION_SCHEMA
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    ROUND(INDEX_LENGTH / 1024 / 1024, 2) AS index_size_mb,
    ROUND(DATA_LENGTH / 1024 / 1024, 2) AS data_size_mb,
    ROUND((INDEX_LENGTH + DATA_LENGTH) / 1024 / 1024, 2) AS total_mb
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'quiz_db'
ORDER BY total_mb DESC;

-- Статистика по индексу
SHOW INDEX FROM players;
```

---

## 4. Оптимизация запросов с индексами

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
| **select_type** | SIMPLE | Тип SELECT (SIMPLE, PRIMARY, SUBQUERY, DERIVED) |
| **table** | players | Таблица |
| **partitions** | NULL | Секции (если есть секционирование) |
| **type** | ref | Тип соединения (см. ниже) |
| **possible_keys** | idx_username | Возможные индексы |
| **key** | idx_username | Используемый индекс |
| **key_len** | 202 | Длина используемого ключа (байты) |
| **ref** | const | Столбцы/константы для сравнения |
| **rows** | 1 | Оцениваемое количество строк |
| **filtered** | 100.00 | Процент отфильтрованных строк |
| **Extra** | Using index | Дополнительная информация |

### Типы доступа (type)

**От лучшего к худшему:**

| Type | Описание | Пример |
|------|----------|--------|
| **system** | Одна строка в таблице | PRIMARY KEY с одним значением |
| **const** | Константа (1 строка) | WHERE id = 1 (PRIMARY KEY) |
| **eq_ref** | Уникальный ключ | JOIN по PRIMARY KEY |
| **ref** | Не уникальный индекс | WHERE username = 'alex' |
| **fulltext** | Полнотекстовый поиск | MATCH() AGAINST() |
| **ref_or_null** | ref + проверка на NULL | WHERE col = 'val' OR col IS NULL |
| **index_merge** | Объединение индексов | WHERE col1 = 1 OR col2 = 2 |
| **range** | Диапазон по индексу | WHERE id BETWEEN 1 AND 100 |
| **index** | Полное сканирование индекса | SELECT COUNT(*) FROM table |
| **ALL** | Полное сканирование таблицы | WHERE LOWER(username) = 'alex' |

### Примеры оптимизации

#### ❌ Плохо: функция в WHERE

```sql
-- Полное сканирование (ALL)
EXPLAIN SELECT * FROM players 
WHERE YEAR(created_at) = 2024;

-- Решение: диапазон дат
EXPLAIN SELECT * FROM players 
WHERE created_at >= '2024-01-01' 
  AND created_at < '2025-01-01';
-- type: range
```

#### ❌ Плохо: LIKE с wildcard в начале

```sql
-- Полное сканирование (ALL)
EXPLAIN SELECT * FROM players 
WHERE username LIKE '%alex%';

-- Решение: FULLTEXT индекс
CREATE FULLTEXT INDEX ft_username ON players(username);

EXPLAIN SELECT * FROM players 
WHERE MATCH(username) AGAINST('alex' IN NATURAL LANGUAGE MODE);
-- type: fulltext
```

#### ❌ Плохо: OR без индексов

```sql
-- type: ALL
EXPLAIN SELECT * FROM questions 
WHERE difficulty = 'easy' OR view_count > 100;

-- Решение: UNION
EXPLAIN SELECT * FROM questions WHERE difficulty = 'easy'
UNION
SELECT * FROM questions WHERE view_count > 100;
-- type: ref / range
```

#### ✅ Хорошо: Covering Index

```sql
-- Создаём покрывающий индекс
CREATE INDEX idx_covering ON players(username, email, total_score);

-- Запрос использует только индекс
EXPLAIN SELECT username, email, total_score 
FROM players 
WHERE username = 'alex';
-- Extra: Using index (без обращения к таблице!)
```

#### ✅ Хорошо: Composite Index

```sql
-- Составной индекс для частого запроса
CREATE INDEX idx_score_category ON questions(total_score, category_id);

-- Запрос использует индекс
EXPLAIN SELECT * FROM questions 
WHERE total_score > 1000 AND category_id = 5;
-- type: range
```

---

## 5. Планы выполнения запросов

### Визуализация плана

```sql
-- MySQL 8.0.18+
EXPLAIN ANALYZE SELECT * FROM players WHERE username = 'alex';
```

**Пример вывода:**
```
-> Index lookup on players using idx_username (username='alex')  
   (cost=0.30 rows=1) (actual time=0.050..0.051 rows=1 loops=1)
```

### EXPLAIN FORMAT=JSON

```sql
EXPLAIN FORMAT=JSON 
SELECT * FROM players WHERE total_score > 1000;
```

**Пример вывода:**
```json
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "1234.56"
    },
    "table": {
      "table_name": "players",
      "access_type": "range",
      "possible_keys": ["idx_score"],
      "key": "idx_score",
      "used_key_parts": ["total_score"],
      "key_length": "5",
      "rows_examined_per_scan": 10000,
      "rows_produced_per_join": 1000,
      "filtered": "10.00",
      "index_condition": "(total_score > 1000)",
      "cost_info": {
        "read_cost": "1000.00",
        "eval_cost": "200.00",
        "prefix_cost": "1200.00"
      }
    }
  }
}
```

### Статистика выполнения

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

-- Анализ медленных запросов (утилита)
-- mysqldumpslow /var/log/mysql/slow.log
-- pt-query-digest /var/log/mysql/slow.log
```

---

## 6. Лучшие практики

### Когда создавать индексы

✅ **Создавать:**
- Первичные ключи (автоматически)
- Внешние ключи (для JOIN)
- Столбцы в WHERE
- Столбцы в ORDER BY
- Столбцы в GROUP BY
- Столбцы в DISTINCT
- Столбцы в JOIN условиях

❌ **Не создавать:**
- На маленьких таблицах (< 1000 строк)
- На столбцах с низкой селективностью (пол, статус)
- На часто изменяемых столбцах (INSERT/UPDATE/DELETE)
- Дублирующие индексы
- Слишком широкие составные индексы

### Селективность индекса

```sql
-- Селективность = Уникальные значения / Всего строк

-- Высокая селективность (> 0.3) — хороший кандидат
SELECT 
    COUNT(DISTINCT username) * 1.0 / COUNT(*) AS selectivity
FROM players;
-- Результат: 0.95 (отлично!)

-- Низкая селективность (< 0.1) — плохой кандидат
SELECT 
    COUNT(DISTINCT status) * 1.0 / COUNT(*) AS selectivity
FROM game_sessions;
-- Результат: 0.003 (плохо!)
```

### Мониторинг использования индексов

```sql
-- Статистика использования индексов
SELECT 
    OBJECT_NAME(object_id) AS table_name,
    index_id,
    user_seeks,
    user_scans,
    user_lookups,
    user_updates,
    (user_seeks + user_scans + user_lookups) AS total_reads,
    user_updates AS total_writes
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID('quiz_db')
ORDER BY total_reads DESC;

-- Для MySQL/MariaDB
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    ROUND(STAT_VALUE * @@innodb_page_size / 1024 / 1024, 2) AS size_mb
FROM mysql.innodb_index_stats
WHERE database_name = 'quiz_db'
  AND stat_name = 'size'
ORDER BY size_mb DESC;
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

### Рекомендации по размеру

| Таблица | Рекомендуемый размер индекса |
|---------|------------------------------|
| < 1 GB | 10-20% от размера данных |
| 1-10 GB | 20-30% от размера данных |
| 10-100 GB | 30-50% от размера данных |
| > 100 GB | Индивидуальный расчёт |

### Проверка перед созданием

```sql
-- 1. Проверить существующие индексы
SHOW INDEX FROM players;

-- 2. Проверить селективность
SELECT COUNT(DISTINCT column) * 1.0 / COUNT(*) FROM table;

-- 3. Проанализировать запросы
EXPLAIN SELECT ...;

-- 4. Оценить размер
-- Размер ключа × Количество строк × 1.2

-- 5. Создать индекс
CREATE INDEX idx_name ON table(column);

-- 6. Проверить улучшение
EXPLAIN SELECT ...;
```

---

## Заключение

### Ключевые моменты

1. **Индексы ускоряют SELECT, замедляют INSERT/UPDATE/DELETE**
2. **Размер индекса = 10-50% от размера данных**
3. **Используйте EXPLAIN для анализа запросов**
4. **Создавайте индексы только для селективных столбцов**
5. **Регулярно обслуживайте индексы (ANALYZE, OPTIMIZE)**

### Формулы

```
Размер B-Tree индекса:
  Размер_ключа × Количество_строк × 1.2

Селективность:
  COUNT(DISTINCT column) / COUNT(*)

Эффективность:
  (Время_без_индекса - Время_с_индексом) / Время_без_индекса × 100%
```

### Полезные команды

```sql
-- Создать индекс
CREATE INDEX idx_name ON table(column);

-- Проверить использование
EXPLAIN SELECT ...;

-- Удалить индекс
DROP INDEX idx_name ON table;

-- Обновить статистику
ANALYZE TABLE table;

-- Оптимизировать таблицу
OPTIMIZE TABLE table;
```
