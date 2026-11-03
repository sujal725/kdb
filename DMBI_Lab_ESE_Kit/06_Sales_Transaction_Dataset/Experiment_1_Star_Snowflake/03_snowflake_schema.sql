-- ========================================================================
-- EXPERIMENT 1 - STEP 3 : SNOWFLAKE SCHEMA  [Sales_Transaction_Dataset]
-- Same fact table as the star schema; dimensions are NORMALISED into sub-dimensions.
-- Sub-dimensions here: dim_country; date chain dim_date > dim_month > dim_quarter > dim_year
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_sales_transaction_snow` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_sales_transaction_snow`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_sales`;
DROP TABLE IF EXISTS `dim_date`;
DROP TABLE IF EXISTS `dim_month`;
DROP TABLE IF EXISTS `dim_quarter`;
DROP TABLE IF EXISTS `dim_year`;
DROP TABLE IF EXISTS `dim_country`;
DROP TABLE IF EXISTS `dim_product`;
DROP TABLE IF EXISTS `dim_customer`;
SET FOREIGN_KEY_CHECKS = 1;

-- ---- PART A : DDL (outer-most sub-dimensions first) ---------------------------

CREATE TABLE `dim_year` (
  `year_key` INT NOT NULL,
  `year_num` SMALLINT NULL,
  PRIMARY KEY (`year_key`),
  UNIQUE KEY `uq_dim_year` (`year_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_quarter` (
  `quarter_key` INT NOT NULL,
  `quarter_num` TINYINT NULL,
  `year_key` INT NULL,
  PRIMARY KEY (`quarter_key`),
  UNIQUE KEY `uq_dim_quarter` (`quarter_num`, `year_key`),
  CONSTRAINT `fk_dim_quarter_year_key` FOREIGN KEY (`year_key`) REFERENCES `dim_year` (`year_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_month` (
  `month_key` INT NOT NULL,
  `month_num` TINYINT NULL,
  `month_name` VARCHAR(10) NULL,
  `quarter_key` INT NULL,
  PRIMARY KEY (`month_key`),
  UNIQUE KEY `uq_dim_month` (`month_num`, `quarter_key`),
  CONSTRAINT `fk_dim_month_quarter_key` FOREIGN KEY (`quarter_key`) REFERENCES `dim_quarter` (`quarter_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_date` (
  `date_key` INT NOT NULL,
  `full_date` DATE NULL,
  `day_of_month` TINYINT NULL,
  `day_name` VARCHAR(10) NULL,
  `is_weekend` TINYINT NULL,
  `month_key` INT NULL,
  PRIMARY KEY (`date_key`),
  UNIQUE KEY `uq_dim_date` (`full_date`),
  CONSTRAINT `fk_dim_date_month_key` FOREIGN KEY (`month_key`) REFERENCES `dim_month` (`month_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_country` (
  `country_key` INT NOT NULL AUTO_INCREMENT,
  `country` VARCHAR(100) NULL,
  PRIMARY KEY (`country_key`),
  UNIQUE KEY `uq_dim_country` (`country`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_product` (
  `product_key` INT NOT NULL AUTO_INCREMENT,
  `product_no` VARCHAR(100) NULL,
  `product_name` VARCHAR(100) NULL,
  PRIMARY KEY (`product_key`),
  UNIQUE KEY `uq_dim_product` (`product_no`, `product_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_customer` (
  `customer_key` INT NOT NULL AUTO_INCREMENT,
  `customer_no` VARCHAR(100) NULL,
  `country_key` INT NULL,
  PRIMARY KEY (`customer_key`),
  UNIQUE KEY `uq_dim_customer` (`customer_no`, `country_key`),
  CONSTRAINT `fk_dim_customer_country_key` FOREIGN KEY (`country_key`) REFERENCES `dim_country` (`country_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_sales` (
  `fact_sales_key` BIGINT NOT NULL AUTO_INCREMENT,
  `date_key` INT NULL,
  `product_key` INT NULL,
  `customer_key` INT NULL,
  `transaction_no` VARCHAR(100) NULL,
  `price` DECIMAL(18,2) NULL,
  `quantity` INT NULL,
  `sales_amount` DECIMAL(18,2) NULL,
  `is_cancellation` TINYINT NULL,
  PRIMARY KEY (`fact_sales_key`),
  CONSTRAINT `fk_fact_sales_date_key` FOREIGN KEY (`date_key`) REFERENCES `dim_date` (`date_key`),
  CONSTRAINT `fk_fact_sales_product_key` FOREIGN KEY (`product_key`) REFERENCES `dim_product` (`product_key`),
  CONSTRAINT `fk_fact_sales_customer_key` FOREIGN KEY (`customer_key`) REFERENCES `dim_customer` (`customer_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL ------------------------------------------------------------

-- date hierarchy: year > quarter > month > date
INSERT INTO `dim_year` (year_key, year_num)
SELECT DISTINCT YEAR(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')) AS d FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_quarter` (quarter_key, quarter_num, year_key)
SELECT DISTINCT YEAR(d) * 10 + QUARTER(d), QUARTER(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')) AS d FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_month` (month_key, month_num, month_name, quarter_key)
SELECT DISTINCT YEAR(d) * 100 + MONTH(d), MONTH(d), MONTHNAME(d), YEAR(d) * 10 + QUARTER(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')) AS d FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_key)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), YEAR(d) * 100 + MONTH(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')) AS d FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s) x WHERE d IS NOT NULL;

-- dim_country
INSERT INTO `dim_country` (`country`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Country`), '')
FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s;

-- dim_product
INSERT INTO `dim_product` (`product_no`, `product_name`)
SELECT DISTINCT
  NULLIF(TRIM(s.`ProductNo`), ''),
  NULLIF(TRIM(s.`ProductName`), '')
FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s;

-- dim_customer
INSERT INTO `dim_customer` (`customer_no`, `country_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`CustomerNo`), ''),
  x1.`country_key`
FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s
LEFT JOIN `dim_country` x1 ON x1.`country` <=> NULLIF(TRIM(s.`Country`), '');

-- fact_sales
INSERT INTO `fact_sales` (`date_key`, `product_key`, `customer_key`, `transaction_no`, `price`, `quantity`, `sales_amount`, `is_cancellation`)
SELECT
  CAST(DATE_FORMAT(DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')), '%Y%m%d') AS UNSIGNED),
  d1.`product_key`,
  d2.`customer_key`,
  NULLIF(TRIM(s.`TransactionNo`), ''),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Quantity`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) * (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Quantity`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)),
  CASE WHEN (NULLIF(TRIM(s.`TransactionNo`), '')) LIKE 'C%' THEN 1 ELSE 0 END
FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s
LEFT JOIN `dim_product` d1 ON d1.`product_no` <=> NULLIF(TRIM(s.`ProductNo`), '')
       AND d1.`product_name` <=> NULLIF(TRIM(s.`ProductName`), '')
LEFT JOIN `dim_country` x1 ON x1.`country` <=> NULLIF(TRIM(s.`Country`), '')
LEFT JOIN `dim_customer` d2 ON d2.`customer_no` <=> NULLIF(TRIM(s.`CustomerNo`), '')
       AND d2.`country_key` <=> x1.`country_key`;

-- ---- PART C : QUICK CHECK ------------------------------------------------------
SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count FROM `fact_sales` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date` UNION ALL SELECT 'dim_month' AS table_name, COUNT(*) AS row_count FROM `dim_month` UNION ALL SELECT 'dim_quarter' AS table_name, COUNT(*) AS row_count FROM `dim_quarter` UNION ALL SELECT 'dim_year' AS table_name, COUNT(*) AS row_count FROM `dim_year` UNION ALL SELECT 'dim_country' AS table_name, COUNT(*) AS row_count FROM `dim_country` UNION ALL SELECT 'dim_product' AS table_name, COUNT(*) AS row_count FROM `dim_product` UNION ALL SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM `dim_customer`;
