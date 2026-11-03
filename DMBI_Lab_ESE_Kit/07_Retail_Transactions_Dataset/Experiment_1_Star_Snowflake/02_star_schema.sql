-- ========================================================================
-- EXPERIMENT 1 - STEP 2 : STAR SCHEMA  [Retail_Transactions_Dataset]
-- Fact  : fact_transactions   (grain: One row per basket / transaction.)
-- Dims  : dim_date, dim_customer, dim_store, dim_payment_method, dim_season, dim_promotion
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_retail_transactions_star` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_retail_transactions_star`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_transactions`;
DROP TABLE IF EXISTS `dim_customer`;
DROP TABLE IF EXISTS `dim_store`;
DROP TABLE IF EXISTS `dim_payment_method`;
DROP TABLE IF EXISTS `dim_season`;
DROP TABLE IF EXISTS `dim_promotion`;
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
  `customer_name` VARCHAR(100) NULL,
  `customer_category` VARCHAR(100) NULL,
  PRIMARY KEY (`customer_key`),
  UNIQUE KEY `uq_dim_customer` (`customer_name`, `customer_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_store` (
  `store_key` INT NOT NULL AUTO_INCREMENT,
  `city` VARCHAR(100) NULL,
  `store_type` VARCHAR(100) NULL,
  PRIMARY KEY (`store_key`),
  UNIQUE KEY `uq_dim_store` (`city`, `store_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_payment_method` (
  `payment_method_key` INT NOT NULL AUTO_INCREMENT,
  `payment_method` VARCHAR(100) NULL,
  PRIMARY KEY (`payment_method_key`),
  UNIQUE KEY `uq_dim_payment_method` (`payment_method`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_season` (
  `season_key` INT NOT NULL AUTO_INCREMENT,
  `season` VARCHAR(100) NULL,
  PRIMARY KEY (`season_key`),
  UNIQUE KEY `uq_dim_season` (`season`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_promotion` (
  `promotion_key` INT NOT NULL AUTO_INCREMENT,
  `promotion` VARCHAR(100) NULL,
  PRIMARY KEY (`promotion_key`),
  UNIQUE KEY `uq_dim_promotion` (`promotion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_transactions` (
  `fact_transactions_key` BIGINT NOT NULL AUTO_INCREMENT,
  `date_key` INT NULL,
  `customer_key` INT NULL,
  `store_key` INT NULL,
  `payment_method_key` INT NULL,
  `season_key` INT NULL,
  `promotion_key` INT NULL,
  `transaction_id` BIGINT NULL,
  `product` VARCHAR(500) NULL,
  `total_items` INT NULL,
  `total_cost` DECIMAL(18,2) NULL,
  `discount_applied` TINYINT NULL,
  `avg_item_cost` DECIMAL(15,2) NULL,
  PRIMARY KEY (`fact_transactions_key`),
  CONSTRAINT `fk_fact_transactions_date_key` FOREIGN KEY (`date_key`) REFERENCES `dim_date` (`date_key`),
  CONSTRAINT `fk_fact_transactions_customer_key` FOREIGN KEY (`customer_key`) REFERENCES `dim_customer` (`customer_key`),
  CONSTRAINT `fk_fact_transactions_store_key` FOREIGN KEY (`store_key`) REFERENCES `dim_store` (`store_key`),
  CONSTRAINT `fk_fact_transactions_payment_method_key` FOREIGN KEY (`payment_method_key`) REFERENCES `dim_payment_method` (`payment_method_key`),
  CONSTRAINT `fk_fact_transactions_season_key` FOREIGN KEY (`season_key`) REFERENCES `dim_season` (`season_key`),
  CONSTRAINT `fk_fact_transactions_promotion_key` FOREIGN KEY (`promotion_key`) REFERENCES `dim_promotion` (`promotion_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL (staging -> dimensions -> fact) -------------------------

-- NULL-safe equality (<=>) is used in the joins so rows with blanks are not lost.

-- dim_date: one row per distinct calendar date found in the data
INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_num, month_name, quarter_num, year_num)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), MONTH(d), MONTHNAME(d), QUARTER(d), YEAR(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d %H:%i:%s')) AS d FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s) x
WHERE d IS NOT NULL;

-- dim_customer
INSERT INTO `dim_customer` (`customer_name`, `customer_category`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Customer_Name`), ''),
  NULLIF(TRIM(s.`Customer_Category`), '')
FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s;

-- dim_store
INSERT INTO `dim_store` (`city`, `store_type`)
SELECT DISTINCT
  NULLIF(TRIM(s.`City`), ''),
  NULLIF(TRIM(s.`Store_Type`), '')
FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s;

-- dim_payment_method
INSERT INTO `dim_payment_method` (`payment_method`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Payment_Method`), '')
FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s;

-- dim_season
INSERT INTO `dim_season` (`season`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Season`), '')
FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s;

-- dim_promotion
INSERT INTO `dim_promotion` (`promotion`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Promotion`), '')
FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s;

-- fact_transactions : one row per source row, foreign keys looked up from the dimensions
INSERT INTO `fact_transactions` (`date_key`, `customer_key`, `store_key`, `payment_method_key`, `season_key`, `promotion_key`, `transaction_id`, `product`, `total_items`, `total_cost`, `discount_applied`, `avg_item_cost`)
SELECT
  CAST(DATE_FORMAT(DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d %H:%i:%s')), '%Y%m%d') AS UNSIGNED),
  d1.`customer_key`,
  d2.`store_key`,
  d3.`payment_method_key`,
  d4.`season_key`,
  d5.`promotion_key`,
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Transaction_ID`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`Product`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total_Items`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total_Cost`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CASE WHEN UPPER(TRIM(s.`Discount_Applied`)) IN ('YES','Y','TRUE','1') THEN 1 ELSE 0 END,
  (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total_Cost`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) / NULLIF((CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total_Items`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)), 0)
FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s
LEFT JOIN `dim_customer` d1 ON d1.`customer_name` <=> NULLIF(TRIM(s.`Customer_Name`), '')
       AND d1.`customer_category` <=> NULLIF(TRIM(s.`Customer_Category`), '')
LEFT JOIN `dim_store` d2 ON d2.`city` <=> NULLIF(TRIM(s.`City`), '')
       AND d2.`store_type` <=> NULLIF(TRIM(s.`Store_Type`), '')
LEFT JOIN `dim_payment_method` d3 ON d3.`payment_method` <=> NULLIF(TRIM(s.`Payment_Method`), '')
LEFT JOIN `dim_season` d4 ON d4.`season` <=> NULLIF(TRIM(s.`Season`), '')
LEFT JOIN `dim_promotion` d5 ON d5.`promotion` <=> NULLIF(TRIM(s.`Promotion`), '');

-- ---- PART C : QUICK CHECK -------------------------------------------------
SELECT 'fact_transactions' AS table_name, COUNT(*) AS row_count FROM `fact_transactions` UNION ALL SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM `dim_customer` UNION ALL SELECT 'dim_store' AS table_name, COUNT(*) AS row_count FROM `dim_store` UNION ALL SELECT 'dim_payment_method' AS table_name, COUNT(*) AS row_count FROM `dim_payment_method` UNION ALL SELECT 'dim_season' AS table_name, COUNT(*) AS row_count FROM `dim_season` UNION ALL SELECT 'dim_promotion' AS table_name, COUNT(*) AS row_count FROM `dim_promotion` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date`;
