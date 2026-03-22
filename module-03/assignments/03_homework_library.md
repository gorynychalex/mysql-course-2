# Домашнее задание - Модуль 3

## Тема: DDL для базы данных библиотеки

### Легенда

Продолжаем разработку системы управления библиотекой. На этом этапе необходимо создать полноценную схему базы данных с использованием всех изученных DDL-операторов, индексов и оптимизаций.

---

## Часть 1. Создание полной схемы БД (15 баллов)

### Задание:

Создайте базу данных `library_final` со следующей структурой:

### Таблицы:

#### 1. `authors` (Авторы)
```
- id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- first_name VARCHAR(50) NOT NULL
- last_name VARCHAR(50) NOT NULL
- middle_name VARCHAR(50)
- birth_date DATE
- death_date DATE
- country VARCHAR(50)
- biography TEXT
- is_active BOOLEAN DEFAULT TRUE
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

Индексы:
- INDEX idx_name (last_name, first_name)
- INDEX idx_country (country)
- FULLTEXT INDEX ft_author (first_name, last_name, biography)
```

#### 2. `publishers` (Издательства)
```
- id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- name VARCHAR(200) NOT NULL UNIQUE
- city VARCHAR(100)
- country VARCHAR(50)
- website VARCHAR(255)
- founded_year YEAR
- description TEXT

Индексы:
- INDEX idx_country (country)
- FULLTEXT INDEX ft_publisher (name, description)
```

#### 3. `categories` (Категории книг)
```
- id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- name VARCHAR(100) NOT NULL
- slug VARCHAR(100) NOT NULL UNIQUE
- parent_id INT UNSIGNED NULL
- description TEXT
- sort_order TINYINT DEFAULT 0

Индексы:
- FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
- INDEX idx_parent (parent_id)
```

#### 4. `books` (Книги - библиографические записи)
```
- id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- title VARCHAR(500) NOT NULL
- subtitle VARCHAR(300)
- isbn CHAR(13) UNIQUE
- isbn10 CHAR(10)
- language CHAR(2) DEFAULT 'ru'
- original_title VARCHAR(500)
- publication_year YEAR
- pages_count INT UNSIGNED
- price DECIMAL(10,2) DEFAULT 0.00
- rating DECIMAL(3,2) DEFAULT 0.00 CHECK (rating >= 0 AND rating <= 5)
- description TEXT
- cover_image_url VARCHAR(255)
- status ENUM('active', 'inactive', 'archived') DEFAULT 'active'
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

Индексы:
- INDEX idx_title (title)
- INDEX idx_year (publication_year)
- INDEX idx_status (status)
- INDEX idx_language (language)
- FULLTEXT INDEX ft_book (title, subtitle, description)
```

#### 5. `book_authors` (Связь книг и авторов M:N)
```
- book_id INT UNSIGNED NOT NULL
- author_id INT UNSIGNED NOT NULL
- author_order TINYINT DEFAULT 1

PRIMARY KEY (book_id, author_id)
FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
FOREIGN KEY (author_id) REFERENCES authors(id) ON DELETE CASCADE
INDEX idx_author (author_id)
```

#### 6. `book_categories` (Связь книг и категорий M:N)
```
- book_id INT UNSIGNED NOT NULL
- category_id INT UNSIGNED NOT NULL
- is_primary BOOLEAN DEFAULT FALSE

PRIMARY KEY (book_id, category_id)
FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
INDEX idx_category (category_id)
```

#### 7. `book_copies` (Экземпляры книг)
```
- id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- book_id INT UNSIGNED NOT NULL
- inventory_number VARCHAR(50) NOT NULL UNIQUE
- acquisition_date DATE
- source VARCHAR(100)
- purchase_price DECIMAL(10,2)
- condition ENUM('excellent', 'good', 'fair', 'poor', 'damaged') DEFAULT 'good'
- location VARCHAR(50)
- status ENUM('available', 'borrowed', 'reserved', 'maintenance', 'lost', 'written_off') DEFAULT 'available'
- notes TEXT
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

Индексы:
- FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE RESTRICT
- INDEX idx_status (status)
- INDEX idx_location (location)
- INDEX idx_inventory (inventory_number)
```

