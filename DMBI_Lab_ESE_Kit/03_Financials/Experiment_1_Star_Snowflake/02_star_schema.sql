-- ========================================================================
-- EXPERIMENT 1 - STEP 2 : STAR SCHEMA  [Financials]
-- Fact  : fact_sales   (grain: One row per segment x country x product x discount band x month (as in the source file).)
-- Dims  : dim_date, dim_segment, dim_country, dim_product, dim_discount_band
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_financials_star` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_financials_star`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_sales`;
DROP TABLE IF EXISTS `dim_segment`;
DROP TABLE IF EXISTS `dim_country`;
DROP TABLE IF EXISTS `dim_product`;
DROP TABLE IF EXISTS `dim_discount_band`;
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

CREATE TABLE `dim_segment` (
  `segment_key` INT NOT NULL AUTO_INCREMENT,
  `segment` VARCHAR(100) NULL,
  PRIMARY KEY (`segment_key`),
  UNIQUE KEY `uq_dim_segment` (`segment`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_country` (
  `country_key` INT NOT NULL AUTO_INCREMENT,
  `country` VARCHAR(100) NULL,
  PRIMARY KEY (`country_key`),
  UNIQUE KEY `uq_dim_country` (`country`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_product` (
  `product_key` INT NOT NULL AUTO_INCREMENT,
  `product` VARCHAR(100) NULL,
  PRIMARY KEY (`product_key`),
  UNIQUE KEY `uq_dim_product` (`product`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_discount_band` (
  `discount_band_key` INT NOT NULL AUTO_INCREMENT,
  `discount_band` VARCHAR(100) NULL,
  PRIMARY KEY (`discount_band_key`),
  UNIQUE KEY `uq_dim_discount_band` (`discount_band`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_sales` (
  `fact_sales_key` BIGINT NOT NULL AUTO_INCREMENT,
  `date_key` INT NULL,
  `segment_key` INT NULL,
  `country_key` INT NULL,
  `product_key` INT NULL,
  `discount_band_key` INT NULL,
  `units_sold` DECIMAL(18,2) NULL,
  `manufacturing_price` DECIMAL(18,2) NULL,
  `sale_price` DECIMAL(18,2) NULL,
  `gross_sales` DECIMAL(18,2) NULL,
  `discounts` DECIMAL(18,2) NULL,
  `sales` DECIMAL(18,2) NULL,
  `cogs` DECIMAL(18,2) NULL,
  `profit` DECIMAL(18,2) NULL,
  PRIMARY KEY (`fact_sales_key`),
  CONSTRAINT `fk_fact_sales_date_key` FOREIGN KEY (`date_key`) REFERENCES `dim_date` (`date_key`),
  CONSTRAINT `fk_fact_sales_segment_key` FOREIGN KEY (`segment_key`) REFERENCES `dim_segment` (`segment_key`),
  CONSTRAINT `fk_fact_sales_country_key` FOREIGN KEY (`country_key`) REFERENCES `dim_country` (`country_key`),
  CONSTRAINT `fk_fact_sales_product_key` FOREIGN KEY (`product_key`) REFERENCES `dim_product` (`product_key`),
  CONSTRAINT `fk_fact_sales_discount_band_key` FOREIGN KEY (`discount_band_key`) REFERENCES `dim_discount_band` (`discount_band_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL (staging -> dimensions -> fact) -------------------------

-- NULL-safe equality (<=>) is used in the joins so rows with blanks are not lost.

-- dim_date: one row per distinct calendar date found in the data
INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_num, month_name, quarter_num, year_num)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), MONTH(d), MONTHNAME(d), QUARTER(d), YEAR(d)
FROM (SELECT STR_TO_DATE(CONCAT(REPLACE(s.`Year`, ',', ''), '-', s.`Month Number`, '-01'), '%Y-%m-%d') AS d FROM `dmbi_financials_stg`.`stg_financials` s) x
WHERE d IS NOT NULL;

-- dim_segment
INSERT INTO `dim_segment` (`segment`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Segment`), '')
FROM `dmbi_financials_stg`.`stg_financials` s;

-- dim_country
INSERT INTO `dim_country` (`country`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Country`), '')
FROM `dmbi_financials_stg`.`stg_financials` s;

-- dim_product
INSERT INTO `dim_product` (`product`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Product`), '')
FROM `dmbi_financials_stg`.`stg_financials` s;

-- dim_discount_band
INSERT INTO `dim_discount_band` (`discount_band`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Discount Band`), '')
FROM `dmbi_financials_stg`.`stg_financials` s;

-- fact_sales : one row per source row, foreign keys looked up from the dimensions
INSERT INTO `fact_sales` (`date_key`, `segment_key`, `country_key`, `product_key`, `discount_band_key`, `units_sold`, `manufacturing_price`, `sale_price`, `gross_sales`, `discounts`, `sales`, `cogs`, `profit`)
SELECT
  CAST(DATE_FORMAT(STR_TO_DATE(CONCAT(REPLACE(s.`Year`, ',', ''), '-', s.`Month Number`, '-01'), '%Y-%m-%d'), '%Y%m%d') AS UNSIGNED),
  d1.`segment_key`,
  d2.`country_key`,
  d3.`product_key`,
  d4.`discount_band_key`,
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Manufacturing Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Sale Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Gross Sales`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discounts`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Sales`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`COGS`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Profit`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))
FROM `dmbi_financials_stg`.`stg_financials` s
LEFT JOIN `dim_segment` d1 ON d1.`segment` <=> NULLIF(TRIM(s.`Segment`), '')
LEFT JOIN `dim_country` d2 ON d2.`country` <=> NULLIF(TRIM(s.`Country`), '')
LEFT JOIN `dim_product` d3 ON d3.`product` <=> NULLIF(TRIM(s.`Product`), '')
LEFT JOIN `dim_discount_band` d4 ON d4.`discount_band` <=> NULLIF(TRIM(s.`Discount Band`), '');

-- ---- PART C : QUICK CHECK -------------------------------------------------
SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count FROM `fact_sales` UNION ALL SELECT 'dim_segment' AS table_name, COUNT(*) AS row_count FROM `dim_segment` UNION ALL SELECT 'dim_country' AS table_name, COUNT(*) AS row_count FROM `dim_country` UNION ALL SELECT 'dim_product' AS table_name, COUNT(*) AS row_count FROM `dim_product` UNION ALL SELECT 'dim_discount_band' AS table_name, COUNT(*) AS row_count FROM `dim_discount_band` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date`;
