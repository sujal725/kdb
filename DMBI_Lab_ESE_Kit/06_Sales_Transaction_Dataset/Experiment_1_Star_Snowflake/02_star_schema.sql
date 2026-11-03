-- ========================================================================
-- EXPERIMENT 1 - STEP 2 : STAR SCHEMA  [Sales_Transaction_Dataset]
-- Fact  : fact_sales   (grain: One row per product line within a transaction.)
-- Dims  : dim_date, dim_product, dim_customer
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_sales_transaction_star` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_sales_transaction_star`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_sales`;
DROP TABLE IF EXISTS `dim_product`;
DROP TABLE IF EXISTS `dim_customer`;
DROP TABLE IF EXISTS `dim_date`;
SET FOREIGN_KEY_CHECKS = 1;

-- ---- PART A : DDL (dimension tables, then the fact table) -------------------

CREATE TABLE `dim_date` (
  `date_key` INT NOT NULL,
  `full_date` DATE NULL,
  `day_of_month` TINYINT NULL,
  `day_name` VARCHAR(10) NULL,
  `is_weekend` TINYINT NULL,
  `month_num` TINYINT NULL,
  `month_name` VARCHAR(10) NULL,
  `quarter_num` TINYINT NULL,
  `year_num` SMALLINT NULL,
  PRIMARY KEY (`date_key`),
  UNIQUE KEY `uq_dim_date` (`full_date`)
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
  `country` VARCHAR(100) NULL,
  PRIMARY KEY (`customer_key`),
  UNIQUE KEY `uq_dim_customer` (`customer_no`, `country`)
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

-- ---- PART B : ETL (staging -> dimensions -> fact) -------------------------

-- NULL-safe equality (<=>) is used in the joins so rows with blanks are not lost.

-- dim_date: one row per distinct calendar date found in the data
INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_num, month_name, quarter_num, year_num)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), MONTH(d), MONTHNAME(d), QUARTER(d), YEAR(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')) AS d FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s) x
WHERE d IS NOT NULL;

-- dim_product
INSERT INTO `dim_product` (`product_no`, `product_name`)
SELECT DISTINCT
  NULLIF(TRIM(s.`ProductNo`), ''),
  NULLIF(TRIM(s.`ProductName`), '')
FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s;

-- dim_customer
INSERT INTO `dim_customer` (`customer_no`, `country`)
SELECT DISTINCT
  NULLIF(TRIM(s.`CustomerNo`), ''),
  NULLIF(TRIM(s.`Country`), '')
FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction` s;

-- fact_sales : one row per source row, foreign keys looked up from the dimensions
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
LEFT JOIN `dim_customer` d2 ON d2.`customer_no` <=> NULLIF(TRIM(s.`CustomerNo`), '')
       AND d2.`country` <=> NULLIF(TRIM(s.`Country`), '');

-- ---- PART C : QUICK CHECK -------------------------------------------------
SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count FROM `fact_sales` UNION ALL SELECT 'dim_product' AS table_name, COUNT(*) AS row_count FROM `dim_product` UNION ALL SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM `dim_customer` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date`;