#### 8. `readers` (Читатели)
```
- id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- reader_card_number VARCHAR(20) NOT NULL UNIQUE
- first_name VARCHAR(50) NOT NULL
- last_name VARCHAR(50) NOT NULL
- middle_name VARCHAR(50)
- birth_date DATE
- gender ENUM('M', 'F')
- email VARCHAR(100) NOT NULL UNIQUE
- phone VARCHAR(20)
- address VARCHAR(255)
- city VARCHAR(100)
- postal_code VARCHAR(10)
- occupation VARCHAR(100)
- education_level ENUM('secondary', 'bachelor', 'master', 'phd', 'other')
- registration_date DATE NOT NULL
- membership_until DATE
- is_active BOOLEAN DEFAULT TRUE
- is_blocked BOOLEAN DEFAULT FALSE
- block_reason VARCHAR(255)
- blocked_until DATE
- notes TEXT
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

Индексы:
- INDEX idx_name (last_name, first_name)
- INDEX idx_email (email)
- INDEX idx_card (reader_card_number)
- INDEX idx_status (is_active, is_blocked)
- FULLTEXT INDEX ft_reader (first_name, last_name, address)
```

#### 9. `loans` (Выдача книг)
```
- id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- copy_id INT UNSIGNED NOT NULL
- reader_id INT UNSIGNED NOT NULL
- loan_date DATE NOT NULL
- due_date DATE NOT NULL
- return_date DATE
- expected_return_date DATE
- loan_type ENUM('home', 'reading_room', 'interlibrary', 'short_term') DEFAULT 'home'
- status ENUM('active', 'returned', 'overdue', 'lost') DEFAULT 'active'
- renewal_count TINYINT DEFAULT 0
- max_renewals TINYINT DEFAULT 2
- notes TEXT
- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

Индексы:
- FOREIGN KEY (copy_id) REFERENCES book_copies(id) ON DELETE RESTRICT
- FOREIGN KEY (reader_id) REFERENCES readers(id) ON DELETE RESTRICT
- INDEX idx_reader (reader_id)
- INDEX idx_copy (copy_id)
- INDEX idx_status (status)
- INDEX idx_dates (loan_date, due_date, return_date)
- INDEX idx_due (due_date, status)
```

#### 10. `reservations` (Резервирование)
```
- id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- book_id INT UNSIGNED NOT NULL
- reader_id INT UNSIGNED NOT NULL
- reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- expiry_date DATE
- status ENUM('pending', 'ready', 'fulfilled', 'cancelled', 'expired') DEFAULT 'pending'
- notification_sent BOOLEAN DEFAULT FALSE
- notes TEXT

Индексы:
- FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
- FOREIGN KEY (reader_id) REFERENCES readers(id) ON DELETE CASCADE
- INDEX idx_reader (reader_id)
- INDEX idx_status (status)
- INDEX idx_book (book_id, status)
```

#### 11. `fines` (Штрафы)
```
- id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- loan_id INT UNSIGNED NOT NULL
- reader_id INT UNSIGNED NOT NULL
- fine_date DATE NOT NULL
- amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0)
- reason ENUM('overdue', 'lost', 'damaged', 'other') DEFAULT 'overdue'
- days_overdue SMALLINT
- paid_amount DECIMAL(10,2) DEFAULT 0.00
- paid_date DATE
- payment_method ENUM('cash', 'card', 'transfer', 'other')
- status ENUM('pending', 'partial', 'paid', 'waived') DEFAULT 'pending'
- notes TEXT

Индексы:
- FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE RESTRICT
- FOREIGN KEY (reader_id) REFERENCES readers(id) ON DELETE RESTRICT
- INDEX idx_reader (reader_id)
- INDEX idx_status (status)
- INDEX idx_date (fine_date)
```

### Требования:
- Все таблицы должны использовать InnoDB
- Кодировка utf8mb4_unicode_ci
- Все FOREIGN KEY с правильными ON DELETE/ON UPDATE
- CHECK ограничения где применимо
- COMMENT к таблицам

---

## Часть 2. Заполнение тестовыми данными (10 баллов)

### Задание:

