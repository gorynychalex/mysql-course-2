# Модуль 7. Транзакции и типы хранилищ MySQL

**Продолжительность:** 4 академических часа

## Содержание модуля

1. Блокировка таблиц
2. Условная блокировка
3. Транзакции и ACID
   - Свойства ACID
   - Уровни изоляции
   - Проблемы параллелизма
4. Точки сохранения
5. Типы хранилищ
6. Пример: Банковские операции

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

## 3. Транзакции и ACID

### Что такое транзакция?

**Транзакция** — последовательность операций, выполняемая как единое целое.

### ACID свойства

**ACID** — аббревиатура четырёх свойств транзакции:

| Свойство | Описание | Пример |
|----------|----------|--------|
| **A**tomicity | Атомарность — всё или ничего | Либо все операции выполняются, либо ни одна |
| **C**onsistency | Согласованность — данные валидны | Баланс не уходит в минус после транзакции |
| **I**solation | Изолированность — параллельные транзакции не мешают | Два перевода не влияют друг на друга |
| **D**urability | Долговечность — после COMMIT изменения постоянны | После фиксации данные сохраняются даже при сбое |

### Подробное описание ACID

#### Atomicity (Атомарность)

**Гарантия:** Все операции транзакции выполняются успешно, или ни одна не выполняется.

```sql
START TRANSACTION;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

-- Если ошибка во втором UPDATE, первый будет отменён
COMMIT;  -- или ROLLBACK при ошибке
```

**Реализация в InnoDB:**
- Журнал транзакций (redo log)
- Откат изменений (undo log)
- Двухфазная фиксация (two-phase commit)

#### Consistency (Согласованность)

**Гарантия:** Транзакция переводит базу из одного согласованного состояния в другое.

```sql
-- Ограничения целостности
CREATE TABLE accounts (
    id INT PRIMARY KEY,
    balance DECIMAL(10,2) NOT NULL CHECK (balance >= 0)
);

START TRANSACTION;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- Если balance < 0, транзакция будет отменена

COMMIT;
```

**Проверки:**
- FOREIGN KEY ограничения
- UNIQUE ограничения
- CHECK ограничения
- NOT NULL ограничения

#### Isolation (Изолированность)

**Гарантия:** Параллельные транзакции не влияют друг на друга.

```sql
-- Транзакция 1
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;  -- 1000

-- Транзакция 2 (параллельно)
START TRANSACTION;
UPDATE accounts SET balance = 900 WHERE id = 1;
COMMIT;

-- Транзакция 1 (в зависимости от уровня изоляции)
SELECT balance FROM accounts WHERE id = 1;  -- 1000 или 900
COMMIT;
```

#### Durability (Долговечность)

**Гарантия:** После COMMIT изменения сохраняются навсегда.

```sql
START TRANSACTION;
UPDATE accounts SET balance = 1000 WHERE id = 1;
COMMIT;  -- После этого данные сохранены даже при сбое питания

-- InnoDB использует:
-- - Redo log для восстановления
-- - Doublewrite buffer для защиты от частичной записи
-- - Flush на диск при COMMIT
```

### Уровни изоляции транзакций

**Синтаксис:**
```sql
-- Для сессии
SET [SESSION] TRANSACTION ISOLATION LEVEL level;

-- Для следующей транзакции
SET TRANSACTION ISOLATION LEVEL level;

-- Проверка текущего уровня
SELECT @@transaction_isolation;
```

**4 уровня изоляции (от слабого к сильному):**

| Уровень | Грязное чтение | Неповторяемое чтение | Фантомы | Производительность |
|---------|---------------|---------------------|---------|-------------------|
| **READ UNCOMMITTED** | ✅ Возможно | ✅ Возможно | ✅ Возможно | ⭐⭐⭐⭐⭐ |
| **READ COMMITTED** | ❌ Нет | ✅ Возможно | ✅ Возможно | ⭐⭐⭐⭐ |
| **REPEATABLE READ** | ❌ Нет | ❌ Нет | ✅ Возможно* | ⭐⭐⭐ |
| **SERIALIZABLE** | ❌ Нет | ❌ Нет | ❌ Нет | ⭐⭐ |

*В InnoDB фантомы блокируются диапазоными блокировками

### Проблемы параллелизма

#### 1. Dirty Read (Грязное чтение)

