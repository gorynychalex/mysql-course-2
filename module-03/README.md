# Модуль 3. Синтаксис выражений SQL для определения структуры данных (DDL)

**Продолжительность:** 4 академических часа

## Содержание модуля

1. DDL-операторы
2. Операторы создания базы
3. Создание таблиц
4. Временные таблицы
5. Индексы
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
CREATE TABLE table_name (
    column1_name datatype [constraints],
    column2_name datatype [constraints],
    ...
    table_constraints
) ENGINE=storage_engine DEFAULT CHARSET=charset;
```

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

-- Составной индекс
CREATE INDEX idx_player_stats ON players(username, total_score);
```

### Просмотр индексов

```sql
-- Показать индексы таблицы
SHOW INDEX FROM players;

-- Альтернатива
SHOW INDEXES FROM players;
SHOW KEYS FROM players;
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

### Когда создавать индексы

✅ **Создавать индекс:**
- Поля в WHERE
- Поля в JOIN
- Поля в ORDER BY
- Поля в GROUP BY
- Внешние ключи

❌ **Не создавать индекс:**
- Таблицы с частыми INSERT/UPDATE/DELETE
- Поля с низкой селективностью (пол, статус)
- Маленькие таблицы

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
