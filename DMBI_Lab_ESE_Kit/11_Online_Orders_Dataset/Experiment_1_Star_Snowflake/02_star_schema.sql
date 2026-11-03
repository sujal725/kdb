-- ========================================================================
-- EXPERIMENT 1 - STEP 2 : STAR SCHEMA  [Online_Orders_Dataset]
-- Fact  : fact_orders   (grain: One row per online order line.)
-- Dims  : dim_date, dim_product, dim_region, dim_payment_method
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_online_orders_star` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_online_orders_star`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_orders`;
DROP TABLE IF EXISTS `dim_product`;
DROP TABLE IF EXISTS `dim_region`;
DROP TABLE IF EXISTS `dim_payment_method`;
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
  `product_name` VARCHAR(100) NULL,
  `product_category` VARCHAR(100) NULL,
  PRIMARY KEY (`product_key`),
  UNIQUE KEY `uq_dim_product` (`product_name`, `product_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_region` (
  `region_key` INT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(100) NULL,
  PRIMARY KEY (`region_key`),
  UNIQUE KEY `uq_dim_region` (`region`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_payment_method` (
  `payment_method_key` INT NOT NULL AUTO_INCREMENT,
  `payment_method` VARCHAR(100) NULL,
  PRIMARY KEY (`payment_method_key`),
  UNIQUE KEY `uq_dim_payment_method` (`payment_method`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_orders` (
  `fact_orders_key` BIGINT NOT NULL AUTO_INCREMENT,
  `date_key` INT NULL,
  `product_key` INT NULL,
  `region_key` INT NULL,
  `payment_method_key` INT NULL,
  `transaction_id` BIGINT NULL,
  `units_sold` INT NULL,
  `unit_price` DECIMAL(18,2) NULL,
  `total_revenue` DECIMAL(18,2) NULL,
  PRIMARY KEY (`fact_orders_key`),
  CONSTRAINT `fk_fact_orders_date_key` FOREIGN KEY (`date_key`) REFERENCES `dim_date` (`date_key`),
  CONSTRAINT `fk_fact_orders_product_key` FOREIGN KEY (`product_key`) REFERENCES `dim_product` (`product_key`),
  CONSTRAINT `fk_fact_orders_region_key` FOREIGN KEY (`region_key`) REFERENCES `dim_region` (`region_key`),
  CONSTRAINT `fk_fact_orders_payment_method_key` FOREIGN KEY (`payment_method_key`) REFERENCES `dim_payment_method` (`payment_method_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL (staging -> dimensions -> fact) -------------------------

-- NULL-safe equality (<=>) is used in the joins so rows with blanks are not lost.

-- dim_date: one row per distinct calendar date found in the data
INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_num, month_name, quarter_num, year_num)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), MONTH(d), MONTHNAME(d), QUARTER(d), YEAR(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_online_orders_stg`.`stg_online_orders` s) x
WHERE d IS NOT NULL;

-- dim_product
INSERT INTO `dim_product` (`product_name`, `product_category`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Product Name`), ''),
  NULLIF(TRIM(s.`Product Category`), '')
FROM `dmbi_online_orders_stg`.`stg_online_orders` s;

-- dim_region
INSERT INTO `dim_region` (`region`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Region`), '')
FROM `dmbi_online_orders_stg`.`stg_online_orders` s;

-- dim_payment_method
INSERT INTO `dim_payment_method` (`payment_method`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Payment Method`), '')
FROM `dmbi_online_orders_stg`.`stg_online_orders` s;

-- fact_orders : one row per source row, foreign keys looked up from the dimensions
INSERT INTO `fact_orders` (`date_key`, `product_key`, `region_key`, `payment_method_key`, `transaction_id`, `units_sold`, `unit_price`, `total_revenue`)
SELECT
  CAST(DATE_FORMAT(DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')), '%Y%m%d') AS UNSIGNED),
  d1.`product_key`,
  d2.`region_key`,
  d3.`payment_method_key`,
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Transaction ID`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Unit Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total Revenue`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))
FROM `dmbi_online_orders_stg`.`stg_online_orders` s
LEFT JOIN `dim_product` d1 ON d1.`product_name` <=> NULLIF(TRIM(s.`Product Name`), '')
       AND d1.`product_category` <=> NULLIF(TRIM(s.`Product Category`), '')
LEFT JOIN `dim_region` d2 ON d2.`region` <=> NULLIF(TRIM(s.`Region`), '')
LEFT JOIN `dim_payment_method` d3 ON d3.`payment_method` <=> NULLIF(TRIM(s.`Payment Method`), '');

-- ---- PART C : QUICK CHECK -------------------------------------------------
SELECT 'fact_orders' AS table_name, COUNT(*) AS row_count FROM `fact_orders` UNION ALL SELECT 'dim_product' AS table_name, COUNT(*) AS row_count FROM `dim_product` UNION ALL SELECT 'dim_region' AS table_name, COUNT(*) AS row_count FROM `dim_region` UNION ALL SELECT 'dim_payment_method' AS table_name, COUNT(*) AS row_count FROM `dim_payment_method` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date`;