```sql
-- Транзакция 1
START TRANSACTION;
UPDATE accounts SET balance = 900 WHERE id = 1;  -- balance был 1000
-- ещё не COMMIT

-- Транзакция 2 (READ UNCOMMITTED)
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;  -- Читает 900 (грязное!)

-- Транзакция 1
ROLLBACK;  -- Отмена изменений

-- Транзакция 2 получила неверные данные!
```

**Решение:** READ COMMITTED или выше

#### 2. Non-Repeatable Read (Неповторяемое чтение)

```sql
-- Транзакция 1
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;  -- 1000

-- Транзакция 2
START TRANSACTION;
UPDATE accounts SET balance = 900 WHERE id = 1;
COMMIT;

-- Транзакция 1 (повторный запрос)
SELECT balance FROM accounts WHERE id = 1;  -- 900 (изменилось!)
-- Данные изменились в середине транзакции!
```

**Решение:** REPEATABLE READ или выше

#### 3. Phantom Read (Фантомы)

```sql
-- Транзакция 1
START TRANSACTION;
SELECT COUNT(*) FROM game_sessions WHERE player_id = 1;  -- 5

-- Транзакция 2
START TRANSACTION;
INSERT INTO game_sessions (player_id, score) VALUES (1, 100);
COMMIT;

-- Транзакция 1 (повторный запрос)
SELECT COUNT(*) FROM game_sessions WHERE player_id = 1;  -- 6 (появилась новая строка!)
```

**Решение:** SERIALIZABLE

#### 4. Lost Update (Потерянное обновление)

```sql
-- Транзакция 1
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;  -- 1000

-- Транзакция 2 (параллельно)
START TRANSACTION;
SELECT balance FROM accounts WHERE id = 1;  -- 1000

-- Транзакция 1
UPDATE accounts SET balance = 1000 - 100 = 900 WHERE id = 1;
COMMIT;

-- Транзакция 2
UPDATE accounts SET balance = 1000 - 50 = 950 WHERE id = 1;
COMMIT;

-- Результат: 950 вместо 850! Обновление транзакции 1 потеряно.
```

**Решение:** SELECT ... FOR UPDATE или оптимистичная блокировка

### Блокировки в транзакциях

#### Shared Lock (S) — Разделяемая

```sql
-- Разрешает другим читать, но не писать
SELECT * FROM accounts WHERE id = 1 LOCK IN SHARE MODE;

-- Другая транзакция может:
SELECT * FROM accounts WHERE id = 1;  -- ✅ Читать
UPDATE accounts SET balance = 100 WHERE id = 1;  -- ❌ Ждёт
```

#### Exclusive Lock (X) — Исключительная

```sql
-- Блокирует чтение и запись другими
SELECT * FROM accounts WHERE id = 1 FOR UPDATE;

-- Другая транзакция не может:
SELECT * FROM accounts WHERE id = 1;  -- ✅ Читать (зависит от уровня)
UPDATE accounts SET balance = 100 WHERE id = 1;  -- ❌ Ждёт
INSERT INTO accounts ...;  -- ❌ Ждёт
```

#### Intention Locks — Намеренные блокировки

```
Таблица: accounts
├── IX (Intention Exclusive) — намерение блокировать строки
│   ├── X (строка 1)
│   ├── X (строка 2)
│   └── X (строка 3)
└── IS (Intention Shared) — намерение читать строки
    ├── S (строка 4)
    └── S (строка 5)
```

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

## 6. Пример: Банковские операции

### Таблица счетов (упрощённая схема)

```sql
CREATE TABLE accounts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL UNIQUE,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    version INT UNSIGNED DEFAULT 0  -- Для оптимистичной блокировки
) ENGINE=InnoDB;

-- Тестовые данные
INSERT INTO accounts (user_id, balance) VALUES
(1, 10000.00),  -- Счёт 1: 10 000 руб
(2, 5000.00),   -- Счёт 2: 5 000 руб
(3, 7500.00);   -- Счёт 3: 7 500 руб
```

### Пример 1: Перевод между счетами (базовый)

