# Модуль 2. Проектирование реляционной базы данных

**Продолжительность:** 4 академических часа

## Содержание модуля

1. Типы данных
2. Проектирование схемы базы в WorkBench
3. Нормализация таблицы базы
4. Создание ключей
5. Связи между таблицами
6. Работа с файлами .mwb
7. Экспорт SQL-кода из схемы базы

---

## 1. Типы данных MySQL

### Числовые типы данных

| Тип | Размер | Диапазон | Описание |
|-----|--------|----------|----------|
| **TINYINT** | 1 байт | -128 до 127 | Очень маленькие целые числа |
| **SMALLINT** | 2 байта | -32768 до 32767 | Малые целые числа |
| **MEDIUMINT** | 3 байта | -8388608 до 8388607 | Средние целые числа |
| **INT/INTEGER** | 4 байта | -2³¹ до 2³¹-1 | Целые числа |
| **BIGINT** | 8 байт | -2⁶³ до 2⁶³-1 | Большие целые числа |
| **FLOAT** | 4 байта | ~7 знаков | Числа с плавающей точкой |
| **DOUBLE** | 8 байт | ~15 знаков | Числа с двойной точностью |
| **DECIMAL(M,D)** | Зависит | Точное значение | Точные десятичные числа |

### Примеры использования:

**Синтаксис объявления числовых столбцов:**
```sql
column_name DATA_TYPE [UNSIGNED] [DEFAULT значение] [NOT NULL] [COMMENT 'описание']
```

**Параметры:**
- `UNSIGNED` — только неотрицательные значения (диапазон с 0)
- `DEFAULT` — значение по умолчанию при вставке
- `NOT NULL` — запрет NULL значений
- `COMMENT` — описание столбца

```sql
-- Количество очков за вопрос (1-100)
points TINYINT UNSIGNED

-- Количество вопросов в категории
question_count INT UNSIGNED

-- Сложность вопроса (1.0 - 10.0)
difficulty DECIMAL(3,1)

-- Общий счет игрока (точно до единиц)
total_score DECIMAL(10,2)
```

### Строковые типы данных

| Тип | Описание | Макс. размер |
|-----|----------|--------------|
| **CHAR(N)** | Фиксированная длина | 255 символов |
| **VARCHAR(N)** | Переменная длина | 65535 байт |
| **TINYTEXT** | Короткий текст | 255 байт |
| **TEXT** | Текст | 65535 байт |
| **MEDIUMTEXT** | Средний текст | 16 МБ |
| **LONGTEXT** | Длинный текст | 4 ГБ |
| **ENUM** | Перечисление | 65535 значений |
| **SET** | Множество | 64 элемента |

### Примеры использования:

**Синтаксис объявления строковых столбцов:**
```sql
column_name VARCHAR(N) [CHARACTER SET charset] [COLLATE collation] [DEFAULT 'значение'] [NOT NULL]
```

**Параметры:**
- `VARCHAR(N)` — строка переменной длины, N — максимальная длина
- `CHAR(N)` — строка фиксированной длины
- `TEXT` — текстовое поле (не требует указания длины)
- `ENUM('val1','val2')` — перечисление, можно выбрать только одно значение
- `SET('val1','val2')` — множество, можно выбрать несколько значений
- `CHARACTER SET` — кодировка (обычно utf8mb4)
- `COLLATE` — правила сравнения (обычно utf8mb4_unicode_ci)

```sql
-- Слаг категории (фиксированная длина)
slug CHAR(50)

-- Название вопроса (переменная длина)
question_text VARCHAR(500)

-- Описание категории (текст)
description TEXT

-- Статус вопроса (перечисление)
status ENUM('active', 'inactive', 'draft', 'archived')

-- Типы вопросов (множество)
question_types SET('single_choice', 'multiple_choice', 'true_false', 'text_input')
```

### Типы данных для даты и времени

