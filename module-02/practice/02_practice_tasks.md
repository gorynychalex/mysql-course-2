# Практические задания - Модуль 2

## Задание 1. Изучение типов данных

**Цель:** Понять различия между типами данных MySQL

### Часть А: Эксперименты с числовыми типами

```sql
-- Создайте таблицу для экспериментов
CREATE TABLE data_types_test (
    id INT PRIMARY KEY,
    tiny_int_col TINYINT,
    small_int_col SMALLINT,
    medium_int_col MEDIUMINT,
    int_col INT,
    big_int_col BIGINT,
    float_col FLOAT(10,2),
    double_col DOUBLE(10,2),
    decimal_col DECIMAL(10,2)
);

-- Вставьте предельные значения
INSERT INTO data_types_test VALUES (1, 127, 32767, 8388607, 2147483647, 9223372036854775807, 99999999.99, 99999999.99, 99999999.99);

-- Проверьте, что происходит при превышении диапазона
-- (попробуйте вставить значения больше максимальных)
```

### Часть Б: Строковые типы

```sql
-- Сравните CHAR и VARCHAR
CREATE TABLE string_test (
    char_col CHAR(50),
    varchar_col VARCHAR(50)
);

INSERT INTO string_test VALUES ('test', 'test');

-- Проверьте занимаемое место
SELECT 
    char_col, 
    varchar_col,
    LENGTH(char_col) AS char_length,
    LENGTH(varchar_col) AS varchar_length
FROM string_test;
```

### Отчет:
- Скриншоты результатов
- Выводы о различиях типов

---

## Задание 2. Проектирование схемы в Workbench

**Цель:** Научиться создавать ER-диаграммы

### Задание:

1. Откройте MySQL Workbench
2. Создайте новую модель (File → New Model)
3. Добавьте диаграмму (Add Diagram)
4. Создайте таблицы для викторины:
   - `categories` (категории вопросов)
   - `questions` (вопросы)
   - `answers` (варианты ответов)
   - `players` (игроки)
   - `game_sessions` (игровые сессии)

5. Настройте связи между таблицами:
   - categories → questions (1:M)
   - questions → answers (1:M)
   - players → game_sessions (1:M)
   - game_sessions → questions (M:N через session_answers)

6. Сохраните модель как `quiz_model.mwb`

### Отчет:
- Файл .mwb
- Экспорт диаграммы в PNG

---

## Задание 3. Нормализация

**Цель:** Научиться применять нормальные формы

### Дана денормализованная таблица:

```
Orders (order_id, customer_name, customer_email, product_name, product_category, quantity, price, supplier_name, supplier_phone)
```

### Задание:

1. Определите нарушения нормальных форм
2. Разбейте на нормализованные таблицы (до 3NF)
3. Создайте SQL-скрипт с новой структурой
4. Нарисуйте ER-диаграмму

### Ожидаемая структура:

```
Customers (customer_id, name, email)
Products (product_id, name, category_id, price, supplier_id)
Categories (category_id, name)
Suppliers (supplier_id, name, phone)
Orders (order_id, customer_id, order_date)
OrderItems (order_item_id, order_id, product_id, quantity)
```

---

## Задание 4. Создание ключей и связей

**Цель:** Отработать создание различных типов ключей

### Задание:

Создайте таблицу `library_loans` с ключами:

```sql
-- Требования:
-- 1. Первичный ключ: id (AUTO_INCREMENT)
-- 2. Внешние ключи: book_id, reader_id
-- 3. Уникальный ключ: (book_id, loan_date) - книга не может быть выдана дважды в один день
-- 4. Индексы: на reader_id, на loan_date

-- Действия при удалении:
-- При удалении читателя: SET NULL в loan.reader_id
-- При удалении книги: RESTRICT (нельзя удалить книгу, которая на руках)
```

---

## Задание 5. Экспорт из Workbench

**Цель:** Научиться экспортировать модель в SQL

### Задание:

1. Откройте созданную в Задании 2 модель
2. Выполните Forward Engineer (Database → Forward Engineer)
3. Настройте опции:
   - Generate DROP Statements
   - Generate CREATE Statements
   - Generate INSERT Statements (для тестовых данных)
4. Сохраните SQL-скрипт
5. Выполните скрипт на сервере
6. Проверьте создание объектов

### Отчет:
- SQL-файл экспорта
- Скриншот успешного выполнения

---

## Критерии оценки

| Критерий | Баллы |
|----------|-------|
| Задание 1: Типы данных | 5 |
| Задание 2: ER-диаграмма | 10 |
| Задание 3: Нормализация | 10 |
| Задание 4: Ключи и связи | 5 |
| Задание 5: Экспорт | 5 |
| Оформление | 5 |
| **ИТОГО** | **40** |
