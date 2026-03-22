# Модуль 1. Установка и запуск сервера MySQL

**Продолжительность:** 4 академических часа

## Содержание модуля

1. Дистрибутив
2. MySQL vs MariaDB — различия
3. Структура файлов
4. Настройка конфигурационного файла
5. Инициализация данных сервера
6. Запуск сервера
7. Развёртывание через Docker
8. Запуск консоли mysql
9. Команды консоли
10. Работа с MySQL Workbench
11. Базовые команды SQL

---

## 1. Дистрибутив MySQL

### Что такое дистрибутив?

**Дистрибутив** — это пакет программного обеспечения, содержащий все необходимые компоненты для установки и работы MySQL.

### Варианты дистрибутивов

| Тип | Описание |
|-----|----------|
| **MySQL Installer** (Windows) | Графический установщик, включает все компоненты |
| **RPM/DEB пакеты** (Linux) | Пакеты для систем управления пакетами |
| **Generic Binary** | Универсальный бинарный дистрибутив |
| **Source Code** | Исходный код для компиляции |

### Компоненты дистрибутива

- **MySQL Server** — сервер базы данных
- **MySQL Client** — клиент для подключения
- **MySQL Workbench** — графическая среда разработки
- **MySQL Router** — маршрутизатор для кластеров
- **Connectors** — драйверы для различных языков программирования

### Скачивание

