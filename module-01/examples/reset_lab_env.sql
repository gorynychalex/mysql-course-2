# Сброс данных между занятиями
DROP DATABASE IF EXISTS shop;
DROP DATABASE IF EXISTS shop_lab;
DROP USER IF EXISTS 'student'@'localhost';
FLUSH PRIVILEGES;
