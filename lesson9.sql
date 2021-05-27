/*****************************************
 * ТРАНЗАКЦИИ, ПЕРЕМЕННЫЕ, ПРЕДСТАВЛЕНИЯ *
 *****************************************/

-- 1. В базе данных shop и sample присутствуют одни и те же таблицы, учебной базы данных. 
-- Переместите запись id = 1 из таблицы shop.users в таблицу sample.users. Используйте транзакции.

START TRANSACTION;
    SELECT id, firstname, lastname INTO @id, @firstname, @lastname FROM shop.users WHERE id = 1;
    INSERT INTO sample.users (id, firstname, lastname) VALUES (@id, @firstname, @lastname);
    DELETE FROM shop.users WHERE id = 1;
COMMIT;

-- 2. Создайте представление, которое выводит название name товарной позиции из таблицы products 
-- и соответствующее название каталога name из таблицы catalogs.

DROP VIEW IF EXISTS prod_cat;
CREATE VIEW prod_cat AS 
	(SELECT c.name as cat_name, p.name as prod_name FROM products as p
	JOIN catalogs as c
	ON p.catalog_id = c.id);
SELECT * from prod_cat;

-- 3. Пусть имеется таблица с календарным полем created_at. 
-- В ней размещены разряженые календарные записи за август 2018 года 
-- '2018-08-01', '2016-08-04', '2018-08-16' и 2018-08-17. 
-- Составьте запрос, который выводит полный список дат за август, 
-- выставляя в соседнем поле значение 1, если дата присутствует в исходной таблице и 0, если она отсутствует.

USE `test`;
DROP procedure IF EXISTS `test`.`show_all_august`;

DELIMITER $$
USE `test`$$
CREATE PROCEDURE `show_all_august`()
BEGIN
	DECLARE cur_date DATE;
    DECLARE exists_date INT;
    SET cur_date = DATE_FORMAT('2018-08-01', '%Y-%m-%d');
    DROP TABLE IF EXISTS all_august;
    CREATE TEMPORARY TABLE all_august (
		august_date DATE NOT NULL,
		if_date_exists INT NOT NULL,
		PRIMARY KEY (august_date));
    REPEAT
		IF (cur_date = ANY (SELECT created_at FROM august_table)) 
			THEN SET exists_date = 1;
            ELSE SET exists_date = 0;
		END IF;
        INSERT INTO all_august (august_date, if_date_exists) VALUES (cur_date, exists_date);
        SET cur_date = DATE_ADD(cur_date, INTERVAL 1 DAY);        
	UNTIL cur_date > '2018-08-31'
    END REPEAT;
    SELECT * FROM all_august;
END$$

DELIMITER ;

CALL show_all_august;

-- 5. Пусть имеется любая таблица с календарным полем created_at. 
-- Создайте запрос, который удаляет устаревшие записи из таблицы, оставляя только 5 самых свежих записей.

USE `test`;
DROP procedure IF EXISTS test.five_dates;

DELIMITER $$
USE `test`$$
CREATE PROCEDURE five_dates()
BEGIN	
    DECLARE i INT DEFAULT 1;
    DECLARE limit_date DATE;
    SET limit_date = (SELECT min(created_at) FROM(SELECT * FROM august_table ORDER BY created_at DESC LIMIT 5) as ttt);
    WHILE (i-1) < (SELECT MAX(id) FROM august_table) DO
		IF (SELECT created_at FROM august_table WHERE id = i) < limit_date 
			THEN DELETE FROM august_table WHERE id = i;
        END IF;
		SET i = i + 1;	    
    END WHILE;
END $$

DELIMITER ;

CALL five_dates;


/*****************************************
 * ХРАНИМЫЕ ПРОЦЕДУРЫ, ФУНКЦИИ, ТРИГГЕРЫ *
 *****************************************/
 
-- 1. Создайте хранимую функцию hello(), которая будет возвращать приветствие, 
-- в зависимости от текущего времени суток. 
-- С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", 
-- с 12:00 до 18:00 функция должна возвращать фразу "Добрый день", 
-- с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".

