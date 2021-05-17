/*
Задание 1.
Пусть в таблице users поля created_at и updated_at оказались незаполненными. 
Заполните их текущими датой и временем.
*/
UPDATE vk.users SET created_at = '20.10.2017 8:10' WHERE id > 0;
UPDATE vk.users SET updated_at = NOW() WHERE id > 0;

/*
Задание 2.
Таблица users была неудачно спроектирована. 
Записи created_at и updated_at были заданы типом VARCHAR и в них долгое время 
помещались значения в формате 20.10.2017 8:10. 
Необходимо преобразовать поля к типу DATETIME, сохранив введённые ранее значения.
*/

USE VK;
SELECT created_at from users;
SELECT STR_TO_DATE(created_at, '%d.%m.%Y %h:%i');

/*
Задание 3.
В таблице складских запасов storehouses_products в поле value могут встречаться 
самые разные цифры: 0, если товар закончился и выше нуля, если на складе имеются запасы. 
Необходимо отсортировать записи таким образом, чтобы они выводились в порядке увеличения значения value. 
Однако нулевые запасы должны выводиться в конце, после всех записей.
*/

SELECT * FROM storehouses_products WHERE value > 0 ORDER BY value;