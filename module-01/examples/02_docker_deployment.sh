# ============================================================================
# Module 1: Docker Deployment Examples
# ============================================================================
# Примеры развёртывания MariaDB (основной) и MySQL при помощи Docker
# ============================================================================
# ОСНОВНОЙ СЕРВЕР: MariaDB 10.11 LTS
# ВЕБ-ИНТЕРФЕЙС: Adminer (порт 8081)
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Быстрый запуск MariaDB (основной)
# ----------------------------------------------------------------------------

# MariaDB 10.11 LTS - минимальная команда
docker run --name mariadb-quick \
  -e MARIADB_ROOT_PASSWORD=root \
  -p 3306:3306 \
  -d mariadb:10.11

# MariaDB 10.11 с базой данных и пользователем
docker run --name mariadb-dev \
  -e MARIADB_ROOT_PASSWORD=rootpassword \
  -e MARIADB_DATABASE=library \
  -e MARIADB_USER=librarian \
  -e MARIADB_PASSWORD=librarian123 \
  -p 3306:3306 \
  -d mariadb:10.11

# MariaDB 11.2 Latest
docker run --name mariadb-latest \
  -e MARIADB_ROOT_PASSWORD=rootpassword \
  -e MARIADB_DATABASE=quiz_db \
  -p 3306:3306 \
  -d mariadb:11.2

# ----------------------------------------------------------------------------
# 2. Быстрый запуск MySQL (альтернатива)
# ----------------------------------------------------------------------------

# MySQL 8.0
docker run --name mysql-80 \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=library \
  -p 3307:3306 \
  -d mysql:8.0

# MySQL 8.4 LTS
docker run --name mysql-84 \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=quiz_db \
  -p 3308:3306 \
  -d mysql:8.4

# ----------------------------------------------------------------------------
# 3. Запуск с сохранением данных
# ----------------------------------------------------------------------------

# С именованным томом (рекомендуется для MariaDB)
docker run --name mariadb-persistent \
  -e MARIADB_ROOT_PASSWORD=rootpassword \
  -v mariadb_data:/var/lib/mysql \
  -p 3306:3306 \
  -d mariadb:10.11

# С томом-папкой (замените путь на свой)
docker run --name mariadb-host-data \
  -e MARIADB_ROOT_PASSWORD=rootpassword \
  -v /home/gorynych/mariadb-data:/var/lib/mysql \
  -p 3306:3306 \
  -d mariadb:10.11

# ----------------------------------------------------------------------------
# 4. Подключение к контейнеру
# ----------------------------------------------------------------------------

# Из хоста (MariaDB)
mariadb -h 127.0.0.1 -P 3306 -u root -prootpassword
mariadb -h 127.0.0.1 -P 3306 -u librarian -plibrarian123 library

# Из контейнера (MariaDB)
docker exec -it mariadb-dev mariadb -u root -prootpassword
docker exec -it mariadb-dev mariadb -u librarian -plibrarian123 library

# MySQL (если запущен на порту 3307)
mysql -h 127.0.0.1 -P 3307 -u root -prootpassword

# Альтернативно: используйте mysql клиент для подключения к MariaDB
mysql -h 127.0.0.1 -P 3306 -u root -prootpassword

# ----------------------------------------------------------------------------
# 5. Управление контейнером
# ----------------------------------------------------------------------------

# Просмотр запущенных контейнеров
docker ps
docker ps -a

# Статус конкретного контейнера
docker inspect mariadb-dev --format='{{.State.Status}}'

# Остановка
docker stop mariadb-dev

# Запуск
docker start mariadb-dev

# Перезапуск
docker restart mariadb-dev

# Логи
docker logs mariadb-dev
docker logs -f mariadb-dev  # follow mode

# Статистика ресурсов
docker stats mariadb-dev

# Удаление
docker stop mariadb-dev && docker rm mariadb-dev

# ----------------------------------------------------------------------------
# 6. Проверка версий и информации
# ----------------------------------------------------------------------------

# Версия MariaDB
docker exec -it mariadb-dev mariadb -u root -prootpassword -e "SELECT VERSION();"

# Версия MySQL (если запущен)
docker exec -it mysql-80 mysql -u root -prootpassword -e "SELECT VERSION();"

# Информация о сервере
docker exec -it mariadb-dev mariadb -u root -prootpassword -e "STATUS;"

# Список баз данных
docker exec -it mariadb-dev mariadb -u root -prootpassword -e "SHOW DATABASES;"

# Движки
docker exec -it mariadb-dev mariadb -u root -prootpassword -e "SHOW ENGINES;"

# Переменные
docker exec -it mysql-dev mysql -u root -prootpassword \
  -e "SHOW VARIABLES LIKE 'version%';"