USE `test`;
DROP FUNCTION IF EXISTS hello;

DELIMITER $$
USE `test`$$

CREATE FUNCTION hello(moment_time TIME)
RETURNS TEXT DETERMINISTIC
BEGIN
	DECLARE hello_phrase TEXT;
    IF (moment_time >= time_format('06:00:00', '%H:%i:%S') AND moment_time < time_format('12:00:00', '%H:%i:%S')) 
		THEN SET hello_phrase = 'Доброе утро';
    ELSE
		IF (moment_time >= time_format('12:00:00', '%H:%i:%S') AND moment_time < time_format('18:00:00', '%H:%i:%S')) 
			THEN SET hello_phrase = 'Добрый день';
		ELSE 
			IF (moment_time >= time_format('18:00:00', '%H:%i:%S') AND moment_time < time_format('24:00:00', '%H:%i:%S')) 
				THEN SET hello_phrase = 'Добрый вечер';
			ELSE SET hello_phrase = 'Доброй ночи';
            END IF;
        END IF;
	END IF;
	RETURN concat(hello_phrase, '. Время ', moment_time);
END $$

DELIMITER ;

SELECT hello('06:00'); -- утро
SELECT hello('12:00'); -- день
SELECT hello('18:45'); -- день
SELECT hello('00:45:00'); -- ночь
SELECT hello(NOW()); -- результат в зависимости от текущего времени суток


-- 2. В таблице products есть два текстовых поля: name с названием товара и description с его описанием. 
-- Допустимо присутствие обоих полей или одно из них. 
-- Ситуация, когда оба поля принимают неопределенное значение NULL неприемлема. 
-- Используя триггеры, добейтесь того, чтобы одно из этих полей или оба поля были заполнены. 
-- При попытке присвоить полям NULL-значение необходимо отменить операцию.

SELECT * FROM test.products_tr;
DROP TRIGGER IF EXISTS check_isnull_insert;
DROP TRIGGER IF EXISTS check_isnull_update;

DELIMITER $$
USE `test`$$

CREATE TRIGGER check_isnull_insert BEFORE INSERT ON products_tr
FOR EACH ROW
BEGIN
		IF ((ISNULL(NEW.name) and ISNULL(NEW.description))) 
			THEN SIGNAL SQLSTATE '02000' SET MESSAGE_TEXT = 'Хотя бы одно из полей name и description должно быть заполнено';
		END IF;
END
$$

CREATE TRIGGER check_isnull_update BEFORE UPDATE ON products_tr
FOR EACH ROW
BEGIN
		IF ((ISNULL(NEW.name) and ISNULL(NEW.description))) 
			THEN SIGNAL SQLSTATE '02000' SET MESSAGE_TEXT = 'Хотя бы одно из полей name и description должно быть заполнено';
		END IF;
END $$

DELIMITER ;


-- 3. Напишите хранимую функцию для вычисления произвольного числа Фибоначчи. 
-- Числами Фибоначчи называется последовательность в которой число равно 
-- сумме двух предыдущих чисел. Вызов функции FIBONACCI(10) должен возвращать число 55.

DROP FUNCTION IF EXISTS fibo;

DELIMITER $$
USE `test`$$

CREATE FUNCTION fibo(num INT)
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE sum INT DEFAULT 1;
    DECLARE pre_sum INT DEFAULT 0;
    DECLARE i INT DEFAULT 2;
    CASE num
		WHEN 0 THEN SET sum = 0;
		WHEN 1 THEN SET sum = 1;
		ELSE
            WHILE i <= num DO
                SET sum = sum + pre_sum;
                SET pre_sum = sum - pre_sum;
				SET i = i + 1;
			END WHILE;
	END CASE;
	RETURN sum;
END $$

DELIMITER ;

SELECT fibo(2); -- 1
SELECT fibo(3); -- 2
SELECT fibo(4); -- 3
SELECT fibo(5); -- 5
SELECT fibo(6); -- 8
SELECT fibo(7); -- 13
SELECT fibo(8); -- 21
SELECT fibo(10); -- 55
