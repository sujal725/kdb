-- ========================================================================
-- EXPERIMENT 1 - STEP 3 : SNOWFLAKE SCHEMA  [Online_Orders_Dataset]
-- Same fact table as the star schema; dimensions are NORMALISED into sub-dimensions.
-- Sub-dimensions here: dim_product_category; date chain dim_date > dim_month > dim_quarter > dim_year
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_online_orders_snow` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_online_orders_snow`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_orders`;
DROP TABLE IF EXISTS `dim_date`;
DROP TABLE IF EXISTS `dim_month`;
DROP TABLE IF EXISTS `dim_quarter`;
DROP TABLE IF EXISTS `dim_year`;
DROP TABLE IF EXISTS `dim_product_category`;
DROP TABLE IF EXISTS `dim_product`;
DROP TABLE IF EXISTS `dim_region`;
DROP TABLE IF EXISTS `dim_payment_method`;
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

CREATE TABLE `dim_product_category` (
  `product_category_key` INT NOT NULL AUTO_INCREMENT,
  `product_category` VARCHAR(100) NULL,
  PRIMARY KEY (`product_category_key`),
  UNIQUE KEY `uq_dim_product_category` (`product_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_product` (
  `product_key` INT NOT NULL AUTO_INCREMENT,
  `product_name` VARCHAR(100) NULL,
  `product_category_key` INT NULL,
  PRIMARY KEY (`product_key`),
  UNIQUE KEY `uq_dim_product` (`product_name`, `product_category_key`),
  CONSTRAINT `fk_dim_product_product_category_key` FOREIGN KEY (`product_category_key`) REFERENCES `dim_product_category` (`product_category_key`)
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

-- ---- PART B : ETL ------------------------------------------------------------

-- date hierarchy: year > quarter > month > date
INSERT INTO `dim_year` (year_key, year_num)
SELECT DISTINCT YEAR(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_online_orders_stg`.`stg_online_orders` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_quarter` (quarter_key, quarter_num, year_key)
SELECT DISTINCT YEAR(d) * 10 + QUARTER(d), QUARTER(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_online_orders_stg`.`stg_online_orders` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_month` (month_key, month_num, month_name, quarter_key)
SELECT DISTINCT YEAR(d) * 100 + MONTH(d), MONTH(d), MONTHNAME(d), YEAR(d) * 10 + QUARTER(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_online_orders_stg`.`stg_online_orders` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_key)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), YEAR(d) * 100 + MONTH(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_online_orders_stg`.`stg_online_orders` s) x WHERE d IS NOT NULL;

-- dim_product_category
INSERT INTO `dim_product_category` (`product_category`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Product Category`), '')
FROM `dmbi_online_orders_stg`.`stg_online_orders` s;

-- dim_product
INSERT INTO `dim_product` (`product_name`, `product_category_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Product Name`), ''),
  x1.`product_category_key`
FROM `dmbi_online_orders_stg`.`stg_online_orders` s
LEFT JOIN `dim_product_category` x1 ON x1.`product_category` <=> NULLIF(TRIM(s.`Product Category`), '');

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

-- fact_orders
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
LEFT JOIN `dim_product_category` x1 ON x1.`product_category` <=> NULLIF(TRIM(s.`Product Category`), '')
LEFT JOIN `dim_product` d1 ON d1.`product_name` <=> NULLIF(TRIM(s.`Product Name`), '')
       AND d1.`product_category_key` <=> x1.`product_category_key`
LEFT JOIN `dim_region` d2 ON d2.`region` <=> NULLIF(TRIM(s.`Region`), '')
LEFT JOIN `dim_payment_method` d3 ON d3.`payment_method` <=> NULLIF(TRIM(s.`Payment Method`), '');

-- ---- PART C : QUICK CHECK ------------------------------------------------------
SELECT 'fact_orders' AS table_name, COUNT(*) AS row_count FROM `fact_orders` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date` UNION ALL SELECT 'dim_month' AS table_name, COUNT(*) AS row_count FROM `dim_month` UNION ALL SELECT 'dim_quarter' AS table_name, COUNT(*) AS row_count FROM `dim_quarter` UNION ALL SELECT 'dim_year' AS table_name, COUNT(*) AS row_count FROM `dim_year` UNION ALL SELECT 'dim_product_category' AS table_name, COUNT(*) AS row_count FROM `dim_product_category` UNION ALL SELECT 'dim_product' AS table_name, COUNT(*) AS row_count FROM `dim_product` UNION ALL SELECT 'dim_region' AS table_name, COUNT(*) AS row_count FROM `dim_region` UNION ALL SELECT 'dim_payment_method' AS table_name, COUNT(*) AS row_count FROM `dim_payment_method`;
