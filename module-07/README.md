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

### Схема базы данных банка

```sql
-- Таблица счетов клиентов
CREATE TABLE accounts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL UNIQUE,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    currency CHAR(3) DEFAULT 'RUB',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_balance (balance)
) ENGINE=InnoDB;

-- Таблица транзакций (история операций)
CREATE TABLE transactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    from_account_id INT UNSIGNED,
    to_account_id INT UNSIGNED NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    transaction_type ENUM('transfer', 'deposit', 'withdrawal', 'payment') NOT NULL,
    status ENUM('pending', 'completed', 'failed', 'reversed') DEFAULT 'pending',
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL,
    FOREIGN KEY (from_account_id) REFERENCES accounts(id),
    FOREIGN KEY (to_account_id) REFERENCES accounts(id),
    INDEX idx_from (from_account_id),
    INDEX idx_to (to_account_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB;

-- Таблица блокировок (для овердрафта и спорных операций)
CREATE TABLE account_locks (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id INT UNSIGNED NOT NULL,
    lock_amount DECIMAL(15,2) NOT NULL,
    lock_reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    released_at TIMESTAMP NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    INDEX idx_account (account_id),
    INDEX idx_released (released_at)
) ENGINE=InnoDB;
```

### Пример 1: Перевод между счетами

```sql
DELIMITER //

CREATE PROCEDURE transfer_funds(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(15,2),
    IN p_description VARCHAR(255),
    OUT p_transaction_id BIGINT,
    OUT p_status VARCHAR(20)
)
BEGIN
    DECLARE v_from_balance DECIMAL(15,2);
    DECLARE v_locked_amount DECIMAL(15,2) DEFAULT 0;
    DECLARE v_available_balance DECIMAL(15,2);
    
    -- Обработчик ошибок
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'failed';
        SET p_transaction_id = NULL;
    END;
    
    START TRANSACTION;
    
    -- Получаем баланс с блокировкой строки
    SELECT balance INTO v_from_balance
    FROM accounts
    WHERE id = p_from_account
    FOR UPDATE;
    
    -- Получаем сумму блокировок
    SELECT COALESCE(SUM(lock_amount), 0) INTO v_locked_amount
    FROM account_locks
    WHERE account_id = p_from_account AND released_at IS NULL;
    
    -- Вычисляем доступный баланс
    SET v_available_balance = v_from_balance - v_locked_amount;
    
    -- Проверяем достаточность средств
    IF v_available_balance < p_amount THEN
        ROLLBACK;
        SET p_status = 'insufficient_funds';
        SET p_transaction_id = NULL;
    ELSE
        -- Списываем со счёта отправителя
        UPDATE accounts
        SET balance = balance - p_amount
        WHERE id = p_from_account;
        
        -- Зачисляем на счёт получателя
        UPDATE accounts
        SET balance = balance + p_amount
        WHERE id = p_to_account;
        
        -- Создаём запись о транзакции
        INSERT INTO transactions (
            from_account_id,
            to_account_id,
            amount,
            transaction_type,
            status,
            description,
            processed_at
        ) VALUES (
            p_from_account,
            p_to_account,
            p_amount,
            'transfer',
            'completed',
            p_description,
            NOW()
        );
        
        SET p_transaction_id = LAST_INSERT_ID();
        SET p_status = 'completed';
        
        COMMIT;
    END IF;
END//

DELIMITER ;

-- Использование:
CALL transfer_funds(1, 2, 1000.00, 'Перевод другу', @txn_id, @status);
SELECT @txn_id, @status;
```

### Пример 2: Внесение наличных (депозит)

```sql
DELIMITER //

CREATE PROCEDURE deposit_funds(
    IN p_account_id INT,
    IN p_amount DECIMAL(15,2),
    IN p_description VARCHAR(255),
    OUT p_transaction_id BIGINT,
    OUT p_status VARCHAR(20)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'failed';
        SET p_transaction_id = NULL;
    END;
    
    START TRANSACTION;
    
    -- Проверяем существование счёта с блокировкой
    SELECT id INTO @account_exists
    FROM accounts
    WHERE id = p_account_id
    FOR UPDATE;
    
    IF @account_exists IS NULL THEN
        ROLLBACK;
        SET p_status = 'account_not_found';
        SET p_transaction_id = NULL;
    ELSE
        -- Зачисляем на счёт
        UPDATE accounts
        SET balance = balance + p_amount
        WHERE id = p_account_id;
        
        -- Создаём запись о транзакции
        INSERT INTO transactions (
            to_account_id,
            amount,
            transaction_type,
            status,
            description,
            processed_at
        ) VALUES (
            p_account_id,
            p_amount,
            'deposit',
            'completed',
            p_description,
            NOW()
        );
        
        SET p_transaction_id = LAST_INSERT_ID();
        SET p_status = 'completed';
        
        COMMIT;
    END IF;
END//

DELIMITER ;
```