# ----------------------------------------------------------------------------
# 7. Docker Compose
# ----------------------------------------------------------------------------

# docker-compose.yml для разработки (MariaDB + Adminer)
# ---------------------------------
# version: '3.8'
#
# services:
#   mariadb:
#     image: mariadb:10.11
#     container_name: mariadb-dev
#     restart: unless-stopped
#     environment:
#       MARIADB_ROOT_PASSWORD: rootpassword
#       MARIADB_DATABASE: library
#       MARIADB_USER: librarian
#       MARIADB_PASSWORD: librarian123
#       MARIADB_ROOT_HOST: '%'
#     ports:
#       - "3306:3306"
#     volumes:
#       - mariadb_data:/var/lib/mysql
#       - ./init-scripts:/docker-entrypoint-initdb.d
#     command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
#     healthcheck:
#       test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
#       interval: 10s
#       timeout: 5s
#       retries: 5
#
#   adminer:
#     image: adminer:latest
#     container_name: adminer-dev
#     restart: unless-stopped
#     environment:
#       ADMINER_DEFAULT_SERVER: mariadb
#       ADMINER_DESIGN: pepa-linha-dark
#     ports:
#       - "8081:8080"
#     depends_on:
#       - mariadb
#
# volumes:
#   mariadb_data:

# Команды Docker Compose:
docker-compose up -d              # Запуск
docker-compose down               # Остановка
docker-compose down -v            # Остановка с удалением томов
docker-compose ps                 # Статус
docker-compose logs -f mariadb    # Логи
docker-compose exec mariadb bash  # Вход в контейнер

# ----------------------------------------------------------------------------
# 8. Инициализационные скрипты
# ----------------------------------------------------------------------------

# Создайте директорию init-scripts/ и поместите туда SQL файлы
# Они выполняются при первом запуске контейнера

# init-scripts/01-schema.sql
# --------------------------
CREATE DATABASE IF NOT EXISTS quiz_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quiz_db;

CREATE TABLE categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
) ENGINE=InnoDB;

CREATE TABLE questions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    question_text TEXT NOT NULL,
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    points DECIMAL(5,2) DEFAULT 1.00,
    FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB;

CREATE TABLE answers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    question_id INT UNSIGNED NOT NULL,
    answer_text VARCHAR(500) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

# init-scripts/02-data.sql
# ------------------------
USE quiz_db;

INSERT INTO categories (name, description) VALUES
('SQL Basics', 'Основные понятия SQL'),
('Database Design', 'Проектирование БД'),
('MySQL Admin', 'Администрирование MySQL');

INSERT INTO questions (category_id, question_text, difficulty, points) VALUES
(1, 'Что означает SQL?', 'easy', 1.00),
(1, 'Какой оператор выбирает данные?', 'easy', 1.00),
(2, 'Что такое нормализация?', 'medium', 2.00),
(3, 'Порт MySQL по умолчанию?', 'easy', 1.00);

INSERT INTO answers (question_id, answer_text, is_correct) VALUES
(1, 'Structured Query Language', TRUE),
(1, 'Simple Question Language', FALSE),
(1, 'System Query Logic', FALSE),
(1, 'Standard Question List', FALSE),
(2, 'SELECT', TRUE),
(2, 'INSERT', FALSE),
(2, 'UPDATE', FALSE),
(2, 'CREATE', FALSE);

# ----------------------------------------------------------------------------
# 9. Сравнение MySQL и MariaDB
# ----------------------------------------------------------------------------

# Запустите оба и сравните

# MySQL
docker run --name mysql-compare \
  -e MYSQL_ROOT_PASSWORD=root \
  -p 3306:3306 \
  -d mysql:8.0

# MariaDB
docker run --name mariadb-compare \
  -e MARIADB_ROOT_PASSWORD=root \
  -p 3307:3306 \
  -d mariadb:10.11

# Сравнение версий
docker exec -it mysql-compare mysql -u root -proot -e "SELECT VERSION(), 'MySQL' AS server;"
docker exec -it mariadb-compare mariadb -u root -proot -e "SELECT VERSION(), 'MariaDB' AS server;"

# Сравнение движков
docker exec -it mysql-compare mysql -u root -proot -e "SHOW ENGINES;" > mysql_engines.txt
docker exec -it mariadb-compare mariadb -u root -proot -e "SHOW ENGINES;" > mariadb_engines.txt

# Сравнение переменных
docker exec -it mysql-compare mysql -u root -proot -e "SHOW VARIABLES;" > mysql_vars.txt
docker exec -it mariadb-compare mariadb -u root -proot -e "SHOW VARIABLES;" > mariadb_vars.txt