| Тип | Формат | Диапазон | Размер |
|-----|--------|----------|--------|
| **DATE** | YYYY-MM-DD | 1000-01-01 до 9999-12-31 | 3 байта |
| **TIME** | HH:MM:SS | -838:59:59 до 838:59:59 | 3 байта |
| **DATETIME** | YYYY-MM-DD HH:MM:SS | 1000-01-01 00:00:00 до 9999-12-31 23:59:59 | 8 байт |
| **TIMESTAMP** | YYYY-MM-DD HH:MM:SS | 1970-01-01 00:00:01 до 2038-01-19 03:14:07 | 4 байта |
| **YEAR** | YYYY | 1901 до 2155 | 1 байт |

### Примеры использования:

**Синтаксис объявления столбцов даты и времени:**
```sql
column_name DATE|TIME|DATETIME|TIMESTAMP|YEAR [DEFAULT CURRENT_TIMESTAMP] [ON UPDATE CURRENT_TIMESTAMP] [NOT NULL]
```

**Параметры:**
- `DATE` — только дата (YYYY-MM-DD)
- `TIME` — только время (HH:MM:SS)
- `DATETIME` — дата и время (без привязки к часовому поясу)
- `TIMESTAMP` — дата и время (с привязкой к UTC, автоматическое обновление)
- `YEAR` — только год (YYYY)
- `DEFAULT CURRENT_TIMESTAMP` — установить текущую дату/время при создании
- `ON UPDATE CURRENT_TIMESTAMP` — обновлять при изменении записи
- `NOT NULL` — запрет NULL значений

```sql
-- Дата рождения игрока
birth_date DATE

-- Время начала игровой сессии
start_time TIME

-- Дата и время создания вопроса
created_at DATETIME

-- Время последнего обновления счета (авто)
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

-- Год создания категории
created_year YEAR
```

### Типы данных для бинарных данных

| Тип | Описание |
|-----|----------|
| **BLOB** | Binary Large Object |
| **TINYBLOB** | Малый бинарный объект |
| **MEDIUMBLOB** | Средний бинарный объект |
| **LONGBLOB** | Большой бинарный объект |
| **BIT** | Битовое поле |
| **BINARY** | Фиксированные бинарные данные |
| **VARBINARY** | Переменные бинарные данные |

---

## 2. Проектирование схемы базы в MySQL Workbench

### Создание новой модели

1. **File → New Model** (Ctrl+N)
2. **Add Diagram** → Добавить диаграмму
3. **File → Save Model** → Сохранить как .mwb файл

### Добавление таблиц

1. Используйте инструмент **Table** на панели
2. Кликните на области диаграммы
3. Заполните свойства таблицы:
   - Имя таблицы
   - Столбцы и типы данных
   - Первичные ключи
   - Индексы

### Настройка столбцов

| Вкладка | Описание |
|---------|----------|
| **Columns** | Определение столбцов |
| **Advanced** | Дополнительные параметры |
| **Triggers** | Триггеры таблицы |
| **Partitions** | Секционирование |

### Пример настройки столбца:

```
Column Name: id
Datatype: INT
Not Null: ✓
PK: ✓
Auto Increment: ✓

Column Name: question_text
Datatype: VARCHAR(500)
Not Null: ✓

Column Name: points
Datatype: DECIMAL(10,2)
Default Value: 1.00
```

---

## 3. Нормализация базы данных

### Что такое нормализация?

**Нормализация** — процесс организации данных в базе данных для уменьшения избыточности и улучшения целостности данных.

### Первая нормальная форма (1NF)

**Требования:**
- Все атрибуты атомарны (неделимы)
- Нет повторяющихся групп
- Каждая строка уникальна

**Пример нарушения 1NF:**

| id | player | categories_played |
|----|--------|---------------------|
| 1 | Иванов | "История, Наука, Спорт" |

**Исправление (1NF):**

| id | player | category |
|----|--------|----------|
| 1 | Иванов | "История" |
| 2 | Иванов | "Наука" |
| 3 | Иванов | "Спорт" |

### Вторая нормальная форма (2NF)

**Требования:**
- Таблица в 1NF
- Все неключевые атрибуты зависят от всего первичного ключа

**Пример нарушения 2NF:**

| session_id | question_id | question_text | selected_answer |
|------------|-------------|---------------|-----------------|
| 1 | 101 | "Вопрос А" | "Ответ 1" |

`question_text` зависит только от `question_id`, а не от всего ключа.