Создайте SQL-скрипт с тестовыми данными:

| Таблица | Минимум записей |
|---------|-----------------|
| authors | 20 |
| publishers | 10 |
| categories | 15 (с иерархией) |
| books | 50 |
| book_authors | 60 (связи) |
| book_categories | 70 (связи) |
| book_copies | 100 |
| readers | 30 |
| loans | 100 |
| reservations | 10 |
| fines | 15 |

### Требования к данным:
- Реалистичные названия книг и авторов
- Разные статусы для записей
- Разные даты (прошлые, текущие, будущие)
- Корректные связи между таблицами

---

## Часть 3. Модификация структуры (10 баллов)

### Задание:

После создания схемы выполните следующие изменения:

1. **Добавьте новые столбцы:**
   - В `readers`: `telegram` VARCHAR(50), `preferred_language` CHAR(2) DEFAULT 'ru'
   - В `books`: `series_name` VARCHAR(200), `series_number` SMALLINT
   - В `loans`: `reminder_sent` BOOLEAN DEFAULT FALSE, `reminder_date` DATE

2. **Создайте новые таблицы:**
   - `reviews` (отзывы читателей о книгах)
   - `reading_history` (история просмотров книг читателями)
   - `staff` (сотрудники библиотеки)

3. **Добавьте индексы:**
   - Составные индексы для частых запросов
   - Дополнительные FULLTEXT индексы

4. **Создайте представления:**
   - `v_available_books` - доступные книги
   - `v_overdue_loans` - просроченные выдачи
   - `v_reader_stats` - статистика читателей

---

## Часть 4. Полнотекстовый поиск (5 баллов)

### Задание:

1. Создайте минимум 3 FULLTEXT индекса в разных таблицах

2. Напишите и протестируйте запросы:
   - Поиск книг по названию
   - Поиск авторов по фамилии
   - Поиск по описанию книги с релевантностью

3. Продемонстрируйте разные режимы поиска:
   - NATURAL LANGUAGE MODE
   - BOOLEAN MODE с операторами +, -, *
   - Поиск точной фразы

### Отчет:
- SQL-скрипт с примерами поиска
- Результаты с пояснениями

---

## Формат сдачи

### Структура файлов:

```
module-03/assignments/
├── submission.md                  # Отчет студента
├── library_final_schema.sql       # Полная схема БД
├── library_test_data.sql          # Тестовые данные
├── library_alterations.sql        # ALTER команды
├── library_views.sql              # Представления
├── fulltext_search_examples.sql   # Примеры полнотекстового поиска
└── README.md                      # Документация
```

### Файл submission.md:

```markdown
# Отчет студента: [ФИО]
# Модуль 3: DDL

## Часть 1: Создание схемы
[Описание структуры, особенности решения]

## Часть 2: Тестовые данные
[Как генерировались данные]

## Часть 3: Модификации
[Список внесённых изменений]

## Часть 4: Полнотекстовый поиск
[Примеры запросов и результаты]

## Проблемы и решения
[Описание сложностей]

## Что узнал
[Ключевые инсайты]
```

---

## Критерии оценки

| Критерий | Баллы |
|----------|-------|
| Часть 1: Создание схемы | 15 |
| Часть 2: Тестовые данные | 10 |
| Часть 3: Модификации | 10 |
| Часть 4: FULLTEXT поиск | 5 |
| Оформление и документация | 5 |
| Использование лучших практик | 5 |
| **ИТОГО** | **50** |

---

## Дополнительные баллы (до 10)

- [ ] (+3) Создание триггеров для автоматизации
- [ ] (+3) Создание хранимых процедур
- [ ] (+2) Создание событий (EVENTS)
- [ ] (+2) Документация в формате PDF

---

## Срок сдачи

[Указывается преподавателем]

---

## Чек-лист перед сдачей

- [ ] Все таблицы созданы без ошибок
- [ ] Все FOREIGN KEY работают корректно
- [ ] Индексы созданы
- [ ] Тестовые данные загружаются
- [ ] ALTER команды выполняются
- [ ] FULLTEXT поиск работает
- [ ] Файлы названы правильно
- [ ] Отчет заполнен
