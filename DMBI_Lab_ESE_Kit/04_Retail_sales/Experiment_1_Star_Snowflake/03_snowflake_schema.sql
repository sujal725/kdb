-- ========================================================================
-- EXPERIMENT 1 - STEP 3 : SNOWFLAKE SCHEMA  [Retail_sales]
-- Same fact table as the star schema; dimensions are NORMALISED into sub-dimensions.
-- Sub-dimensions here: dim_gender, dim_age_group; date chain dim_date > dim_month > dim_quarter > dim_year
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_retail_sales_snow` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_retail_sales_snow`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_sales`;
DROP TABLE IF EXISTS `dim_date`;
DROP TABLE IF EXISTS `dim_month`;
DROP TABLE IF EXISTS `dim_quarter`;
DROP TABLE IF EXISTS `dim_year`;
DROP TABLE IF EXISTS `dim_gender`;
DROP TABLE IF EXISTS `dim_age_group`;
DROP TABLE IF EXISTS `dim_customer`;
DROP TABLE IF EXISTS `dim_product_category`;
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

CREATE TABLE `dim_gender` (
  `gender_key` INT NOT NULL AUTO_INCREMENT,
  `gender` VARCHAR(100) NULL,
  PRIMARY KEY (`gender_key`),
  UNIQUE KEY `uq_dim_gender` (`gender`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_age_group` (
  `age_group_key` INT NOT NULL AUTO_INCREMENT,
  `age_group` VARCHAR(20) NULL,
  PRIMARY KEY (`age_group_key`),
  UNIQUE KEY `uq_dim_age_group` (`age_group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_customer` (
  `customer_key` INT NOT NULL AUTO_INCREMENT,
  `customer_id` VARCHAR(100) NULL,
  `age` INT NULL,
  `gender_key` INT NULL,
  `age_group_key` INT NULL,
  PRIMARY KEY (`customer_key`),
  UNIQUE KEY `uq_dim_customer` (`customer_id`, `age`, `gender_key`, `age_group_key`),
  CONSTRAINT `fk_dim_customer_gender_key` FOREIGN KEY (`gender_key`) REFERENCES `dim_gender` (`gender_key`),
  CONSTRAINT `fk_dim_customer_age_group_key` FOREIGN KEY (`age_group_key`) REFERENCES `dim_age_group` (`age_group_key`)
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

-- ---- PART B : ETL ------------------------------------------------------------

-- date hierarchy: year > quarter > month > date
INSERT INTO `dim_year` (year_key, year_num)
SELECT DISTINCT YEAR(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_quarter` (quarter_key, quarter_num, year_key)
SELECT DISTINCT YEAR(d) * 10 + QUARTER(d), QUARTER(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_month` (month_key, month_num, month_name, quarter_key)
SELECT DISTINCT YEAR(d) * 100 + MONTH(d), MONTH(d), MONTHNAME(d), YEAR(d) * 10 + QUARTER(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_key)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), YEAR(d) * 100 + MONTH(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s) x WHERE d IS NOT NULL;

-- dim_gender
INSERT INTO `dim_gender` (`gender`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Gender`), '')
FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s;

-- dim_age_group
INSERT INTO `dim_age_group` (`age_group`)
SELECT DISTINCT
  CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN '18-24' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '25-34' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 45 THEN '35-44' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 55 THEN '45-54' ELSE '55+' END
FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s;

-- dim_customer
INSERT INTO `dim_customer` (`customer_id`, `age`, `gender_key`, `age_group_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Customer ID`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  x1.`gender_key`,
  x2.`age_group_key`
FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s
LEFT JOIN `dim_gender` x1 ON x1.`gender` <=> NULLIF(TRIM(s.`Gender`), '')
LEFT JOIN `dim_age_group` x2 ON x2.`age_group` <=> CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN '18-24' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '25-34' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 45 THEN '35-44' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 55 THEN '45-54' ELSE '55+' END;

-- dim_product_category
INSERT INTO `dim_product_category` (`product_category`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Product Category`), '')
FROM `dmbi_retail_sales_stg`.`stg_retail_sales` s;

-- fact_sales
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
LEFT JOIN `dim_gender` x1 ON x1.`gender` <=> NULLIF(TRIM(s.`Gender`), '')
LEFT JOIN `dim_age_group` x2 ON x2.`age_group` <=> CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN '18-24' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '25-34' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 45 THEN '35-44' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 55 THEN '45-54' ELSE '55+' END
LEFT JOIN `dim_customer` d1 ON d1.`customer_id` <=> NULLIF(TRIM(s.`Customer ID`), '')
       AND d1.`age` <=> CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
       AND d1.`gender_key` <=> x1.`gender_key`
       AND d1.`age_group_key` <=> x2.`age_group_key`
LEFT JOIN `dim_product_category` d2 ON d2.`product_category` <=> NULLIF(TRIM(s.`Product Category`), '');

-- ---- PART C : QUICK CHECK ------------------------------------------------------
SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count FROM `fact_sales` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date` UNION ALL SELECT 'dim_month' AS table_name, COUNT(*) AS row_count FROM `dim_month` UNION ALL SELECT 'dim_quarter' AS table_name, COUNT(*) AS row_count FROM `dim_quarter` UNION ALL SELECT 'dim_year' AS table_name, COUNT(*) AS row_count FROM `dim_year` UNION ALL SELECT 'dim_gender' AS table_name, COUNT(*) AS row_count FROM `dim_gender` UNION ALL SELECT 'dim_age_group' AS table_name, COUNT(*) AS row_count FROM `dim_age_group` UNION ALL SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM `dim_customer` UNION ALL SELECT 'dim_product_category' AS table_name, COUNT(*) AS row_count FROM `dim_product_category`;
