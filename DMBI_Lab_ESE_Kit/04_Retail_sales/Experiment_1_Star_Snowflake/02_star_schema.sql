-- ========================================================================
-- EXPERIMENT 1 - STEP 2 : STAR SCHEMA  [Retail_sales]
-- Fact  : fact_sales   (grain: One row per sales transaction.)
-- Dims  : dim_date, dim_customer, dim_product_category
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_retail_sales_star` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_retail_sales_star`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_sales`;
DROP TABLE IF EXISTS `dim_customer`;
DROP TABLE IF EXISTS `dim_product_category`;
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

CREATE TABLE `dim_customer` (
  `customer_key` INT NOT NULL AUTO_INCREMENT,
  `customer_id` VARCHAR(100) NULL,
  `gender` VARCHAR(100) NULL,
  `age` INT NULL,
  `age_group` VARCHAR(20) NULL,
  PRIMARY KEY (`customer_key`),
  UNIQUE KEY `uq_dim_customer` (`customer_id`, `gender`, `age`, `age_group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_product_category` (
  `product_category_key` INT NOT NULL AUTO_INCREMENT,
  `product_category` VARCHAR(100) NULL,
  PRIMARY KEY (`product_category_key`),
  UNIQUE KEY `uq_dim_product_category` (`product_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_sales` (
  `fact_sales_key` BIGINT NOT NULL AUTO_INCREMENT,
  `date_key` INT NULL,
  `customer_key` INT NULL,
  `product_category_key` INT NULL,
  `transaction_id` BIGINT NULL,
  `quantity` INT NULL,
  `price_per_unit` DECIMAL(18,2) NULL,
  `total_amount` DECIMAL(18,2) NULL,
  PRIMARY KEY (`fact_sales_key`),
  CONSTRAINT `fk_fact_sales_date_key` FOREIGN KEY (`date_key`) REFERENCES `dim_date` (`date_key`),
  CONSTRAINT `fk_fact_sales_customer_key` FOREIGN KEY (`customer_key`) REFERENCES `dim_customer` (`customer_key`),
  CONSTRAINT `fk_fact_sales_product_category_key` FOREIGN KEY (`product_category_key`) REFERENCES `dim_product_category` (`product_category_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL (staging -> dimensions -> fact) -------------------------

-- NULL-safe equality (<=>) is used in the joins so rows with blanks are not lost.

-- dim_date: one row per distinct calendar date found in the data
INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_num, month_name, quarter_num, year_num)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), MONTH(d), MONTHNAME(d), QUARTER(d), YEAR(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s) x
WHERE d IS NOT NULL;

-- dim_customer
INSERT INTO `dim_customer` (`customer_id`, `gender`, `age`, `age_group`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Customer ID`), ''),
  NULLIF(TRIM(s.`Gender`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN '18-24' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '25-34' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 45 THEN '35-44' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 55 THEN '45-54' ELSE '55+' END
FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s;

-- dim_product_category
INSERT INTO `dim_product_category` (`product_category`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Product Category`), '')
FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s;

-- fact_sales : one row per source row, foreign keys looked up from the dimensions
INSERT INTO `fact_sales` (`date_key`, `customer_key`, `product_category_key`, `transaction_id`, `quantity`, `price_per_unit`, `total_amount`)
SELECT
  CAST(DATE_FORMAT(DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')), '%Y%m%d') AS UNSIGNED),
  d1.`customer_key`,
  d2.`product_category_key`,
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Transaction ID`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Quantity`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price per Unit`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total Amount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))
FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s
LEFT JOIN `dim_customer` d1 ON d1.`customer_id` <=> NULLIF(TRIM(s.`Customer ID`), '')
       AND d1.`gender` <=> NULLIF(TRIM(s.`Gender`), '')
       AND d1.`age` <=> CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
       AND d1.`age_group` <=> CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN '18-24' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '25-34' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 45 THEN '35-44' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 55 THEN '45-54' ELSE '55+' END
LEFT JOIN `dim_product_category` d2 ON d2.`product_category` <=> NULLIF(TRIM(s.`Product Category`), '');

-- ---- PART C : QUICK CHECK -------------------------------------------------
SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count FROM `fact_sales` UNION ALL SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM `dim_customer` UNION ALL SELECT 'dim_product_category' AS table_name, COUNT(*) AS row_count FROM `dim_product_category` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date`;
