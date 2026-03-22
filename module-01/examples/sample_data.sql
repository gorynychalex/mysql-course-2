USE shop;

-- Категории
INSERT INTO categories (name, description) VALUES
('Смартфоны', 'Мобильные телефоны и аксессуары'),
('Ноутбуки', 'Портативные компьютеры'),
('Наушники', 'Аудиотехника'),
('Умные часы', 'Носимая электроника');

-- Товары
INSERT INTO products (category_id, name, description, price, stock) VALUES
(1, 'iPhone 15 Pro', 'Флагманский смартфон Apple', 99990.00, 15),
(1, 'Samsung Galaxy S24', 'Флагман на Android', 79990.00, 23),
(2, 'MacBook Air M2', 'Ультралёгкий ноутбук', 119990.00, 8),
(2, 'Lenovo ThinkPad X1', 'Бизнес-ноутбук', 145000.00, 5),
(3, 'AirPods Pro 2', 'Беспроводные наушники с шумоподавлением', 24990.00, 42),
(3, 'Sony WH-1000XM5', 'Полноразмерные наушники', 34990.00, 18),
(4, 'Apple Watch Series 9', 'Умные часы с GPS', 42990.00, 12),
(4, 'Samsung Galaxy Watch 6', 'Часы на WearOS', 29990.00, 20);

-- Покупатели
INSERT INTO customers (email, first_name, last_name, phone) VALUES
('ivan.petrov@example.com', 'Иван', 'Петров', '+79001112233'),
('maria.sidorova@example.com', 'Мария', 'Сидорова', '+79004445566'),
('alex.kozlov@example.com', 'Александр', 'Козлов', '+79007778899'),
('elena.volkova@example.com', 'Елена', 'Волкова', '+79001234567');

-- Заказы
INSERT INTO orders (customer_id, status, total_amount) VALUES
(1, 'delivered', 124980.00),
(2, 'shipped', 59980.00),
(3, 'processing', 145000.00),
(1, 'new', 24990.00);

-- Позиции заказов
INSERT INTO order_items (order_id, product_id, quantity, price_at_order) VALUES
(1, 1, 1, 99990.00),  -- iPhone 15 Pro
(1, 5, 1, 24990.00),  -- AirPods Pro 2
(2, 6, 1, 34990.00),  -- Sony WH-1000XM5
(2, 8, 1, 29990.00),  -- Galaxy Watch 6
(3, 4, 1, 145000.00), -- ThinkPad X1
(4, 5, 1, 24990.00);  -- AirPods Pro 2