Официальный сайт: [https://dev.mysql.com/downloads/mysql/](https://dev.mysql.com/downloads/mysql/)

---

## 2. MySQL vs MariaDB — различия

### История разделения

**MariaDB** — это форк MySQL, созданный в 2009 году Михаэлем Видениусом, оригинальным разработчиком MySQL. После покупки MySQL компанией Sun Microsystems, а затем Oracle, сообщество открыло форк для сохранения открытости проекта.

### Сравнительная таблица

| Характеристика | MySQL | MariaDB |
|----------------|-------|---------|
| **Владелец** | Oracle Corporation | MariaDB Foundation |
| **Лицензия** | GPL + коммерческая | GPL |
| **Движок по умолчанию** | InnoDB | InnoDB (ранее Aria) |
| **Репликация** | Есть | Есть + Galera Cluster |
| **Производительность** | Хорошая | Выше на 15-25% для некоторых задач |
| **Новые функции** | Консервативно | Более агрессивно |
| **Совместимость** | — | 100% бинарная совместимость |
| **Версионность** | 5.7, 8.0, 8.1 | 10.x, 11.x |

### Ключевые различия

#### 1. Хранилища

```sql
-- MySQL
SHOW ENGINES;
-- InnoDB (default), MyISAM, MEMORY, ARCHIVE, CSV

-- MariaDB
SHOW ENGINES;
-- InnoDB, Aria, ColumnStore, Spider, MyRocks
```

**MariaDB дополнительные движки:**
- **Aria** — улучшенный MyISAM с транзакциями
- **ColumnStore** — колоночное хранилище для аналитики
- **Spider** — шардирование
- **MyRocks** — движок от Facebook

#### 2. Функции и возможности

| Функция | MySQL 8.0 | MariaDB 10.x |
|---------|-----------|--------------|
| Оконные функции | Да | Да |
| CTE (Common Table Expressions) | Да | Да |
| JSON функции | Да | Да (ограниченно) |
| GIS | Да | Да |
| Fulltext поиск | Да | Да |
| Виртуальные колонки | Да | Да |
| Temporal tables | Да (8.0.26+) | Да |

#### 3. Синтаксические различия

```sql
-- MariaDB поддерживает RETURNING в INSERT/UPDATE/DELETE
INSERT INTO users (name, email) VALUES ('John', 'john@test.com')
RETURNING id;

-- MySQL требует отдельного SELECT
INSERT INTO users (name, email) VALUES ('John', 'john@test.com');
SELECT LAST_INSERT_ID();

-- MariaDB: EXCEPT и INTERSECT
SELECT id FROM t1 EXCEPT SELECT id FROM t2;

-- MySQL: использует LEFT JOIN
SELECT t1.id FROM t1 LEFT JOIN t2 ON t1.id = t2.id WHERE t2.id IS NULL;
```

#### 4. Функции MariaDB без аналогов в MySQL

```sql
-- CONNECT — подключение к внешним источникам
CREATE TABLE remote_table (
    id INT
) ENGINE=CONNECT TABLE_TYPE=ODBC CONNECTION='dsn=mydb';

-- SEQUENCE — генератор последовательностей
CREATE SEQUENCE my_seq START WITH 1 INCREMENT BY 1;
SELECT NEXT VALUE FOR my_seq;

-- SYSTEM VERSIONING — темпоральные таблицы
CREATE TABLE employees (
    id INT,
    name VARCHAR(100),
    salary INT
) WITH SYSTEM VERSIONING;
```

#### 5. Производительность

| Тест | MySQL 8.0 | MariaDB 10.6 |
|------|-----------|--------------|
| SELECT (простой) | 100% | 115% |
| JOIN | 100% | 120% |
| INSERT массовый | 100% | 110% |
| Репликация | 100% | 125% |

### Что выбрать?

#### Выбирайте **MySQL**, если:
- ✅ Требуется официальная поддержка Oracle
- ✅ Используете MySQL Enterprise Edition
- ✅ Нужна максимальная совместимость с облачными сервисами
- ✅ Команда уже имеет опыт с MySQL

#### Выбирайте **MariaDB**, если:
- ✅ Важна открытость проекта
- ✅ Нужны дополнительные движки (ColumnStore, Spider)
- ✅ Требуется лучшая производительность для чтения
- ✅ Планируется использование Galera Cluster
- ✅ Нужны функции RETURNING, SEQUENCE, темпоральные таблицы

### Миграция между MySQL и MariaDB

```bash
# Экспорт из MySQL
mysqldump -u root -p --all-databases > backup.sql

# Импорт в MariaDB
mysql -u root -p < backup.sql

# Проверка совместимости
mysqlcheck -u root -p --all-databases --check-upgrade
```

**Важно:** MariaDB обратно совместима с MySQL, но не все функции MySQL 8.0 поддерживаются в старых версиях MariaDB.

---

## 3. Структура файлов MySQL

### Основные директории

```
mysql/
├── bin/           # Исполняемые файлы (mysqld, mysql, mysqladmin)
├── data/          # Файлы данных (базы данных)
├── docs/          # Документация
├── include/       # Заголовочные файлы для разработки
├── lib/           # Библиотеки
├── share/         # Файлы локализации и вспомогательные скрипты
└── test/          # Тестовые файлы
```

### Структура директории data

```
data/
├── mysql/         # Системная база данных (пользователи, привилегии)
├── information_schema/  # Метаданные о всех базах
├── performance_schema/  # Данные о производительности
├── sys/           # Упрощенный доступ к performance_schema
└── <database_name>/  # Пользовательские базы данных
    ├── table_name.frm    # Определение таблицы (в старых версиях)
    ├── table_name.ibd    # Данные и индексы (InnoDB)
    └── db.opt            # Опции базы данных
```

---

## 4. Настройка конфигурационного файла

### Расположение конфигурационных файлов

| ОС | Путь |
|----|------|
| **Linux** | `/etc/my.cnf`, `/etc/mysql/my.cnf`, `~/.my.cnf` |
| **Windows** | `C:\ProgramData\MySQL\MySQL Server X.X\my.ini` |
| **macOS** | `/etc/my.cnf`, `/usr/local/etc/my.cnf` |

### Основные секции конфигурации

```ini
[mysqld]
# Настройки сервера
port=3306
basedir=/usr/local/mysql
datadir=/var/lib/mysql
socket=/tmp/mysql.sock
bind-address=127.0.0.1

# Настройки памяти
key_buffer_size=256M
innodb_buffer_pool_size=1G
max_connections=200

# Настройки журналов
log_error=/var/log/mysql/error.log
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2

[client]
# Настройки клиента
port=3306
socket=/tmp/mysql.sock
default-character-set=utf8mb4

[mysql]
# Настройки командной строки mysql
default-character-set=utf8mb4
```

### Важные параметры

| Параметр | Описание | Значение по умолчанию |
|----------|----------|----------------------|
| `port` | Порт для подключений | 3306 |
| `datadir` | Путь к данным | Зависит от ОС |
| `max_connections` | Максимум подключений | 151 |
| `innodb_buffer_pool_size` | Размер буфера InnoDB | 128M |
| `character-set-server` | Кодировка по умолчанию | utf8mb4 |

---

## 5. Инициализация данных сервера

### Инициализация для Linux

```bash
# Для систем с systemd
sudo mysqld --initialize --user=mysql

# Или с генерацией временного пароля
sudo mysqld --initialize-insecure --user=mysql
```

### Инициализация для Windows

```cmd
# От имени администратора
mysqld --initialize --console
```

### Что происходит при инициализации

1. Создаются системные базы данных (mysql, information_schema, performance_schema, sys)
2. Создаются таблицы привилегий
3. Генерируется временный пароль root (если не используется --initialize-insecure)
4. Создаются файлы журналов

---

## 6. Запуск сервера

### Linux (systemd)

```bash
# Старт
sudo systemctl start mysqld

# Стоп
sudo systemctl stop mysqld

# Рестарт
sudo systemctl restart mysqld

# Статус
sudo systemctl status mysqld

# Автозагрузка
sudo systemctl enable mysqld
```

### Windows

```cmd
# Установка службы
mysqld --install

# Запуск службы
net start MySQL

# Остановка службы
net stop MySQL
```

### macOS

```bash
# Через launchctl
launchctl load -w /Library/LaunchDaemons/com.oracle.oss.mysql.plist

# Или через System Preferences
```

---

## 7. Развёртывание MySQL (MariaDB) при помощи Docker

### Преимущества Docker для разработки

- ✅ Быстрое развёртывание (одна команда)
- ✅ Изоляция от основной системы
- ✅ Лёгкое переключение между версиями
- ✅ Воспроизводимая среда
- ✅ Чистая система после удаления контейнера

### Требования

- Docker Desktop (Windows/macOS) или Docker Engine (Linux)
- Docker Compose (опционально, для сложных конфигураций)

### Быстрый запуск MySQL

```bash
# MySQL 8.0 с паролем root
docker run --name mysql-dev \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=library \
  -e MYSQL_USER=librarian \
  -e MYSQL_PASSWORD=librarian123 \
  -p 3306:3306 \
  -d mysql:8.0

# Подключение
docker exec -it mysql-dev mysql -u root -prootpassword

# Или из хоста
mysql -h 127.0.0.1 -P 3306 -u root -prootpassword
```

### Быстрый запуск MariaDB

```bash
# MariaDB 10.11 (LTS)
docker run --name mariadb-dev \
  -e MARIADB_ROOT_PASSWORD=rootpassword \
  -e MARIADB_DATABASE=library \
  -e MARIADB_USER=librarian \
  -e MARIADB_PASSWORD=librarian123 \
  -p 3306:3306 \
  -d mariadb:10.11

# Подключение
docker exec -it mariadb-dev mariadb -u root -prootpassword
```

### Параметры Docker

| Параметр | Описание |
|----------|----------|
| `--name` | Имя контейнера |
| `-e MYSQL_ROOT_PASSWORD` | Пароль root |
| `-e MYSQL_DATABASE` | Создать БД при старте |
| `-e MYSQL_USER` | Создать пользователя |
| `-e MYSQL_PASSWORD` | Пароль пользователя |
| `-p 3306:3306` | Проброс порта (хост:контейнер) |
| `-d` | Запуск в фоне (daemon) |
| `-v` | Том для сохранения данных |
| `--restart` | Политика перезапуска |

### Запуск с сохранением данных

```bash
# С именованным томом (рекомендуется)
docker run --name mysql-dev \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -v mysql_data:/var/lib/mysql \
  -p 3306:3306 \
  -d mysql:8.0

# С томом-папкой
docker run --name mysql-dev \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -v /path/on/host:/var/lib/mysql \
  -p 3306:3306 \
  -d mysql:8.0
```

### Управление контейнером

```bash
# Просмотр запущенных контейнеров
docker ps

# Просмотр всех контейнеров
docker ps -a

# Остановка контейнера
docker stop mysql-dev

# Запуск остановленного контейнера
docker start mysql-dev

# Перезапуск
docker restart mysql-dev

# Удаление контейнера
docker rm mysql-dev

# Удаление с данными
docker rm -v mysql-dev
```

### Docker Compose для разработки

Создайте файл `docker-compose.yml`:

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: mysql-dev
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: library
      MYSQL_USER: librarian
      MYSQL_PASSWORD: librarian123
      MYSQL_ROOT_HOST: '%'
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./init-scripts:/docker-entrypoint-initdb.d
      - ./my.cnf:/etc/mysql/conf.d/custom.cnf
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-prootpassword"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Альтернативно: MariaDB
  # mariadb:
  #   image: mariadb:10.11
  #   container_name: mariadb-dev
  #   restart: unless-stopped
  #   environment:
  #     MARIADB_ROOT_PASSWORD: rootpassword
  #     MARIADB_DATABASE: library
  #     MARIADB_USER: librarian
  #     MARIADB_PASSWORD: librarian123
  #   ports:
  #     - "3306:3306"
  #   volumes:
  #     - mariadb_data:/var/lib/mysql

  # phpMyAdmin для управления
  phpmyadmin:
    image: phpmyadmin:latest
    container_name: phpmyadmin-dev
    restart: unless-stopped
    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
      PMA_USER: root
      PMA_PASSWORD: rootpassword
      APACHE_PORT: 8080
    ports:
      - "8080:80"
    depends_on:
      - mysql

volumes:
  mysql_data:
    driver: local
  # mariadb_data:
  #   driver: local
```

### Использование Docker Compose

```bash
# Запуск всех сервисов
docker-compose up -d

# Просмотр логов
docker-compose logs -f mysql

# Остановка
docker-compose down

# Остановка с удалением томов (данные будут удалены!)
docker-compose down -v

# Пересоздание контейнера
docker-compose up -d --force-recreate

# Выполнение команды в контейнере
docker-compose exec mysql mysql -u root -prootpassword -e "SHOW DATABASES;"
```

### Инициализационные скрипты

Скрипты в `/docker-entrypoint-initdb.d` выполняются при первом запуске:

```bash
# ./init-scripts/01-create-tables.sql
CREATE DATABASE IF NOT EXISTS quiz_db;
USE quiz_db;

CREATE TABLE questions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE answers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    question_id INT NOT NULL,
    answer_text VARCHAR(500) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (question_id) REFERENCES questions(id)
);
```

```bash
# ./init-scripts/02-insert-data.sql
USE quiz_db;