# Остановка
docker stop mysql-compare mariadb-compare
docker rm mysql-compare mariadb-compare

# ----------------------------------------------------------------------------
# 10. Экспорт и импорт данных
# ----------------------------------------------------------------------------

# Экспорт базы данных
docker exec mysql-dev mysqldump -u root -prootpassword library > backup.sql

# Импорт базы данных
docker exec -i mysql-dev mysql -u root -prootpassword library < backup.sql

# Экспорт в сжатом виде
docker exec mysql-dev mysqldump -u root -prootpassword library | gzip > backup.sql.gz

# Импорт из сжатого
gunzip < backup.sql.gz | docker exec -i mysql-dev mysql -u root -prootpassword library

# Копирование файлов
docker cp mysql-dev:/var/lib/mysql ./mysql-data-backup
docker cp ./dump.sql mysql-dev:/docker-entrypoint-initdb.d/

# ----------------------------------------------------------------------------
# 11. Переключение между MySQL и MariaDB
# ----------------------------------------------------------------------------

# Остановить MySQL
docker stop mysql-dev
docker rm mysql-dev

# Запустить MariaDB с теми же данными (осторожно!)
docker run --name mariadb-dev \
  -e MARIADB_ROOT_PASSWORD=rootpassword \
  -v mysql_data:/var/lib/mysql \
  -p 3306:3306 \
  -d mariadb:10.11

# Проверка
docker exec -it mariadb-dev mariadb -u root -prootpassword -e "SELECT VERSION();"

# ----------------------------------------------------------------------------
# 12. Отладка и мониторинг
# ----------------------------------------------------------------------------

# Проверка логов
docker logs mysql-dev
docker logs --tail 100 mysql-dev

# Вход в контейнер
docker exec -it mysql-dev bash

# Проверка процессов MySQL
docker exec -it mysql-dev mysqladmin -u root -prootpassword processlist

# Проверка блокировок
docker exec -it mysql-dev mysql -u root -prootpassword \
  -e "SELECT * FROM INFORMATION_SCHEMA.INNODB_TRX;"

# Проверка размера БД
docker exec -it mysql-dev mysql -u root -prootpassword \
  -e "SELECT table_schema, SUM(data_length + index_length) / 1024 / 1024 AS size_mb \
      FROM information_schema.tables \
      GROUP BY table_schema;"

# ----------------------------------------------------------------------------
# 13. Очистка
# ----------------------------------------------------------------------------

# Удаление всех контейнеров MySQL/MariaDB
docker stop $(docker ps -q --filter ancestor=mysql) $(docker ps -q --filter ancestor=mariadb)
docker rm $(docker ps -aq --filter ancestor=mysql) $(docker ps -aq --filter ancestor=mariadb)

# Удаление томов (осторожно! данные будут потеряны)
docker volume rm mysql_data
docker volume prune --filter label=local

# Полная очистка
docker system prune -a --volumes

# ----------------------------------------------------------------------------
# 14. Практическое задание
# ----------------------------------------------------------------------------

# 1. Запустите MySQL 8.0 с базой library_db
docker run --name mysql-task \
  -e MYSQL_ROOT_PASSWORD=root123 \
  -e MYSQL_DATABASE=library_db \
  -e MYSQL_USER=student \
  -e MYSQL_PASSWORD=student123 \
  -p 3306:3306 \
  -d mysql:8.0

# 2. Подключитесь и создайте таблицу
docker exec -it mysql-task mysql -u student -pstudent123 library_db

CREATE TABLE books (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(100),
    year INT
);

INSERT INTO books (title, author, year) VALUES
('War and Peace', 'Leo Tolstoy', 1869),
('Crime and Punishment', 'Fyodor Dostoevsky', 1866);

SELECT * FROM books;

# 3. Сделайте резервную копию
docker exec mysql-task mysqldump -u student -pstudent123 library_db > library_backup.sql

# 4. Остановите и удалите контейнер
docker stop mysql-task
docker rm mysql-task

# 5. Запустите MariaDB и восстановите данные
docker run --name mariadb-task \
  -e MARIADB_ROOT_PASSWORD=root123 \
  -e MARIADB_DATABASE=library_db \
  -e MARIADB_USER=student \
  -e MARIADB_PASSWORD=student123 \
  -p 3306:3306 \
  -d mariadb:10.11

# 6. Импортируйте данные
docker exec -i mariadb-task mariadb -u student -pstudent123 library_db < library_backup.sql

# 7. Проверьте данные
docker exec -it mariadb-task mariadb -u student -pstudent123 library_db -e "SELECT * FROM books;"

# 8. Очистка
docker stop mariadb-task && docker rm mariadb-task

# ============================================================================
# Конец примеров Docker
# ============================================================================
