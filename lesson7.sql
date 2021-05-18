-- 1. Составьте список пользователей users, которые осуществили хотя бы один заказ orders в интернет магазине.

SELECT * from users WHERE id IN (SELECT user_id FROM orders);

-- 2. Выведите список товаров products и разделов catalogs, который соответствует товару.

SELECT id, (SELECT name FROM catalogs WHERE products.id = catalogs.id) AS 'Категория', counta color FROM products;

-- 3. Пусть имеется таблица рейсов flights (id, from, to) и таблица городов cities (label, name). 
-- Поля from, to и label содержат английские названия городов, поле name — русское.
-- Выведите список рейсов flights с русскими названиями городов.
 
SELECT 
	id, 
	(SELECT name FROM cities WHERE `from` = cities.label) AS 'Откуда',
    (SELECT name FROM cities WHERE `to` = cities.label) AS 'Куда'
FROM flights;