```sql
DELIMITER //

CREATE PROCEDURE transfer_funds(
    IN p_from INT, IN p_to INT, IN p_amount DECIMAL(15,2),
    OUT p_status VARCHAR(20)
)
BEGIN
    DECLARE v_balance DECIMAL(15,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN ROLLBACK; SET p_status = 'failed'; END;
    
    START TRANSACTION;
    
    -- Блокировка строки отправителя
    SELECT balance INTO v_balance FROM accounts
    WHERE id = p_from FOR UPDATE;
    
    IF v_balance < p_amount THEN
        ROLLBACK;
        SET p_status = 'insufficient_funds';
    ELSE
        UPDATE accounts SET balance = balance - p_amount WHERE id = p_from;
        UPDATE accounts SET balance = balance + p_amount WHERE id = p_to;
        COMMIT;
        SET p_status = 'completed';
    END IF;
END//

DELIMITER ;

-- Использование:
CALL transfer_funds(1, 2, 1000.00, @status);
SELECT @status;
SELECT * FROM accounts WHERE id IN (1, 2);
```

### Пример 2: Внесение наличных

```sql
DELIMITER //

CREATE PROCEDURE deposit_funds(
    IN p_account INT, IN p_amount DECIMAL(15,2),
    OUT p_status VARCHAR(20)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN ROLLBACK; SET p_status = 'failed'; END;
    
    START TRANSACTION;
    
    UPDATE accounts SET balance = balance + p_amount WHERE id = p_account;
    
    COMMIT;
    SET p_status = 'completed';
END//

DELIMITER ;

-- Использование:
CALL deposit_funds(1, 5000.00, @status);
SELECT @status, (SELECT balance FROM accounts WHERE id = 1);
```

### Пример 3: Оптимистичная блокировка

```sql
DELIMITER //

CREATE PROCEDURE transfer_optimistic(
    IN p_from INT, IN p_to INT, IN p_amount DECIMAL(15,2),
    OUT p_success BOOLEAN
)
BEGIN
    DECLARE v_balance, v_version INT;
    DECLARE v_affected INT;
    
    START TRANSACTION;
    
    SELECT balance, version INTO v_balance, v_version
    FROM accounts WHERE id = p_from;
    
    IF v_balance >= p_amount THEN
        UPDATE accounts
        SET balance = balance - p_amount, version = version + 1
        WHERE id = p_from AND version = v_version;
        
        SET v_affected = ROW_COUNT();
        
        IF v_affected > 0 THEN
            UPDATE accounts SET balance = balance + p_amount WHERE id = p_to;
            COMMIT;
            SET p_success = TRUE;
        ELSE
            ROLLBACK;  -- Конфликт версии
            SET p_success = FALSE;
        END IF;
    ELSE
        ROLLBACK;
        SET p_success = FALSE;
    END IF;
END//

DELIMITER ;
```

### Пример 4: Откат при ошибке

```sql
DELIMITER //

CREATE PROCEDURE safe_transfer(
    IN p_from INT, IN p_to INT, IN p_amount DECIMAL(15,2),
    OUT p_status VARCHAR(50)
)
BEGIN
    DECLARE v_balance DECIMAL(15,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @msg = MESSAGE_TEXT;
        ROLLBACK;
        SET p_status = CONCAT('Error: ', @msg);
    END;
    
    START TRANSACTION;
    
    SELECT balance INTO v_balance FROM accounts
    WHERE id = p_from FOR UPDATE;
    
    IF v_balance < p_amount THEN
        ROLLBACK;
        SET p_status = 'Insufficient funds';
    ELSEIF p_from = p_to THEN
        ROLLBACK;
        SET p_status = 'Same account';
    ELSE
        UPDATE accounts SET balance = balance - p_amount WHERE id = p_from;
        UPDATE accounts SET balance = balance + p_amount WHERE id = p_to;
        COMMIT;
        SET p_status = 'completed';
    END IF;
END//

DELIMITER ;
```

### Демонстрация транзакций

```sql
-- Проверка балансов
SELECT * FROM accounts;

-- Тест 1: Успешный перевод
CALL transfer_funds(1, 2, 1000.00, @status);
SELECT @status;  -- completed

-- Тест 2: Недостаточно средств
CALL transfer_funds(2, 3, 10000.00, @status);
SELECT @status;  -- insufficient_funds

-- Тест 3: Внесение наличных
CALL deposit_funds(1, 5000.00, @status);
SELECT @status, (SELECT balance FROM accounts WHERE id = 1);

-- Итоговые балансы
SELECT * FROM accounts;
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
