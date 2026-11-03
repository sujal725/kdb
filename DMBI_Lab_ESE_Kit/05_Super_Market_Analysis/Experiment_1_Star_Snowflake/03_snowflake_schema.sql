-- ========================================================================
-- EXPERIMENT 1 - STEP 3 : SNOWFLAKE SCHEMA  [Super_Market_Analysis]
-- Same fact table as the star schema; dimensions are NORMALISED into sub-dimensions.
-- Sub-dimensions here: dim_city, dim_gender; date chain dim_date > dim_month > dim_quarter > dim_year
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_super_market_snow` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_super_market_snow`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_sales`;
DROP TABLE IF EXISTS `dim_date`;
DROP TABLE IF EXISTS `dim_month`;
DROP TABLE IF EXISTS `dim_quarter`;
DROP TABLE IF EXISTS `dim_year`;
DROP TABLE IF EXISTS `dim_city`;
DROP TABLE IF EXISTS `dim_gender`;
DROP TABLE IF EXISTS `dim_branch`;
DROP TABLE IF EXISTS `dim_customer`;
DROP TABLE IF EXISTS `dim_product_line`;
DROP TABLE IF EXISTS `dim_payment`;
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

CREATE TABLE `dim_city` (
  `city_key` INT NOT NULL AUTO_INCREMENT,
  `city` VARCHAR(100) NULL,
  PRIMARY KEY (`city_key`),
  UNIQUE KEY `uq_dim_city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_gender` (
  `gender_key` INT NOT NULL AUTO_INCREMENT,
  `gender` VARCHAR(100) NULL,
  PRIMARY KEY (`gender_key`),
  UNIQUE KEY `uq_dim_gender` (`gender`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_branch` (
  `branch_key` INT NOT NULL AUTO_INCREMENT,
  `branch` VARCHAR(100) NULL,
  `city_key` INT NULL,
  PRIMARY KEY (`branch_key`),
  UNIQUE KEY `uq_dim_branch` (`branch`, `city_key`),
  CONSTRAINT `fk_dim_branch_city_key` FOREIGN KEY (`city_key`) REFERENCES `dim_city` (`city_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_customer` (
  `customer_key` INT NOT NULL AUTO_INCREMENT,
  `customer_type` VARCHAR(100) NULL,
  `gender_key` INT NULL,
  PRIMARY KEY (`customer_key`),
  UNIQUE KEY `uq_dim_customer` (`customer_type`, `gender_key`),
  CONSTRAINT `fk_dim_customer_gender_key` FOREIGN KEY (`gender_key`) REFERENCES `dim_gender` (`gender_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_product_line` (
  `product_line_key` INT NOT NULL AUTO_INCREMENT,
  `product_line` VARCHAR(100) NULL,
  PRIMARY KEY (`product_line_key`),
  UNIQUE KEY `uq_dim_product_line` (`product_line`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_payment` (
  `payment_key` INT NOT NULL AUTO_INCREMENT,
  `payment` VARCHAR(100) NULL,
  PRIMARY KEY (`payment_key`),
  UNIQUE KEY `uq_dim_payment` (`payment`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_sales` (
  `fact_sales_key` BIGINT NOT NULL AUTO_INCREMENT,
  `date_key` INT NULL,
  `branch_key` INT NULL,
  `customer_key` INT NULL,
  `product_line_key` INT NULL,
  `payment_key` INT NULL,
  `invoice_id` VARCHAR(100) NULL,
  `sale_time` TIME NULL,
  `unit_price` DECIMAL(18,4) NULL,
  `quantity` INT NULL,
  `tax_5` DECIMAL(18,4) NULL,
  `total` DECIMAL(18,4) NULL,
  `cogs` DECIMAL(18,4) NULL,
  `gross_margin_percentage` DECIMAL(18,4) NULL,
  `gross_income` DECIMAL(18,4) NULL,
  `rating` DECIMAL(18,4) NULL,
  PRIMARY KEY (`fact_sales_key`),
  CONSTRAINT `fk_fact_sales_date_key` FOREIGN KEY (`date_key`) REFERENCES `dim_date` (`date_key`),
  CONSTRAINT `fk_fact_sales_branch_key` FOREIGN KEY (`branch_key`) REFERENCES `dim_branch` (`branch_key`),
  CONSTRAINT `fk_fact_sales_customer_key` FOREIGN KEY (`customer_key`) REFERENCES `dim_customer` (`customer_key`),
  CONSTRAINT `fk_fact_sales_product_line_key` FOREIGN KEY (`product_line_key`) REFERENCES `dim_product_line` (`product_line_key`),
  CONSTRAINT `fk_fact_sales_payment_key` FOREIGN KEY (`payment_key`) REFERENCES `dim_payment` (`payment_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL ------------------------------------------------------------

-- date hierarchy: year > quarter > month > date
INSERT INTO `dim_year` (year_key, year_num)
SELECT DISTINCT YEAR(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')) AS d FROM `dmbi_super_market_stg`.`stg_super_market` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_quarter` (quarter_key, quarter_num, year_key)
SELECT DISTINCT YEAR(d) * 10 + QUARTER(d), QUARTER(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')) AS d FROM `dmbi_super_market_stg`.`stg_super_market` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_month` (month_key, month_num, month_name, quarter_key)
SELECT DISTINCT YEAR(d) * 100 + MONTH(d), MONTH(d), MONTHNAME(d), YEAR(d) * 10 + QUARTER(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')) AS d FROM `dmbi_super_market_stg`.`stg_super_market` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_key)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), YEAR(d) * 100 + MONTH(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')) AS d FROM `dmbi_super_market_stg`.`stg_super_market` s) x WHERE d IS NOT NULL;

-- dim_city
INSERT INTO `dim_city` (`city`)
SELECT DISTINCT
  NULLIF(TRIM(s.`City`), '')
FROM `dmbi_super_market_stg`.`stg_super_market` s;

-- dim_gender
INSERT INTO `dim_gender` (`gender`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Gender`), '')
FROM `dmbi_super_market_stg`.`stg_super_market` s;

-- dim_branch
INSERT INTO `dim_branch` (`branch`, `city_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Branch`), ''),
  x1.`city_key`
FROM `dmbi_super_market_stg`.`stg_super_market` s
LEFT JOIN `dim_city` x1 ON x1.`city` <=> NULLIF(TRIM(s.`City`), '');

-- dim_customer
INSERT INTO `dim_customer` (`customer_type`, `gender_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Customer type`), ''),
  x1.`gender_key`
FROM `dmbi_super_market_stg`.`stg_super_market` s
LEFT JOIN `dim_gender` x1 ON x1.`gender` <=> NULLIF(TRIM(s.`Gender`), '');

-- dim_product_line
INSERT INTO `dim_product_line` (`product_line`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Product line`), '')
FROM `dmbi_super_market_stg`.`stg_super_market` s;

-- dim_payment
INSERT INTO `dim_payment` (`payment`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Payment`), '')
FROM `dmbi_super_market_stg`.`stg_super_market` s;

-- fact_sales
INSERT INTO `fact_sales` (`date_key`, `branch_key`, `customer_key`, `product_line_key`, `payment_key`, `invoice_id`, `sale_time`, `unit_price`, `quantity`, `tax_5`, `total`, `cogs`, `gross_margin_percentage`, `gross_income`, `rating`)
SELECT
  CAST(DATE_FORMAT(DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')), '%Y%m%d') AS UNSIGNED),
  d1.`branch_key`,
  d2.`customer_key`,
  d3.`product_line_key`,
  d4.`payment_key`,
  NULLIF(TRIM(s.`Invoice ID`), ''),
  TIME(STR_TO_DATE(TRIM(s.`Time`), '%H:%i')),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Unit price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Quantity`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Tax 5%`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`cogs`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`gross margin percentage`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`gross income`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Rating`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4))
FROM `dmbi_super_market_stg`.`stg_super_market` s
LEFT JOIN `dim_city` x1 ON x1.`city` <=> NULLIF(TRIM(s.`City`), '')
LEFT JOIN `dim_branch` d1 ON d1.`branch` <=> NULLIF(TRIM(s.`Branch`), '')
       AND d1.`city_key` <=> x1.`city_key`
LEFT JOIN `dim_gender` x2 ON x2.`gender` <=> NULLIF(TRIM(s.`Gender`), '')
LEFT JOIN `dim_customer` d2 ON d2.`customer_type` <=> NULLIF(TRIM(s.`Customer type`), '')
       AND d2.`gender_key` <=> x2.`gender_key`
LEFT JOIN `dim_product_line` d3 ON d3.`product_line` <=> NULLIF(TRIM(s.`Product line`), '')
LEFT JOIN `dim_payment` d4 ON d4.`payment` <=> NULLIF(TRIM(s.`Payment`), '');

-- ---- PART C : QUICK CHECK ------------------------------------------------------
SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count FROM `fact_sales` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date` UNION ALL SELECT 'dim_month' AS table_name, COUNT(*) AS row_count FROM `dim_month` UNION ALL SELECT 'dim_quarter' AS table_name, COUNT(*) AS row_count FROM `dim_quarter` UNION ALL SELECT 'dim_year' AS table_name, COUNT(*) AS row_count FROM `dim_year` UNION ALL SELECT 'dim_city' AS table_name, COUNT(*) AS row_count FROM `dim_city` UNION ALL SELECT 'dim_gender' AS table_name, COUNT(*) AS row_count FROM `dim_gender` UNION ALL SELECT 'dim_branch' AS table_name, COUNT(*) AS row_count FROM `dim_branch` UNION ALL SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM `dim_customer` UNION ALL SELECT 'dim_product_line' AS table_name, COUNT(*) AS row_count FROM `dim_product_line` UNION ALL SELECT 'dim_payment' AS table_name, COUNT(*) AS row_count FROM `dim_payment`;
