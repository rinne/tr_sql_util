-- 
-- Copyright © Timo J. Rinne <tri@iki.fi>
-- 
-- This set of tools is licensed under the terms
-- of MIT License as expressed in the file COPYING
-- in the root directory of this repository.
-- 

CREATE DATABASE IF NOT EXISTS TR_UTIL;
ALTER DATABASE TR_UTIL DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_general_ci';

USE TR_UTIL;

DROP FUNCTION IF EXISTS ID_ENCODE;

DELIMITER //

CREATE FUNCTION ID_ENCODE(num BIGINT, vocabulary TEXT, salt TEXT, minlen INTEGER)
RETURNS TEXT
DETERMINISTIC NO SQL
BEGIN
  DECLARE rv TEXT DEFAULT NULL;
  DECLARE v TEXT DEFAULT NULL;
  DECLARE n BIGINT DEFAULT NULL;
  DECLARE r BIGINT DEFAULT NULL;
  DECLARE i BIGINT DEFAULT NULL;
  DECLARE m BIGINT DEFAULT NULL;
  IF num < 0 THEN
    RETURN NULL;
  END IF;
  SET rv = '';
  SET n = num;
  SET m = CHAR_LENGTH(vocabulary);
  SET i = 0;
  SET v = STR_SHUFFLE(vocabulary, salt);
  WHILE n > 0 OR CHAR_LENGTH(rv) < minlen DO
    SET i = i + 1;
    SET r = n % m;
    SET n = (n - r) / m;
    SET rv = CONCAT(SUBSTRING(v, r + 1, 1), rv);
    SET v = STR_SHUFFLE(v, CONCAT(salt, ':', r, ':', i));
  END WHILE;
  RETURN rv;
END; //

DELIMITER ;


DROP FUNCTION IF EXISTS ID_DECODE;

DELIMITER //

CREATE FUNCTION ID_DECODE(str TEXT, vocabulary TEXT, salt TEXT)
RETURNS BIGINT
DETERMINISTIC NO SQL
BEGIN
  DECLARE rv BIGINT DEFAULT NULL;
  DECLARE v TEXT DEFAULT NULL;
  DECLARE r BIGINT DEFAULT NULL;
  DECLARE i BIGINT DEFAULT NULL;
  DECLARE m BIGINT DEFAULT NULL;
  DECLARE s TEXT DEFAULT NULL;
  DECLARE f BIGINT DEFAULT NULL;
  SET rv = 0;
  SET f = 1;
  SET s = str;
  SET m = CHAR_LENGTH(vocabulary);
  SET i = 0;
  SET v = STR_SHUFFLE(vocabulary, salt);
  WHILE CHAR_LENGTH(s) > 0 DO
    SET r = LOCATE(SUBSTRING(s, CHAR_LENGTH(s), 1), v);
    IF r > 0 THEN
      SET r = r - 1;
      SET rv = rv + (r * f);
      SET f = f * m;
      SET i = i + 1;
      SET v = STR_SHUFFLE(v, CONCAT(salt, ':', r, ':', i));
    END IF;
    SET s = SUBSTRING(s, 1, CHAR_LENGTH(s) - 1);
  END WHILE;
  RETURN rv;
END; //

DELIMITER ;


DROP FUNCTION IF EXISTS ID_PRETTY;

DELIMITER //

