# Практические задания - Модуль 1

## Задание 1. Установка и проверка работы MySQL

**Цель:** Установить MySQL и проверить базовую функциональность

### Вариант A: Классическая установка

1. Скачайте дистрибутив MySQL для вашей ОС
2. Установите MySQL Server и MySQL Workbench
3. Запустите сервер MySQL
4. Подключитесь через консоль mysql
5. Выполните команды:
   ```sql
   SELECT VERSION();
   SELECT USER();
   SHOW DATABASES;
   ```

### Вариант B: Docker (рекомендуется)

1. Установите Docker Desktop
2. Запустите контейнер:
   ```bash
   docker run --name mysql-practice \
     -e MYSQL_ROOT_PASSWORD=root \
     -e MYSQL_DATABASE=practice \
     -p 3306:3306 \
     -d mysql:8.0
   ```
3. Подключитесь:
   ```bash
   docker exec -it mysql-practice mysql -u root -proot
   ```
4. Выполните команды:
   ```sql
   SELECT VERSION();
   SELECT USER();
   SHOW DATABASES;
   ```

### Отчет:
- Скриншот успешного подключения
- Версия MySQL
- Список баз данных

---

## Задание 2. Сравнение MySQL и MariaDB

**Цель:** Изучить различия между MySQL и MariaDB

### Шаги:

1. Запустите MySQL:
   ```bash
   docker run --name mysql-compare \
     -e MYSQL_ROOT_PASSWORD=root \
     -p 3306:3306 \
     -d mysql:8.0
   ```

2. Запустите MariaDB:
   ```bash
   docker run --name mariadb-compare \
     -e MARIADB_ROOT_PASSWORD=root \
     -p 3307:3306 \
     -d mariadb:10.11
   ```

3. Сравните версии:
   ```bash
   docker exec -it mysql-compare mysql -u root -proot -e "SELECT VERSION(), 'MySQL' AS server;"
   docker exec -it mariadb-compare mariadb -u root -proot -e "SELECT VERSION(), 'MariaDB' AS server;"
   ```

4. Сравните движки:
   ```bash
   docker exec -it mysql-compare mysql -u root -proot -e "SHOW ENGINES;" > mysql_engines.txt
   docker exec -it mariadb-compare mariadb -u root -proot -e "SHOW ENGINES;" > mariadb_engines.txt
   ```

5. Сравните переменные:
   ```bash
   docker exec -it mysql-compare mysql -u root -proot -e "SHOW VARIABLES LIKE 'version%';"
   docker exec -it mariadb-compare mariadb -u root -proot -e "SHOW VARIABLES LIKE 'version%';"
   ```

### Отчет:
- Таблица сравнения версий
- Список движков (отличия)
- Выводы о различиях

---

## Задание 3. Создание базы данных викторины

**Цель:** Отработать базовые команды SQL

### Задание:

1. Создайте базу данных `quiz_practice`
2. Создайте таблицу `questions` с полями:
   - `id` (INT, PRIMARY KEY, AUTO_INCREMENT)
   - `question` (VARCHAR(500))
   - `correct_answer` (VARCHAR(200))
   
3. Добавьте 5 вопросов по теме MySQL
4. Выведите все вопросы
5. Обновите один из вопросов
6. Удалите один вопрос

### Пример данных:

| question | correct_answer |
|----------|---------------|
| Какой оператор выбирает данные? | SELECT |
| Что означает SQL? | Structured Query Language |

---

## Задание 3. Работа с конфигурацией

**Цель:** Научиться читать и модифицировать конфигурацию

### Задание:

1. Найдите конфигурационный файл MySQL (my.cnf или my.ini)
2. Определите следующие параметры:
   - Порт подключения
   - Путь к данным (datadir)
   - Максимальное количество подключений
   
3. Измените порт на 3307 (если не занят)
4. Перезапустите сервер
5. Подключитесь на новый порт

### Отчет:
- Путь к конфигурационному файлу
- Значения параметров до и после

---

## Задание 4. Docker Compose для разработки

**Цель:** Научиться использовать Docker Compose

### Шаги:

