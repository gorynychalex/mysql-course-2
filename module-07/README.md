# Модуль 7. Транзакции и типы хранилищ MySQL

**Продолжительность:** 4 академических часа

## Содержание модуля

1. Блокировка таблиц
2. Условная блокировка
3. Транзакции
4. Точки сохранения
5. Типы хранилищ

---

## 1. Блокировка таблиц

### LOCK TABLES

```sql
-- Блокировка таблиц
LOCK TABLES 
    table1 READ,
    table2 WRITE,
    table3 READ LOCAL;

-- Разблокировка
UNLOCK TABLES;
```

### Типы блокировок

| Тип | Описание |
|-----|----------|
| **READ** | Только чтение, другие могут читать |
| **READ LOCAL** | Чтение с возможностью вставки |
| **WRITE** | Эксклюзивная блокировка |
| **LOW_PRIORITY WRITE** | Запись с низким приоритетом |

### Пример использования

```sql
-- Атомарное обновление нескольких таблиц
LOCK TABLES 
    books WRITE,
    book_copies WRITE,
    loans WRITE;

-- Проверка доступности
SELECT COUNT(*) FROM book_copies 
WHERE book_id = 1 AND status = 'available';

-- Создание выдачи
INSERT INTO loans (book_id, reader_id, loan_date) VALUES (1, 5, CURDATE());

-- Обновление статуса
UPDATE book_copies SET status = 'borrowed' WHERE id = 10;

UNLOCK TABLES;
```

---

## 2. Условная блокировка (GET_LOCK)

### Функции блокировок

```sql
-- Получение именованной блокировки
SELECT GET_LOCK('lock_name', timeout);

-- Освобождение блокировки
SELECT RELEASE_LOCK('lock_name');

-- Освобождение всех блокировок сессии
SELECT RELEASE_ALL_LOCKS();

-- Проверка блокировки
SELECT IS_USED_LOCK('lock_name');
SELECT IS_FREE_LOCK('lock_name');
```

### Пример использования

```sql
-- Блокировка для предотвращения гонки
START TRANSACTION;

-- Попытка получить блокировку
SELECT GET_LOCK('book_1_lock', 10) AS lock_acquired;

-- Если блокировка получена (1)
IF lock_acquired = 1 THEN
    -- Критическая секция
    UPDATE books SET view_count = view_count + 1 WHERE id = 1;
    
    -- Освобождение блокировки
    SELECT RELEASE_LOCK('book_1_lock');
    
    COMMIT;
ELSE
    -- Блокировка не получена
    ROLLBACK;
END IF;
```

---

## 3. Транзакции

### Что такое транзакция?

**Транзакция** — последовательность операций, выполняемая как единое целое.

### ACID свойства

| Свойство | Описание |
|----------|----------|
| **A**tomicity | Атомарность — всё или ничего |
| **C**onsistency | Согласованность — данные валидны |
| **I**solation | Изолированность — параллельные транзакции не мешают |
| **D**urability | Долговечность — после COMMIT изменения постоянны |

### Управление транзакциями

```sql
-- Начало транзакции
START TRANSACTION;
-- или
BEGIN;

-- Фиксация изменений
COMMIT;

-- Откат изменений
ROLLBACK;

-- Автофиксация (по умолчанию ON)
SET AUTOCOMMIT = 0; -- Отключить
SET AUTOCOMMIT = 1; -- Включить
```

### Пример транзакции

```sql
START TRANSACTION;

-- Перевод книги в другой фонд
UPDATE book_copies 
SET location = 'B2', status = 'available'
WHERE id = 10;

-- Логирование перемещения
INSERT INTO movement_log (copy_id, from_location, to_location, moved_at)
VALUES (10, 'A1', 'B2', NOW());

-- Проверка перед фиксацией
SELECT * FROM book_copies WHERE id = 10;

-- Если всё правильно
COMMIT;

-- Если ошибка
-- ROLLBACK;
```

### Уровни изоляции

```sql
-- Просмотр текущего уровня
SELECT @@transaction_isolation;

-- Установка уровня изоляции
SET TRANSACTION ISOLATION LEVEL 
    READ UNCOMMITTED | 
    READ COMMITTED | 
    REPEATABLE READ | 
    SERIALIZABLE;
```

| Уровень | Проблемы |
|---------|----------|
| **READ UNCOMMITTED** | Грязное чтение, неповторяемое чтение, фантомы |
| **READ COMMITTED** | Неповторяемое чтение, фантомы |
| **REPEATABLE READ** (MySQL default) | Фантомы |
| **SERIALIZABLE** | Нет проблем, но медленно |

