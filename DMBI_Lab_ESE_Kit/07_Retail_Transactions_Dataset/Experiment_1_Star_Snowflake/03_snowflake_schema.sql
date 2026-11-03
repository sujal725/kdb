-- ========================================================================
-- EXPERIMENT 1 - STEP 3 : SNOWFLAKE SCHEMA  [Retail_Transactions_Dataset]
-- Same fact table as the star schema; dimensions are NORMALISED into sub-dimensions.
-- Sub-dimensions here: dim_customer_category, dim_city; date chain dim_date > dim_month > dim_quarter > dim_year
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_retail_transactions_snow` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_retail_transactions_snow`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_transactions`;
DROP TABLE IF EXISTS `dim_date`;
DROP TABLE IF EXISTS `dim_month`;
DROP TABLE IF EXISTS `dim_quarter`;
DROP TABLE IF EXISTS `dim_year`;
DROP TABLE IF EXISTS `dim_customer_category`;
DROP TABLE IF EXISTS `dim_city`;
DROP TABLE IF EXISTS `dim_customer`;
DROP TABLE IF EXISTS `dim_store`;
DROP TABLE IF EXISTS `dim_payment_method`;
DROP TABLE IF EXISTS `dim_season`;
DROP TABLE IF EXISTS `dim_promotion`;
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

CREATE TABLE `dim_customer_category` (
  `customer_category_key` INT NOT NULL AUTO_INCREMENT,
  `customer_category` VARCHAR(100) NULL,
  PRIMARY KEY (`customer_category_key`),
  UNIQUE KEY `uq_dim_customer_category` (`customer_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_city` (
  `city_key` INT NOT NULL AUTO_INCREMENT,
  `city` VARCHAR(100) NULL,
  PRIMARY KEY (`city_key`),
  UNIQUE KEY `uq_dim_city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_customer` (
  `customer_key` INT NOT NULL AUTO_INCREMENT,
  `customer_name` VARCHAR(100) NULL,
  `customer_category_key` INT NULL,
  PRIMARY KEY (`customer_key`),
  UNIQUE KEY `uq_dim_customer` (`customer_name`, `customer_category_key`),
  CONSTRAINT `fk_dim_customer_customer_category_key` FOREIGN KEY (`customer_category_key`) REFERENCES `dim_customer_category` (`customer_category_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_store` (
  `store_key` INT NOT NULL AUTO_INCREMENT,
  `store_type` VARCHAR(100) NULL,
  `city_key` INT NULL,
  PRIMARY KEY (`store_key`),
  UNIQUE KEY `uq_dim_store` (`store_type`, `city_key`),
  CONSTRAINT `fk_dim_store_city_key` FOREIGN KEY (`city_key`) REFERENCES `dim_city` (`city_key`)
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

-- ---- PART B : ETL ------------------------------------------------------------

-- date hierarchy: year > quarter > month > date
INSERT INTO `dim_year` (year_key, year_num)
SELECT DISTINCT YEAR(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d %H:%i:%s')) AS d FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_quarter` (quarter_key, quarter_num, year_key)
SELECT DISTINCT YEAR(d) * 10 + QUARTER(d), QUARTER(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d %H:%i:%s')) AS d FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_month` (month_key, month_num, month_name, quarter_key)
SELECT DISTINCT YEAR(d) * 100 + MONTH(d), MONTH(d), MONTHNAME(d), YEAR(d) * 10 + QUARTER(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d %H:%i:%s')) AS d FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_key)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), YEAR(d) * 100 + MONTH(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d %H:%i:%s')) AS d FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s) x WHERE d IS NOT NULL;

-- dim_customer_category
INSERT INTO `dim_customer_category` (`customer_category`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Customer_Category`), '')
FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s;

-- dim_city
INSERT INTO `dim_city` (`city`)
SELECT DISTINCT
  NULLIF(TRIM(s.`City`), '')
FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s;

-- dim_customer
INSERT INTO `dim_customer` (`customer_name`, `customer_category_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Customer_Name`), ''),
  x1.`customer_category_key`
FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s
LEFT JOIN `dim_customer_category` x1 ON x1.`customer_category` <=> NULLIF(TRIM(s.`Customer_Category`), '');

-- dim_store
INSERT INTO `dim_store` (`store_type`, `city_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Store_Type`), ''),
  x1.`city_key`
FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions` s
LEFT JOIN `dim_city` x1 ON x1.`city` <=> NULLIF(TRIM(s.`City`), '');

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

-- fact_transactions
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
LEFT JOIN `dim_customer_category` x1 ON x1.`customer_category` <=> NULLIF(TRIM(s.`Customer_Category`), '')
LEFT JOIN `dim_customer` d1 ON d1.`customer_name` <=> NULLIF(TRIM(s.`Customer_Name`), '')
       AND d1.`customer_category_key` <=> x1.`customer_category_key`
LEFT JOIN `dim_city` x2 ON x2.`city` <=> NULLIF(TRIM(s.`City`), '')
LEFT JOIN `dim_store` d2 ON d2.`store_type` <=> NULLIF(TRIM(s.`Store_Type`), '')
       AND d2.`city_key` <=> x2.`city_key`
LEFT JOIN `dim_payment_method` d3 ON d3.`payment_method` <=> NULLIF(TRIM(s.`Payment_Method`), '')
LEFT JOIN `dim_season` d4 ON d4.`season` <=> NULLIF(TRIM(s.`Season`), '')
LEFT JOIN `dim_promotion` d5 ON d5.`promotion` <=> NULLIF(TRIM(s.`Promotion`), '');

-- ---- PART C : QUICK CHECK ------------------------------------------------------
SELECT 'fact_transactions' AS table_name, COUNT(*) AS row_count FROM `fact_transactions` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date` UNION ALL SELECT 'dim_month' AS table_name, COUNT(*) AS row_count FROM `dim_month` UNION ALL SELECT 'dim_quarter' AS table_name, COUNT(*) AS row_count FROM `dim_quarter` UNION ALL SELECT 'dim_year' AS table_name, COUNT(*) AS row_count FROM `dim_year` UNION ALL SELECT 'dim_customer_category' AS table_name, COUNT(*) AS row_count FROM `dim_customer_category` UNION ALL SELECT 'dim_city' AS table_name, COUNT(*) AS row_count FROM `dim_city` UNION ALL SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM `dim_customer` UNION ALL SELECT 'dim_store' AS table_name, COUNT(*) AS row_count FROM `dim_store` UNION ALL SELECT 'dim_payment_method' AS table_name, COUNT(*) AS row_count FROM `dim_payment_method` UNION ALL SELECT 'dim_season' AS table_name, COUNT(*) AS row_count FROM `dim_season` UNION ALL SELECT 'dim_promotion' AS table_name, COUNT(*) AS row_count FROM `dim_promotion`;