INSERT INTO questions (question_text) VALUES
('Что такое SQL?'),
('Что такое база данных?');

INSERT INTO answers (question_id, answer_text, is_correct) VALUES
(1, 'Structured Query Language', TRUE),
(1, 'Simple Question Language', FALSE),
(2, 'Организованная совокупность данных', TRUE),
(2, 'Набор файлов', FALSE);
```

### Переключение между MySQL и MariaDB

```bash
# Остановить MySQL
docker stop mysql-dev
docker rm mysql-dev

# Запустить MariaDB
docker run --name mariadb-dev \
  -e MARIADB_ROOT_PASSWORD=rootpassword \
  -v mysql_data:/var/lib/mysql \
  -p 3306:3306 \
  -d mariadb:10.11

# Проверка версии
docker exec -it mariadb-dev mariadb -u root -prootpassword -e "SELECT VERSION();"
```

### Переменные окружения

#### MySQL

| Переменная | Описание |
|------------|----------|
| `MYSQL_ROOT_PASSWORD` | Пароль root (обязательно) |
| `MYSQL_DATABASE` | БД для создания |
| `MYSQL_USER` | Пользователь |
| `MYSQL_PASSWORD` | Пароль пользователя |
| `MYSQL_ROOT_HOST` | Хост для root (по умолчанию localhost) |

#### MariaDB

| Переменная | Описание |
|------------|----------|
| `MARIADB_ROOT_PASSWORD` | Пароль root |
| `MARIADB_DATABASE` | БД для создания |
| `MARIADB_USER` | Пользователь |
| `MARIADB_PASSWORD` | Пароль пользователя |
| `MARIADB_ROOT_HOST` | Хост для root |

### Отладка и мониторинг

```bash
# Логи контейнера
docker logs mysql-dev