**Исправление (2NF):**

```
SessionAnswers (session_id, question_id, selected_answer)
Questions (question_id, question_text, category_id)
```

### Третья нормальная форма (3NF)

**Требования:**
- Таблица в 2NF
- Нет транзитивных зависимостей

**Пример нарушения 3NF:**

| question_id | question_text | category_id | category_name |
|-------------|---------------|-------------|---------------|
| 1 | "Вопрос?" | 10 | "История" |

`category_name` зависит от `category_id`, а не от `question_id`.

**Исправление (3NF):**

```
Questions (question_id, question_text, category_id)
Categories (category_id, category_name, slug)
```

### Нормальные формы высших порядков

| Форма | Описание |
|-------|----------|
| **BCNF** | Бойса-Кодда — усиленная 3NF |
| **4NF** | Устраняет многозначные зависимости |
| **5NF** | Устраняет зависимости соединения |

---

## 4. Создание ключей

### Типы ключей

| Тип | Описание |
|-----|----------|
| **PRIMARY KEY** | Первичный ключ — уникально идентифицирует строку |
| **FOREIGN KEY** | Внешний ключ — ссылается на PRIMARY KEY другой таблицы |
| **UNIQUE KEY** | Уникальный ключ — все значения уникальны |
| **INDEX** | Индекс — ускоряет поиск |

### Первичный ключ (PRIMARY KEY)

```sql
-- При создании таблицы
CREATE TABLE categories (
    id INT PRIMARY KEY,
    name VARCHAR(100)
);

-- Или с AUTO_INCREMENT
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
);

-- Составной первичный ключ
CREATE TABLE session_answers (
    session_id INT,
    question_id INT,
    PRIMARY KEY (session_id, question_id)
);
```

### Внешний ключ (FOREIGN KEY)

```sql
CREATE TABLE game_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT NOT NULL,
    category_id INT NOT NULL,
    score INT,
    status VARCHAR(20),

    -- Внешние ключи
    FOREIGN KEY (player_id) REFERENCES players(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- С указанием действий при удалении/обновлении
FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
```

### Опции FOREIGN KEY

| Опция | Описание |
|-------|----------|
| **ON DELETE CASCADE** | Удалить дочерние записи при удалении родительской |
| **ON DELETE SET NULL** | Установить NULL в дочерних записях |
| **ON DELETE RESTRICT** | Запретить удаление родительской записи |
| **ON UPDATE CASCADE** | Обновить дочерние записи при обновлении родительской |

### Уникальный ключ (UNIQUE KEY)

```sql
-- При создании таблицы
CREATE TABLE players (
    id INT PRIMARY KEY,
    username VARCHAR(100) UNIQUE,
    email VARCHAR(100) UNIQUE
);

-- Добавление после создания
ALTER TABLE players ADD UNIQUE (email);
```

---

## 5. Связи между таблицами

### Типы связей

| Тип | Описание | Пример |
|-----|----------|--------|
| **1:1 (One-to-One)** | Одна запись ↔ Одна запись | Читатель ↔ Паспорт |
| **1:M (One-to-Many)** | Одна запись ↔ Много записей | Автор ↔ Книги |
| **M:N (Many-to-Many)** | Много записей ↔ Много записей | Книги ↔ Читатели |

### Реализация связи 1:1

```sql
CREATE TABLE players (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50),
    email VARCHAR(100)
);

CREATE TABLE player_profiles (
    id INT PRIMARY KEY,
    avatar_url VARCHAR(255),
    bio TEXT,
    created_at DATETIME,

    -- Связь 1:1
    FOREIGN KEY (id) REFERENCES players(id)
        ON DELETE CASCADE
);
```

### Реализация связи 1:M

```sql
CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100)
);

CREATE TABLE questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_text VARCHAR(500),
    category_id INT,

    -- Связь 1:M (одна категория — много вопросов)
    FOREIGN KEY (category_id) REFERENCES categories(id)
);
```

### Реализация связи M:N

