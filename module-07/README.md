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
    questions WRITE,
    game_sessions WRITE,
    session_answers WRITE;

-- Проверка доступности вопроса
SELECT COUNT(*) FROM game_sessions
WHERE question_id = 1 AND status = 'in_progress';

-- Создание игровой сессии
INSERT INTO game_sessions (player_id, category_id, started_at) VALUES (5, 1, CURDATE());

-- Обновление статуса
UPDATE game_sessions SET status = 'in_progress' WHERE id = 10;

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
SELECT GET_LOCK('question_1_lock', 10) AS lock_acquired;

-- Если блокировка получена (1)
IF lock_acquired = 1 THEN
    -- Критическая секция
    UPDATE questions SET view_count = view_count + 1 WHERE id = 1;

    -- Освобождение блокировки
    SELECT RELEASE_LOCK('question_1_lock');

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

**Синтаксис управления транзакциями:**
```sql
-- Начало транзакции
START TRANSACTION;
-- или
BEGIN;
-- или
BEGIN WORK;

-- Фиксация изменений
COMMIT;
-- или
COMMIT WORK;

-- Откат изменений
ROLLBACK;
-- или
ROLLBACK WORK;

-- Точка сохранения
SAVEPOINT savepoint_name;

-- Откат к точке сохранения
ROLLBACK TO [SAVEPOINT] savepoint_name;

-- Удаление точки сохранения
RELEASE [SAVEPOINT] savepoint_name;

-- Управление автофиксацией
SET AUTOCOMMIT = 0;  -- Отключить (требует явного COMMIT)
SET AUTOCOMMIT = 1;  -- Включить (по умолчанию)

-- Уровень изоляции для сессии
SET [SESSION] TRANSACTION ISOLATION LEVEL
    READ UNCOMMITTED |
    READ COMMITTED |
    REPEATABLE READ |
    SERIALIZABLE;

-- Уровень изоляции для следующей транзакции
SET TRANSACTION ISOLATION LEVEL level;
```

**Параметры:**
- `START TRANSACTION` — начать новую транзакцию
- `COMMIT` — зафиксировать все изменения
- `ROLLBACK` — отменить все изменения
- `SAVEPOINT` — создать точку для частичного отката
- `AUTOCOMMIT` — автоматическая фиксация каждой операции
- `ISOLATION LEVEL` — уровень изоляции транзакции

**Уровни изоляции:**
- `READ UNCOMMITTED` — грязное чтение (самый быстрый, наименее безопасный)
- `READ COMMITTED` — чтение зафиксированных данных (Oracle, SQL Server default)
- `REPEATABLE READ` — повторяемое чтение (MySQL/MariaDB default)
- `SERIALIZABLE` — сериализуемость (самый медленный, наиболее безопасный)

**Важно:**
- DDL-операторы (CREATE, ALTER, DROP) автоматически фиксируют транзакцию
- DML-операторы (INSERT, UPDATE, DELETE) требуют явного COMMIT
- При ошибке в транзакции выполните ROLLBACK

### Пример транзакции

```sql
START TRANSACTION;

-- Перевод вопроса в другую категорию
UPDATE questions
SET category_id = 2, status = 'review'
WHERE id = 10;

-- Логирование перемещения
INSERT INTO question_move_log (question_id, from_category, to_category, moved_at)
VALUES (10, 1, 2, NOW());

-- Проверка перед фиксацией
SELECT * FROM questions WHERE id = 10;

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
INSERT INTO players (username, email, total_score)
VALUES ('ivan_gamer', 'ivan@test.com', 0);

-- Точка сохранения
SAVEPOINT after_player_insert;

-- Вторая операция
INSERT INTO game_sessions (player_id, category_id, started_at)
VALUES (LAST_INSERT_ID(), 5, CURDATE());

-- Если ошибка - откат к точке
ROLLBACK TO SAVEPOINT after_player_insert;

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

CREATE PROCEDURE complex_question_transfer(
    IN p_question_id INT,
    IN p_from_category INT,
    IN p_to_category INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SAVEPOINT before_update;

    -- Обновление вопроса
    UPDATE questions
    SET category_id = p_to_category,
        status = 'pending_review'
    WHERE id = p_question_id AND category_id = p_from_category;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK TO SAVEPOINT before_update;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Question not found or already moved';
    END IF;

    SAVEPOINT after_question_update;

    -- Логирование
    INSERT INTO transfer_log (question_id, from_category, to_category, transferred_at)
    VALUES (p_question_id, p_from_category, p_to_category, NOW());

    -- Обновление статистики категорий
    UPDATE category_stats
    SET question_count = question_count - 1
    WHERE category_id = p_from_category;

    UPDATE category_stats
    SET question_count = question_count + 1
    WHERE category_id = p_to_category;

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