CREATE FUNCTION ID_PRETTY(num BIGINT)
RETURNS TEXT
DETERMINISTIC NO SQL
BEGIN
  DECLARE rv TEXT DEFAULT NULL;
  SET rv = ID_ENCODE(num, '123456789', 'ID', 9);
  IF CHAR_LENGTH(rv) = 9 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 3), '-', SUBSTRING(rv, 4, 3), '-', SUBSTRING(rv, 7, 3));
  ELSEIF CHAR_LENGTH(rv) = 10 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 3), '-', SUBSTRING(rv, 4, 4), '-', SUBSTRING(rv, 8, 3));
  ELSEIF CHAR_LENGTH(rv) = 11 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 4), '-', SUBSTRING(rv, 5, 3), '-', SUBSTRING(rv, 8, 4));
  ELSEIF CHAR_LENGTH(rv) = 12 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 4), '-', SUBSTRING(rv, 5, 4), '-', SUBSTRING(rv, 9, 4));
  ELSEIF CHAR_LENGTH(rv) = 13 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 4), '-', SUBSTRING(rv, 5, 5), '-', SUBSTRING(rv, 10, 4));
  ELSEIF CHAR_LENGTH(rv) = 14 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 5), '-', SUBSTRING(rv, 6, 4), '-', SUBSTRING(rv, 10, 5));
  ELSEIF CHAR_LENGTH(rv) = 15 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 5), '-', SUBSTRING(rv, 6, 5), '-', SUBSTRING(rv, 11, 5));
  ELSEIF CHAR_LENGTH(rv) = 16 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 5), '-', SUBSTRING(rv, 6, 6), '-', SUBSTRING(rv, 12, 5));
  ELSEIF CHAR_LENGTH(rv) = 17 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 6), '-', SUBSTRING(rv, 7, 5), '-', SUBSTRING(rv, 12, 6));
  ELSEIF CHAR_LENGTH(rv) = 18 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 6), '-', SUBSTRING(rv, 7, 6), '-', SUBSTRING(rv, 13, 6));
  ELSEIF CHAR_LENGTH(rv) = 19 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 6), '-', SUBSTRING(rv, 7, 7), '-', SUBSTRING(rv, 14, 6));
  ELSEIF CHAR_LENGTH(rv) = 20 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 7), '-', SUBSTRING(rv, 8, 6), '-', SUBSTRING(rv, 14, 7));
  ELSEIF CHAR_LENGTH(rv) = 21 THEN
    SET rv = CONCAT(SUBSTRING(rv, 1, 7), '-', SUBSTRING(rv, 8, 7), '-', SUBSTRING(rv, 15, 7));
  END IF;
  RETURN rv;
END; //

DELIMITER ;


DROP FUNCTION IF EXISTS ID_SAFE;

DELIMITER //

CREATE FUNCTION ID_SAFE(num BIGINT, salt TEXT)
RETURNS TEXT
DETERMINISTIC NO SQL
BEGIN
  DECLARE rv TEXT DEFAULT NULL;
  DECLARE v TEXT DEFAULT NULL;
  DECLARE e TEXT DEFAULT NULL;
  DECLARE c TEXT DEFAULT NULL;
  IF num < 0 THEN
    RETURN NULL;
  END IF;
  SET v = 'bcdfghjkmnpqrstvwxyz';
  SET e = ID_ENCODE(num, v, CONCAT('ID_SAFE1:', salt), 8);
  SET c = SUBSTRING(ID_ENCODE(STR_CRC(e,
                                      CONCAT('ID_SAFE2:', salt),
                                      POW(CHAR_LENGTH(v), 8) - 1),
                              v,
                              CONCAT('ID_SAFE2:', salt),
                              8),
                    1, 8);
  SET rv = CONCAT(e, c);
  RETURN rv;
END; //

DELIMITER ;


DROP FUNCTION IF EXISTS ID_SAFE_DECODE;

DELIMITER //

CREATE FUNCTION ID_SAFE_DECODE(str TEXT, salt TEXT)
RETURNS BIGINT
DETERMINISTIC NO SQL
BEGIN
  DECLARE v TEXT DEFAULT NULL;
  DECLARE e TEXT DEFAULT NULL;
  DECLARE c TEXT DEFAULT NULL;
  DECLARE d TEXT DEFAULT NULL;
  DECLARE rv BIGINT DEFAULT NULL;
  IF CHAR_LENGTH(str) < 16 THEN
    RETURN NULL;
  END IF;
  SET v = 'bcdfghjkmnpqrstvwxyz';
  SET e = SUBSTRING(str, 1, CHAR_LENGTH(str) - 8);
  SET d = SUBSTRING(str, CHAR_LENGTH(str) - 7);
  SET c = SUBSTRING(ID_ENCODE(STR_CRC(e,
                                      CONCAT('ID_SAFE2:', salt),
                                      POW(CHAR_LENGTH(v), 8) - 1),
                              v,
                              CONCAT('ID_SAFE2:', salt),
                              8),
                    1, 8);
  IF c <> d THEN
    RETURN NULL;
  END IF;
  SET rv = ID_DECODE(e, v, CONCAT('ID_SAFE1:', salt));
  RETURN rv;
END; //

DELIMITER ;