1. Создайте файл `docker-compose.yml` (используйте пример из examples/)

2. Запустите сервисы:
   ```bash
   docker-compose up -d
   ```

3. Проверьте статус:
   ```bash
   docker-compose ps
   docker-compose logs -f mysql
   ```

4. Подключитесь через phpMyAdmin (http://localhost:8080)

5. Выполните SQL-скрипт из контейнера:
   ```bash
   docker-compose exec mysql mysql -u root -prootpassword -e "SHOW DATABASES;"
   ```

6. Остановите сервисы:
   ```bash
   docker-compose down
   ```

### Отчет:
- Скриншот работающего docker-compose
- Скриншот phpMyAdmin
- Вывод команды `docker-compose ps`

---

## Задание 5. Работа с инициализационными скриптами

**Цель:** Научиться автоматизировать создание БД

### Шаги:

1. Создайте директорию `init-scripts/`

2. Поместите туда SQL-скрипт (пример из examples/init-scripts/)

3. Запустите контейнер с монтированием скрипта:
   ```bash
   docker run --name mysql-init \
     -e MYSQL_ROOT_PASSWORD=root \
     -v ./init-scripts:/docker-entrypoint-initdb.d \
     -p 3306:3306 \
     -d mysql:8.0
   ```

4. Проверьте создание объектов:
   ```bash
   docker exec -it mysql-init mysql -u root -proot -e "USE quiz_db; SHOW TABLES;"
   ```

5. Посмотрите логи инициализации:
   ```bash
   docker logs mysql-init
   ```

### Отчет:
- Скриншот созданных таблиц
- Фрагмент логов инициализации

---

## Задание 6. Резервное копирование в Docker

**Цель:** Научиться делать backup в Docker

### Шаги:

1. Создайте резервную копию:
   ```bash
   docker exec mysql-practice mysqldump -u root -proot practice > backup.sql
   ```

2. Остановите и удалите контейнер:
   ```bash
   docker stop mysql-practice
   docker rm mysql-practice
   ```

3. Запустите новый контейнер:
   ```bash
   docker run --name mysql-restore \
     -e MYSQL_ROOT_PASSWORD=root \
     -p 3306:3306 \
     -d mysql:8.0
   ```

4. Восстановите данные:
   ```bash
   docker exec -i mysql-restore mysql -u root -proot < backup.sql
   ```

5. Проверьте восстановление:
   ```bash
   docker exec -it mysql-restore mysql -u root -proot -e "USE practice; SHOW TABLES;"
   ```

### Отчет:
- Файл backup.sql (фрагмент)
- Скриншот восстановленных данных

---

## Задание 7. MySQL Workbench

**Цель:** Освоить графический интерфейс

### Задание:

1. Создайте новое подключение в Workbench (к Docker-контейнеру)
2. Создайте новую схему через интерфейс
3. Создайте таблицу через Visual Editor
4. Выполните SQL-запрос через SQL Editor
5. Экспортируйте результат в CSV

---

## Задание 8. Импорт/Экспорт данных

**Цель:** Научиться создавать резервные копии

### Задание:

1. Создайте дамп базы данных quiz_practice:
   ```bash
   docker exec mysql-practice mysqldump -u root -proot quiz_practice > backup.sql
   ```

2. Удалите базу данных:
   ```sql
   DROP DATABASE quiz_practice;
   ```

3. Восстановите из дампа:
   ```bash
   docker exec -i mysql-practice mysql -u root -proot < backup.sql
   ```

4. Проверьте восстановление

---

## Критерии оценки

| Критерий | Баллы |
|----------|-------|
| Задание 1: Установка MySQL/Docker | 5 |
| Задание 2: Сравнение MySQL/MariaDB | 10 |
| Задание 3: Базовые команды SQL | 10 |
| Задание 4: Docker Compose | 10 |
| Задание 5: Инициализационные скрипты | 5 |
| Задание 6: Backup в Docker | 5 |
| Задание 7: Workbench | 5 |
| Задание 8: Импорт/Экспорт | 5 |
| Оформление и отчетность | 5 |
| **ИТОГО** | **60** |
