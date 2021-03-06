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


DROP FUNCTION IF EXISTS STR_RND;

DELIMITER //

CREATE FUNCTION STR_RND(len INTEGER, salt TEXT)
RETURNS BLOB
DETERMINISTIC NO SQL
COMMENT 'STR_RND(<len>, <string>)'
BEGIN
  DECLARE rv BLOB DEFAULT '';
  DECLARE ctr INTEGER DEFAULT 0;
  DECLARE s BLOB DEFAULT NULL;
  DECLARE k BLOB DEFAULT NULL;
  SET k = UNHEX(MD5(salt));
  WHILE LENGTH(rv) < len DO
    SET s = AES_ENCRYPT(UNHEX(MD5(CONCAT(salt, ':', ctr))), k);
    SET rv = CONCAT(rv, s);
    SET ctr = ctr + 1;
  END WHILE;
  IF LENGTH(rv) > len THEN
    SET rv = SUBSTRING(rv, 1, len);
  END IF;
  return rv;
END; //

DELIMITER ;


DROP FUNCTION IF EXISTS STR_SWAP;

DELIMITER //

CREATE FUNCTION STR_SWAP(str TEXT, pos1 INTEGER, pos2 INTEGER)
RETURNS TEXT
DETERMINISTIC NO SQL
COMMENT 'STR_SWAP(<string>, <position1>, <position2>)'
BEGIN
  DECLARE rv TEXT DEFAULT NULL;
  DECLARE a INTEGER DEFAULT NULL;
  DECLARE b INTEGER DEFAULT NULL;
  IF CHAR_LENGTH(str) < 2 OR pos1 < 0 OR pos2 < 0 THEN
    RETURN str;
  END IF;
  SET a = LEAST(pos1 % CHAR_LENGTH(str), pos2 % CHAR_LENGTH(str)) + 1;
  SET b = GREATEST(pos1 % CHAR_LENGTH(str), pos2 % CHAR_LENGTH(str)) + 1;
  IF a <> b THEN
    SET rv = CONCAT(SUBSTRING(str, 1, a - 1),
                    SUBSTRING(str, b, 1),
                    SUBSTRING(str, a + 1, b - a - 1),
                    SUBSTRING(str, a, 1),
                    SUBSTRING(str, b + 1));
  ELSE
    SET rv = str;
  END IF;
  RETURN rv;
END; //

DELIMITER ;


DROP FUNCTION IF EXISTS STR_SHUFFLE;

DELIMITER //

CREATE FUNCTION STR_SHUFFLE(str TEXT, salt TEXT)
RETURNS TEXT
DETERMINISTIC NO SQL
COMMENT 'STR_SHUFFLE(<string>, <string>)'
BEGIN
  DECLARE rv TEXT DEFAULT NULL;
  DECLARE z BLOB DEFAULT NULL;
  DECLARE i INTEGER DEFAULT NULL;
  DECLARE j INTEGER DEFAULT NULL;
  IF CHAR_LENGTH(str) > 256 THEN
    RETURN NULL;
  END IF;
  SET rv = str;
  SET z = STR_RND(2 * CHAR_LENGTH(str), salt);
  SET i = 0;
  WHILE i < LENGTH(z) DO
    SET j = ASCII(SUBSTRING(z, i, 1));
    SET i = i + 1;
    SET rv = STR_SWAP(rv, i, j);
  END WHILE;
  return rv;
END; //

DELIMITER ;


DROP FUNCTION IF EXISTS STR_CRC;

DELIMITER //
CREATE FUNCTION STR_CRC(str TEXT, salt TEXT, maxval BIGINT)
RETURNS BIGINT
DETERMINISTIC NO SQL
BEGIN
  DECLARE b BLOB DEFAULT NULL;
  DECLARE rv BIGINT UNSIGNED DEFAULT 0;
  IF maxval < 1 THEN
    RETURN 0;
  END IF;
  SET b = UNHEX(SHA2(CONCAT('', LENGTH(str),':',
                            LENGTH(str), ':', str, ':',
                            LENGTH(salt), ':',salt, ':',
                            maxval),
                     512));
  WHILE LENGTH(b) > 0 DO
    SET rv = ((rv * 256) + ASCII(SUBSTRING(b, 1 ,1))) % maxval;
    SET b = SUBSTRING(b, 2);
  END WHILE;
  RETURN rv;
END; //

DELIMITER ;