### Пример 3: Массовые выплаты (batch processing)

```sql
DELIMITER //

CREATE PROCEDURE process_batch_payments(
    IN p_from_account INT,
    IN p_payment_file_id INT,
    OUT p_success_count INT,
    OUT p_fail_count INT,
    OUT p_status VARCHAR(20)
)
BEGIN
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_to_account INT;
    DECLARE v_amount DECIMAL(15,2);
    DECLARE v_total_amount DECIMAL(15,2) DEFAULT 0;
    DECLARE v_balance DECIMAL(15,2);
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'failed';
    END;
    
    START TRANSACTION;
    
    -- Получаем баланс с блокировкой
    SELECT balance INTO v_balance
    FROM accounts
    WHERE id = p_from_account
    FOR UPDATE;
    
    -- Курсор для файлов платежей
    DECLARE payment_cursor CURSOR FOR
        SELECT to_account, amount
        FROM payment_file_items
        WHERE file_id = p_payment_file_id
        AND status = 'pending';
    
    OPEN payment_cursor;
    
    read_loop: LOOP
        FETCH payment_cursor INTO v_to_account, v_amount;
        
        IF v_done THEN
            LEAVE read_loop;
        END IF;
        
        SET v_total_amount = v_total_amount + v_amount;
        
        -- Проверяем достаточность средств
        IF v_total_amount > v_balance THEN
            SET p_status = 'insufficient_funds';
            LEAVE read_loop;
        END IF;
        
        -- Зачисляем получателю
        UPDATE accounts
        SET balance = balance + v_amount
        WHERE id = v_to_account;
        
        -- Обновляем статус платежа
        UPDATE payment_file_items
        SET status = 'processed', processed_at = NOW()
        WHERE file_id = p_payment_file_id
        AND to_account = v_to_account;
        
        SET p_success_count = p_success_count + 1;
    END LOOP;
    
    CLOSE payment_cursor;
    
    IF p_status IS NULL OR p_status = 'completed' THEN
        -- Списываем общую сумму со счёта отправителя
        UPDATE accounts
        SET balance = balance - v_total_amount
        WHERE id = p_from_account;
        
        COMMIT;
        SET p_status = 'completed';
    ELSE
        ROLLBACK;
        SET p_fail_count = p_success_count;
        SET p_success_count = 0;
    END IF;
END//

DELIMITER ;
```

### Пример 4: Оптимистичная блокировка (Optimistic Locking)

```sql
-- Таблица с версионированием
CREATE TABLE accounts_optimistic (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    version INT UNSIGNED DEFAULT 0,  -- Версия для оптимистичной блокировки
    INDEX idx_user_version (user_id, version)
) ENGINE=InnoDB;

-- Обновление с проверкой версии
DELIMITER //

CREATE PROCEDURE transfer_optimistic(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(15,2),
    OUT p_success BOOLEAN,
    OUT p_retries INT
)
BEGIN
    DECLARE v_from_version INT;
    DECLARE v_balance DECIMAL(15,2);
    DECLARE v_affected INT;
    
    SET p_retries = 0;
    SET p_success = FALSE;
    
    retry_loop: LOOP
        START TRANSACTION;
        
        -- Получаем текущую версию и баланс
        SELECT balance, version INTO v_balance, v_from_version
        FROM accounts_optimistic
        WHERE id = p_from_account;
        
        IF v_balance < p_amount THEN
            ROLLBACK;
            LEAVE retry_loop;
        END IF;
        
        -- Обновляем с проверкой версии
        UPDATE accounts_optimistic
        SET balance = balance - p_amount,
            version = version + 1
        WHERE id = p_from_account
        AND version = v_from_version;
        
        SET v_affected = ROW_COUNT();
        
        IF v_affected = 0 THEN
            -- Конфликт версий, другая транзакция обновила строку
            ROLLBACK;
            SET p_retries = p_retries + 1;
            
            -- Максимум 3 попытки
            IF p_retries >= 3 THEN
                LEAVE retry_loop;
            END IF;
            
            -- Небольшая пауза перед повторной попыткой
            DO SLEEP(0.1);
            ITERATE retry_loop;
        END IF;
        
        -- Зачисление получателю
        UPDATE accounts_optimistic
        SET balance = balance + p_amount,
            version = version + 1
        WHERE id = p_to_account;
        
        COMMIT;
        SET p_success = TRUE;
        LEAVE retry_loop;
    END LOOP;
END//

DELIMITER ;
```