---

## 4. Точки сохранения (SAVEPOINT)

### Использование SAVEPOINT

```sql
START TRANSACTION;

-- Первая операция
INSERT INTO readers (first_name, last_name, email) 
VALUES ('Иван', 'Петров', 'ivan@test.com');

-- Точка сохранения
SAVEPOINT after_reader_insert;

-- Вторая операция
INSERT INTO loans (reader_id, book_id, loan_date) 
VALUES (LAST_INSERT_ID(), 5, CURDATE());

-- Если ошибка - откат к точке
ROLLBACK TO SAVEPOINT after_reader_insert;

-- Или фиксация всего
COMMIT;
```

### Управление точками сохранения

```sql
-- Создание точки
SAVEPOINT point_name;

-- Откат к точке
ROLLBACK TO SAVEPOINT point_name;

-- Удаление точки
RELEASE SAVEPOINT point_name;
```

### Пример сложной транзакции

```sql
DELIMITER //

CREATE PROCEDURE complex_book_transfer(
    IN p_copy_id INT,
    IN p_from_branch INT,
    IN p_to_branch INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    SAVEPOINT before_update;
    
    -- Обновление копии
    UPDATE book_copies 
    SET location = p_to_branch,
        status = 'in_transit'
    WHERE id = p_copy_id AND location = p_from_branch;
    
    IF ROW_COUNT() = 0 THEN
        ROLLBACK TO SAVEPOINT before_update;
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Copy not found or already moved';
    END IF;
    
    SAVEPOINT after_copy_update;
    
    -- Логирование
    INSERT INTO transfer_log (copy_id, from_branch, to_branch, transferred_at)
    VALUES (p_copy_id, p_from_branch, p_to_branch, NOW());
    
    -- Обновление статистики филиалов
    UPDATE branch_stats 
    SET book_count = book_count - 1 
    WHERE branch_id = p_from_branch;
    
    UPDATE branch_stats 
    SET book_count = book_count + 1 
    WHERE branch_id = p_to_branch;
    
    COMMIT;
END//

DELIMITER ;
```

---

## 5. Типы хранилищ (Storage Engines)

### Основные движки

| Движок | Транзакции | FK | Блокировки | Применение |
|--------|------------|----|------------|------------|
| **InnoDB** | Да | Да | Строковые | По умолчанию |
| **MyISAM** | Нет | Нет | Табличные | Чтение, устарел |
| **MEMORY** | Нет | Нет | Табличные | Временные данные |
| **ARCHIVE** | Нет | Нет | Табличные | Архивирование |
| **CSV** | Нет | Нет | - | Импорт/экспорт |

### Проверка движка

```sql
-- Движок по умолчанию
SELECT @@default_storage_engine;

-- Движки таблиц
SELECT TABLE_NAME, ENGINE 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'database_name';

-- Информация о движках
SHOW ENGINES;
```

### Выбор движка

```sql
-- При создании таблицы
CREATE TABLE table_name (...) ENGINE=InnoDB;
CREATE TABLE table_name (...) ENGINE=MyISAM;
CREATE TABLE table_name (...) ENGINE=MEMORY;

-- Изменение движка
ALTER TABLE table_name ENGINE=InnoDB;
```

### Сравнение InnoDB и MyISAM

```sql
-- InnoDB (рекомендуется)
CREATE TABLE innodb_table (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data VARCHAR(100)
) ENGINE=InnoDB;
-- + Транзакции
-- + Внешние ключи
-- + Блокировка строк
-- + Восстановление после сбоя
-- - Больше места на диске

-- MyISAM (не рекомендуется для новых проектов)
CREATE TABLE myisam_table (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data VARCHAR(100)
) ENGINE=MyISAM;
-- + Быстрее для SELECT
-- + Меньше места
-- + COUNT(*) быстрее
-- - Нет транзакций
-- - Нет FK
-- - Блокировка таблиц
```

### Оптимизация для InnoDB

```sql
-- Размер буфера
SET GLOBAL innodb_buffer_pool_size = 1073741824; -- 1GB

-- Размер лога
SET GLOBAL innodb_log_file_size = 256M;

-- Флеш лог при COMMIT
SET GLOBAL innodb_flush_log_at_trx_commit = 1; -- 0, 1, или 2

-- Проверка настроек
SHOW VARIABLES LIKE 'innodb%';
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