# Статистика ресурсов
docker stats mysql-dev

# Информация о контейнере
docker inspect mysql-dev

# Выполнение команды
docker exec -it mysql-dev mysqladmin -u root -prootpassword processlist

# Копирование файлов
docker cp mysql-dev:/var/lib/mysql ./backup
docker cp ./dump.sql mysql-dev:/docker-entrypoint-initdb.d/
```

### Безопасность

```yaml
# Не используйте в production без изменений!
# Для production:
# 1. Не пробрасывайте порт наружу без необходимости
# 2. Используйте secrets вместо environment
# 3. Настройте сеть
# 4. Используйте read-only файловую систему

version: '3.8'

services:
  mysql:
    image: mysql:8.0
    secrets:
      - mysql_root_password
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
    # ... остальная конфигурация

secrets:
  mysql_root_password:
    external: true
```

### Полезные образы

| Образ | Описание |
|-------|----------|
| `mysql:8.0` | Официальный MySQL 8.0 |
| `mysql:8.4` | MySQL 8.4 (LTS) |
| `mariadb:10.11` | MariaDB 10.11 (LTS) |
| `mariadb:11.2` | MariaDB 11.2 (latest) |
| `percona/percona-server` | Percona Server (форк MySQL) |
| `phpmyadmin` | phpMyAdmin для управления |
| `adminer` | Лёгкая альтернатива phpMyAdmin |

---

## 8. Запуск консоли mysql

### Подключение к серверу

```bash
# Локальное подключение
mysql -u root -p

