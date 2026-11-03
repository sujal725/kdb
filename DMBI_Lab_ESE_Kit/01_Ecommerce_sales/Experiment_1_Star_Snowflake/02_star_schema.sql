-- ========================================================================
-- EXPERIMENT 1 - STEP 2 : STAR SCHEMA  [Ecommerce_sales]
-- Fact  : fact_sales   (grain: One row per daily sales record (product category x customer segment x day).)
-- Dims  : dim_date, dim_product_category, dim_customer_segment, dim_discount_band
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_ecommerce_sales_star` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_ecommerce_sales_star`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_sales`;
DROP TABLE IF EXISTS `dim_product_category`;
DROP TABLE IF EXISTS `dim_customer_segment`;
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

CREATE TABLE `dim_product_category` (
  `product_category_key` INT NOT NULL AUTO_INCREMENT,
  `product_category` VARCHAR(100) NULL,
  PRIMARY KEY (`product_category_key`),
  UNIQUE KEY `uq_dim_product_category` (`product_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_customer_segment` (
  `customer_segment_key` INT NOT NULL AUTO_INCREMENT,
  `customer_segment` VARCHAR(100) NULL,
  PRIMARY KEY (`customer_segment_key`),
  UNIQUE KEY `uq_dim_customer_segment` (`customer_segment`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_discount_band` (
  `discount_band_key` INT NOT NULL AUTO_INCREMENT,
  `discount_band` VARCHAR(20) NULL,
  PRIMARY KEY (`discount_band_key`),
  UNIQUE KEY `uq_dim_discount_band` (`discount_band`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_sales` (
  `fact_sales_key` BIGINT NOT NULL AUTO_INCREMENT,
  `date_key` INT NULL,
  `product_category_key` INT NULL,
  `customer_segment_key` INT NULL,
  `discount_band_key` INT NULL,
  `price` DECIMAL(18,2) NULL,
  `discount` DECIMAL(18,2) NULL,
  `marketing_spend` DECIMAL(18,2) NULL,
  `units_sold` INT NULL,
  `gross_revenue` DECIMAL(18,2) NULL,
  `net_revenue` DECIMAL(18,2) NULL,
  PRIMARY KEY (`fact_sales_key`),
  CONSTRAINT `fk_fact_sales_date_key` FOREIGN KEY (`date_key`) REFERENCES `dim_date` (`date_key`),
  CONSTRAINT `fk_fact_sales_product_category_key` FOREIGN KEY (`product_category_key`) REFERENCES `dim_product_category` (`product_category_key`),
  CONSTRAINT `fk_fact_sales_customer_segment_key` FOREIGN KEY (`customer_segment_key`) REFERENCES `dim_customer_segment` (`customer_segment_key`),
  CONSTRAINT `fk_fact_sales_discount_band_key` FOREIGN KEY (`discount_band_key`) REFERENCES `dim_discount_band` (`discount_band_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL (staging -> dimensions -> fact) -------------------------

-- NULL-safe equality (<=>) is used in the joins so rows with blanks are not lost.

-- dim_date: one row per distinct calendar date found in the data
INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_num, month_name, quarter_num, year_num)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), MONTH(d), MONTHNAME(d), QUARTER(d), YEAR(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_ecommerce_sales_stg`.`stg_ecommerce_sales` s) x
WHERE d IS NOT NULL;

-- dim_product_category
INSERT INTO `dim_product_category` (`product_category`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Product_Category`), '')
FROM `dmbi_ecommerce_sales_stg`.`stg_ecommerce_sales` s;

-- dim_customer_segment
INSERT INTO `dim_customer_segment` (`customer_segment`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Customer_Segment`), '')
FROM `dmbi_ecommerce_sales_stg`.`stg_ecommerce_sales` s;

-- dim_discount_band
INSERT INTO `dim_discount_band` (`discount_band`)
SELECT DISTINCT
  CASE WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 1 THEN 'No discount' WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 10 THEN 'Low (<10%)' WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 20 THEN 'Medium (10-19%)' ELSE 'High (20%+)' END
FROM `dmbi_ecommerce_sales_stg`.`stg_ecommerce_sales` s;

-- fact_sales : one row per source row, foreign keys looked up from the dimensions
INSERT INTO `fact_sales` (`date_key`, `product_category_key`, `customer_segment_key`, `discount_band_key`, `price`, `discount`, `marketing_spend`, `units_sold`, `gross_revenue`, `net_revenue`)
SELECT
  CAST(DATE_FORMAT(DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')), '%Y%m%d') AS UNSIGNED),
  d1.`product_category_key`,
  d2.`customer_segment_key`,
  d3.`discount_band_key`,
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Marketing_Spend`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units_Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) * (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units_Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)),
  (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) * (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units_Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) * (1 - (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) / 100)
FROM `dmbi_ecommerce_sales_stg`.`stg_ecommerce_sales` s
LEFT JOIN `dim_product_category` d1 ON d1.`product_category` <=> NULLIF(TRIM(s.`Product_Category`), '')
LEFT JOIN `dim_customer_segment` d2 ON d2.`customer_segment` <=> NULLIF(TRIM(s.`Customer_Segment`), '')
LEFT JOIN `dim_discount_band` d3 ON d3.`discount_band` <=> CASE WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 1 THEN 'No discount' WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 10 THEN 'Low (<10%)' WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 20 THEN 'Medium (10-19%)' ELSE 'High (20%+)' END;

-- ---- PART C : QUICK CHECK -------------------------------------------------
SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count FROM `fact_sales` UNION ALL SELECT 'dim_product_category' AS table_name, COUNT(*) AS row_count FROM `dim_product_category` UNION ALL SELECT 'dim_customer_segment' AS table_name, COUNT(*) AS row_count FROM `dim_customer_segment` UNION ALL SELECT 'dim_discount_band' AS table_name, COUNT(*) AS row_count FROM `dim_discount_band` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date`;
