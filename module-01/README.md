# Модуль 1. Установка и запуск сервера MySQL

**Продолжительность:** 4 академических часа

## Содержание модуля

1. Дистрибутив
2. Структура файлов
3. Настройка конфигурационного файла
4. Инициализация данных сервера
5. Запуск сервера
6. Запуск консоли mysql
7. Команды консоли
8. Работа с MySQL Workbench
9. Базовые команды SQL

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

## 2. Структура файлов MySQL

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

## 3. Настройка конфигурационного файла

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

## 4. Инициализация данных сервера

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

## 5. Запуск сервера

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

## 6. Запуск консоли mysql

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

## 7. Команды консоли mysql

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

## 8. Работа с MySQL Workbench

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

## 9. Базовые команды SQL

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