# Подключение с указанием хоста
mysql -h localhost -u root -p

# Подключение с портом
mysql -h 127.0.0.1 -P 3306 -u root -p

# Подключение с указанием базы данных
mysql -u root -p database_name
```

### Параметры подключения

| Параметр | Описание |
|----------|----------|
| `-u, --user` | Имя пользователя |
| `-p, --password` | Запрос пароля |
| `-h, --host` | Хост сервера |
| `-P, --port` | Порт |
| `-D, --database` | База данных по умолчанию |
| `--socket` | Путь к сокету |
| `--protocol` | Протокол (TCP, SOCKET, PIPE) |

---

## 9. Команды консоли mysql

### Основные команды

| Команда | Описание |
|---------|----------|
| `help` или `\h` | Справка |
| `status` или `\s` | Статус соединения |
| `quit` или `\q` | Выход |
| `use database` | Выбрать базу данных |
| `show databases` | Показать все базы |
| `show tables` | Показать таблицы |
| `describe table` | Структура таблицы |
| `source file.sql` | Выполнить SQL-файл |

### Системные команды

```sql
-- Версия сервера
SELECT VERSION();

-- Текущий пользователь
SELECT USER();

-- Текущая база данных
SELECT DATABASE();

-- Показать переменные сервера
SHOW VARIABLES;

-- Показать статус сервера
SHOW STATUS;

-- Показать процессы
SHOW PROCESSLIST;
```

### Форматирование вывода

```sql
-- Вертикальный вывод (для широких таблиц)
SELECT * FROM table_name\G

-- Разделитель команд
delimiter //

-- Возврат к стандартному
delimiter ;
```

---

## 10. Работа с MySQL Workbench

### Подключение к серверу

1. Запустить MySQL Workbench
2. Нажать "+" рядом с "MySQL Connections"
3. Ввести параметры подключения:
   - Connection Name: имя подключения
   - Hostname: localhost или IP
   - Port: 3306
   - Username: root
   - Password: сохранить в хранилище

### Основные возможности

| Функция | Описание |
|---------|----------|
| **SQL Editor** | Написание и выполнение запросов |
| **Schema Inspector** | Просмотр структуры БД |
| **Visual Explain** | Визуализация плана выполнения |
| **Data Modeling** | Создание ER-диаграмм |
| **Server Administration** | Администрирование сервера |
| **Data Import/Export** | Импорт и экспорт данных |

### Создание новой базы данных

```sql
-- Через SQL Editor
CREATE DATABASE database_name
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
```

---

## 11. Базовые команды SQL

### DDL (Data Definition Language)

```sql
-- Создание базы данных
CREATE DATABASE library;

-- Использование базы данных
USE library;

-- Создание таблицы
CREATE TABLE books (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(100),
    year INT
);

-- Просмотр таблиц
SHOW TABLES;

-- Описание таблицы
DESCRIBE books;
```

### DML (Data Manipulation Language)

```sql
-- Вставка данных
INSERT INTO books (title, author, year) 
VALUES ('War and Peace', 'Leo Tolstoy', 1869);

-- Выборка данных
SELECT * FROM books;
SELECT title, author FROM books WHERE year > 1900;

-- Обновление данных
UPDATE books SET year = 1870 WHERE id = 1;

-- Удаление данных
DELETE FROM books WHERE id = 1;
```

### DCL (Data Control Language)

```sql
-- Создание пользователя
CREATE USER 'librarian'@'localhost' IDENTIFIED BY 'password123';

-- Предоставление прав
GRANT SELECT, INSERT, UPDATE ON library.* TO 'librarian'@'localhost';

-- Отзыв прав
REVOKE INSERT ON library.* FROM 'librarian'@'localhost';
```

---

## Практические задания

См. директорию `practice/`

## Примеры SQL-скриптов

См. директорию `examples/`

## Домашнее задание

См. директорию `assignments/`
