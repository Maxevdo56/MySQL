-- 1. Создайте таблицу logs типа Archive. Пусть при каждом создании записи в таблицах 
-- users, catalogs и products в таблицу logs помещается время и дата создания записи, 
-- название таблицы, идентификатор первичного ключа и содержимое поля name.

CREATE TABLE `vk`.`logs` (
  `created_at` DATETIME NOT NULL,
  `tablename` VARCHAR(45) NOT NULL,
  `primary_id` INT NOT NULL,
  `namecolumn` VARCHAR(45) NOT NULL)
ENGINE = ARCHIVE;

USE VK;
DELIMITER $$

DROP TRIGGER IF EXISTS users_insert $$
CREATE TRIGGER users_insert AFTER INSERT ON users
FOR EACH ROW
BEGIN
	INSERT INTO vk.logs (`created_at`, `tablename`, `primary_id`, `namecolumn`) 
    VALUES (NOW(), 'users', NEW.id, NEW.firstname);
END $$

DROP TRIGGER IF EXISTS catalogs_insert $$
CREATE TRIGGER catalogs_insert AFTER INSERT ON catalogs
FOR EACH ROW
BEGIN
	INSERT INTO vk.logs (`created_at`, `tablename`, `primary_id`, `namecolumn`) 
    VALUES (NOW(), 'catalogs', NEW.id, NEW.name);
END $$

DROP TRIGGER IF EXISTS products_insert $$
CREATE TRIGGER products_insert AFTER INSERT ON products
FOR EACH ROW
BEGIN
	INSERT INTO vk.logs (`created_at`, `tablename`, `primary_id`, `namecolumn`) 
    VALUES (NOW(), 'products', NEW.id, NEW.name);
END $$
DELIMITER ;

-- (по желанию) Создайте SQL-запрос, который помещает в таблицу users миллион записей.
DELIMITER $$

DROP PROCEDURE IF EXISTS insert_tousers;
CREATE PROCEDURE insert_tousers(num INT)
BEGIN
	DECLARE i INT DEFAULT 1;
    DECLARE cur_id INT;
    DECLARE username VARCHAR(45);
    DECLARE usersurname VARCHAR(45);
    DECLARE pass VARCHAR(45);
    DECLARE phonenum VARCHAR(45);
    DECLARE birthdate DATE;
    WHILE i <= num DO
		SET cur_id = (SELECT max(id) FROM users) + 1;
		SET username = concat('name', cur_id);
        SET usersurname = concat('surname', cur_id);
        SET pass = concat('7dfe44445572d83ebe8a87453d14a63bd15', cur_id);
        SET phonenum = concat('777', cur_id);
        SET birthdate = DATE_ADD('2010-01-01', INTERVAL -(RAND()*18400) DAY);
			INSERT INTO `vk`.`users` 
				(`id`, `firstname`, `lastname`, `password_hash`, `phone`, `created_at`, `updated_at`, `date_of_birth`) 
			VALUES 
				(cur_id, username, usersurname, pass, phonenum, NOW(), NOW(), birthdate);
		SET i = i + 1;
	END WHILE;
END $$
DELIMITER ;
-- здесь вызываем процедуру с параметром 1000000.
-- но я бы не делал этого, т.к. с параметром 10000 у меня выполнялось 24 секунды.
-- предполагаю, что с параметром в 100 раз больше будет выполняться 2400 сек = 40 минут ))
CALL insert_tousers(10000);


/******** Практическое задание по теме “NoSQL” ********/

/*
1. В базе данных Redis подберите коллекцию для подсчета посещений с определенных IP-адресов

Хранение подсчета посещений удобно хранить в коллекции типа "число"
SET ip_1 0 -- установка счетчика ip 1
INCR ip_1 -- увеличение счетчика посещений

2. При помощи базы данных Redis решите задачу поиска имени пользователя по электронному адресу 
и наоборот, поиск электронного адреса пользователя по его имени.

1) Храним в коллекции типа строка: 
MSET dima dima@mail.ru ivan ivan@mail.ru
2) Поиск e-mail по логину:
GET dima
3) поиск логина по email:
SCAN 0 MATCH "*:dima@mail.ru"

3. Организуйте хранение категорий и товарных позиций учебной базы данных shop в СУБД MongoDB.
db.shop.insert({name: "Lenovo X201", category: "notebooks"})
db.shop.insert({name: "HP Gamig R60", category: "notebooks"})
db.shop.insert({name: "Intel core i-5 8250", category: "processors"})
db.shop.insert({name: "AMD Ryzen-5 4600H", category: "processors"})
*/