### Пример 5: Откат транзакции при ошибке

```sql
DELIMITER //

CREATE PROCEDURE safe_transfer_with_rollback(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(15,2),
    OUT p_status VARCHAR(50)
)
BEGIN
    DECLARE v_balance DECIMAL(15,2);
    DECLARE v_from_user INT;
    DECLARE v_to_user INT;
    
    -- Обработчик всех ошибок
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @sqlstate = RETURNED_SQLSTATE,
            @errno = MYSQL_ERRNO,
            @msg = MESSAGE_TEXT;
        
        ROLLBACK;
        SET p_status = CONCAT('Error: ', @msg);
    END;
    
    START TRANSACTION;
    
    -- Блокируем оба счёта
    SELECT user_id, balance INTO v_from_user, v_balance
    FROM accounts WHERE id = p_from_account
    FOR UPDATE;
    
    SELECT user_id INTO v_to_user
    FROM accounts WHERE id = p_to_account
    FOR UPDATE;
    
    -- Проверки
    IF v_from_user IS NULL THEN
        ROLLBACK;
        SET p_status = 'Sender account not found';
    ELSEIF v_to_user IS NULL THEN
        ROLLBACK;
        SET p_status = 'Recipient account not found';
    ELSEIF v_balance < p_amount THEN
        ROLLBACK;
        SET p_status = 'Insufficient funds';
    ELSEIF p_from_account = p_to_account THEN
        ROLLBACK;
        SET p_status = 'Cannot transfer to same account';
    ELSEIF p_amount <= 0 THEN
        ROLLBACK;
        SET p_status = 'Invalid amount';
    ELSE
        -- Все проверки пройдены, выполняем перевод
        UPDATE accounts SET balance = balance - p_amount WHERE id = p_from_account;
        UPDATE accounts SET balance = balance + p_amount WHERE id = p_to_account;
        
        INSERT INTO transactions (
            from_account_id, to_account_id, amount,
            transaction_type, status, processed_at
        ) VALUES (
            p_from_account, p_to_account, p_amount,
            'transfer', 'completed', NOW()
        );
        
        COMMIT;
        SET p_status = 'completed';
    END IF;
END//

DELIMITER ;
```

### Тестирование банковских операций

```sql
-- Создаём тестовые счета
INSERT INTO accounts (user_id, balance) VALUES
(1, 10000.00),  -- Счёт 1: 10 000 руб
(2, 5000.00),   -- Счёт 2: 5 000 руб
(3, 7500.00);   -- Счёт 3: 7 500 руб

-- Тест 1: Успешный перевод
CALL transfer_funds(1, 2, 1000.00, 'Оплата заказа', @txn_id, @status);
SELECT @txn_id, @status;
SELECT * FROM accounts WHERE id IN (1, 2);

-- Тест 2: Недостаточно средств
CALL transfer_funds(2, 3, 10000.00, 'Большой перевод', @txn_id, @status);
SELECT @txn_id, @status;

-- Тест 3: Внесение наличных
CALL deposit_funds(1, 5000.00, 'Пополнение через банкомат', @txn_id, @status);
SELECT @txn_id, @status;
SELECT balance FROM accounts WHERE id = 1;

-- Проверка истории транзакций
SELECT 
    t.id,
    t.from_account_id,
    t.to_account_id,
    t.amount,
    t.transaction_type,
    t.status,
    t.created_at
FROM transactions t
ORDER BY t.created_at DESC;
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
