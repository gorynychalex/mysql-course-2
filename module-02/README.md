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

```sql
-- Возраст человека (0-150)
age TINYINT UNSIGNED

-- Количество книг на складе
quantity INT UNSIGNED

-- Цена книги (точно до копеек)
price DECIMAL(10,2)

-- Рейтинг (0.0 - 5.0)
rating DECIMAL(3,1)
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

```sql
-- ISBN книги (фиксированная длина)
isbn CHAR(13)

-- Название книги (переменная длина)
title VARCHAR(255)

-- Описание книги (текст)
description TEXT

-- Статус книги (перечисление)
status ENUM('available', 'borrowed', 'reserved', 'lost')

-- Языки книги (множество)
languages SET('ru', 'en', 'de', 'fr', 'es')
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

```sql
-- Дата рождения читателя
birth_date DATE

-- Время выдачи книги
issue_time TIME

-- Дата и время создания записи
created_at DATETIME

-- Время последнего обновления (авто)
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

-- Год издания книги
publication_year YEAR
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

Column Name: title
Datatype: VARCHAR(255)
Not Null: ✓

Column Name: price
Datatype: DECIMAL(10,2)
Default Value: 0.00
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

| id | author | books |
|----|--------|-------|
| 1 | Иванов | "Книга 1, Книга 2, Книга 3" |

**Исправление (1NF):**

| id | author | book |
|----|--------|------|
| 1 | Иванов | "Книга 1" |
| 2 | Иванов | "Книга 2" |
| 3 | Иванов | "Книга 3" |

### Вторая нормальная форма (2NF)

**Требования:**
- Таблица в 1NF
- Все неключевые атрибуты зависят от всего первичного ключа

**Пример нарушения 2NF:**

| order_id | product_id | product_name | quantity |
|----------|------------|--------------|----------|
| 1 | 101 | "Книга А" | 2 |

`product_name` зависит только от `product_id`, а не от всего ключа.

**Исправление (2NF):**

```
Orders (order_id, product_id, quantity)
Products (product_id, product_name, price)
```

### Третья нормальная форма (3NF)

**Требования:**
- Таблица в 2NF
- Нет транзитивных зависимостей

**Пример нарушения 3NF:**

| book_id | title | author | author_country |
|---------|-------|--------|----------------|
| 1 | "Война и мир" | "Толстой" | "Россия" |

`author_country` зависит от `author`, а не от `book_id`.

**Исправление (3NF):**

```
Books (book_id, title, author_id)
Authors (author_id, author_name, author_country)
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
CREATE TABLE books (
    id INT PRIMARY KEY,
    title VARCHAR(255)
);

-- Или с AUTO_INCREMENT
CREATE TABLE books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255)
);

-- Составной первичный ключ
CREATE TABLE book_authors (
    book_id INT,
    author_id INT,
    PRIMARY KEY (book_id, author_id)
);
```

### Внешний ключ (FOREIGN KEY)

```sql
CREATE TABLE loans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    reader_id INT NOT NULL,
    loan_date DATE,
    return_date DATE,
    
    -- Внешние ключи
    FOREIGN KEY (book_id) REFERENCES books(id),
    FOREIGN KEY (reader_id) REFERENCES readers(id)
);

-- С указанием действий при удалении/обновлении
FOREIGN KEY (book_id) REFERENCES books(id)
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
CREATE TABLE readers (
    id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20) UNIQUE
);

-- Добавление после создания
ALTER TABLE readers ADD UNIQUE (email);
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
CREATE TABLE readers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50)
);

CREATE TABLE reader_passports (
    id INT PRIMARY KEY,
    passport_series VARCHAR(4),
    passport_number VARCHAR(6),
    issue_date DATE,
    
    -- Связь 1:1
    FOREIGN KEY (id) REFERENCES readers(id)
        ON DELETE CASCADE
);
```

### Реализация связи 1:M

```sql
CREATE TABLE authors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100)
);

CREATE TABLE books (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255),
    author_id INT,
    
    -- Связь 1:M (один автор — много книг)
    FOREIGN KEY (author_id) REFERENCES authors(id)
);
```

### Реализация связи M:N

```sql
-- Таблица связи (junction table)
CREATE TABLE book_loans (
    id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT NOT NULL,
    reader_id INT NOT NULL,
    loan_date DATE NOT NULL,
    due_date DATE,
    return_date DATE,
    
    FOREIGN KEY (book_id) REFERENCES books(id),
    FOREIGN KEY (reader_id) REFERENCES readers(id),
    
    -- Индексы для ускорения поиска
    INDEX idx_loan_dates (loan_date, return_date)
);
```

### Диаграмма связей для библиотеки

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   Authors   │ 1:M   │    Books    │ 1:M   │  Categories │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ id (PK)     │──────<│ id (PK)     │       │ id (PK)     │
│ name        │       │ title       │>------│ name        │
│ country     │       │ author_id   │       │ description │
└─────────────┘       │ category_id │       └─────────────┘
                      │ isbn        │
                      └──────┬──────┘
                             │
                      ┌──────▼──────┐       ┌─────────────┐
                      │  BookLoans  │ M:N   │   Readers   │
                      ├─────────────┤       ├─────────────┤
                      │ id (PK)     │>------│ id (PK)     │
                      │ book_id     │       │ first_name  │
                      │ reader_id   │<------│ last_name   │
                      │ loan_date   │       │ email       │
                      │ return_date │       │ phone       │
                      └─────────────┘       └─────────────┘
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
-- Schema library_db
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `library_db` ;

CREATE SCHEMA IF NOT EXISTS `library_db` 
    DEFAULT CHARACTER SET utf8mb4 ;
USE `library_db` ;

-- -----------------------------------------------------
-- Table `library_db`.`authors`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `library_db`.`authors` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `country` VARCHAR(50) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table `library_db`.`books`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `library_db`.`books` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `isbn` CHAR(13) NULL,
  `author_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_books_authors_idx` (`author_id` ASC),
  CONSTRAINT `fk_books_authors`
    FOREIGN KEY (`author_id`)
    REFERENCES `library_db`.`authors` (`id`)
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