```sql
-- Таблица связи (junction table)
CREATE TABLE session_answers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    session_id INT NOT NULL,
    question_id INT NOT NULL,
    selected_answer_id INT,
    is_correct BOOLEAN,

    FOREIGN KEY (session_id) REFERENCES game_sessions(id),
    FOREIGN KEY (question_id) REFERENCES questions(id),

    -- Индексы для ускорения поиска
    INDEX idx_session_questions (session_id, question_id)
);
```

### Диаграмма связей для викторины

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│  Categories │ 1:M   │  Questions  │ 1:M   │   Answers   │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ id (PK)     │──────<│ id (PK)     │       │ id (PK)     │
│ name        │       │ question    │>------│ answer_text │
│ slug        │       │ category_id │       │ is_correct  │
│ description │       │ difficulty  │       │ question_id │
└─────────────┘       │ points      │       └─────────────┘
                      │ status      │
                      └──────┬──────┘
                             │
                      ┌──────▼──────┐       ┌─────────────┐
                      │SessionAnswers│ M:N  │ GameSessions│
                      ├─────────────┤       ├─────────────┤
                      │ id (PK)     │>------│ id (PK)     │
                      │ session_id  │       │ player_id   │<──────│   Players   │
                      │ question_id │       │ category_id │       ├─────────────┤
                      │ is_correct  │       │ score       │       │ id (PK)     │
                      └─────────────┘       │ status      │       │ username    │
                                            └─────────────┘       │ email       │
                                                                  │ total_score │
                                                                  └─────────────┘
```

---

## 6. Работа с файлами .mwb

### Что такое .mwb файл?

**.mwb** (MySQL Workbench Model) — файл модели данных MySQL Workbench, содержащий:
- Диаграммы ERD
- Определения таблиц
- Связи между таблицами
- Настройки подключения

### Открытие файла .mwb

1. **File → Open Model** (Ctrl+O)
2. Выберите файл .mwb
3. Модель откроется в панели **MySQL Models**

### Сохранение модели

1. **File → Save Model** (Ctrl+S)
2. Выберите расположение файла
3. Рекомендуется хранить в системе контроля версий (Git)

### Экспорт модели

| Формат | Описание |
|--------|----------|
| **SQL** | SQL-скрипт создания БД |
| **PNG/PDF/SVG** | Изображение диаграммы |
| **XML** | XML-представление модели |

---

## 7. Экспорт SQL-кода из схемы базы

### Экспорт через Workbench

1. **Database → Forward Engineer** (Ctrl+G)
2. Выберите подключение к серверу
3. Настройте опции экспорта:
   - Generate DROP Statements
   - Generate CREATE Statements
   - Generate INSERT Statements
4. Review SQL Script
5. Execute или Save to File

### Опции экспорта

```
☑ Generate DROP □ DROP DATABASE
☑ Generate CREATE □ CREATE DATABASE
☑ Add CREATE USE DATABASE
☑ Generate INSERT Statements
  ○ INSERT IGNORE
  ○ REPLACE
  ○ UPDATE
☑ Generate CREATE INDEX
☑ Generate FULLTEXT INDEX
```

### Пример экспортированного SQL

```sql
-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS;
SET UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE;
SET SQL_MODE='NO_AUTO_VALUE_ON_ZERO';

-- -----------------------------------------------------
-- Schema quiz_db
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `quiz_db` ;

CREATE SCHEMA IF NOT EXISTS `quiz_db`
    DEFAULT CHARACTER SET utf8mb4 ;
USE `quiz_db` ;

-- -----------------------------------------------------
-- Table `quiz_db`.`categories`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `quiz_db`.`categories` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `slug` VARCHAR(50) NOT NULL,
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table `quiz_db`.`questions`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `quiz_db`.`questions` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `category_id` INT NOT NULL,
  `question_text` VARCHAR(500) NOT NULL,
  `difficulty` DECIMAL(3,1) DEFAULT 1.0,
  `points` INT UNSIGNED DEFAULT 1,
  `status` ENUM('active', 'inactive', 'draft') DEFAULT 'active',
  PRIMARY KEY (`id`),
  INDEX `fk_questions_categories_idx` (`category_id` ASC),
  CONSTRAINT `fk_questions_categories`
    FOREIGN KEY (`category_id`)
    REFERENCES `quiz_db`.`categories` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS=1;
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
