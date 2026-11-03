-- ========================================================================
-- EXPERIMENT 1 - STEP 2 : STAR SCHEMA  [Customer_Purchase_History_Dataset]
-- Fact  : fact_customer_purchase   (grain: One row per customer.)
-- Dims  : dim_region, dim_demographic
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_customer_purchase_star` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_customer_purchase_star`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_customer_purchase`;
DROP TABLE IF EXISTS `dim_region`;
DROP TABLE IF EXISTS `dim_demographic`;
SET FOREIGN_KEY_CHECKS = 1;

-- ---- PART A : DDL (dimension tables, then the fact table) -------------------

CREATE TABLE `dim_region` (
  `region_key` INT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(100) NULL,
  PRIMARY KEY (`region_key`),
  UNIQUE KEY `uq_dim_region` (`region`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_demographic` (
  `demographic_key` INT NOT NULL AUTO_INCREMENT,
  `age_group` VARCHAR(20) NULL,
  `income_band` VARCHAR(20) NULL,
  PRIMARY KEY (`demographic_key`),
  UNIQUE KEY `uq_dim_demographic` (`age_group`, `income_band`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_customer_purchase` (
  `fact_customer_purchase_key` BIGINT NOT NULL AUTO_INCREMENT,
  `region_key` INT NULL,
  `demographic_key` INT NULL,
  `user_id` INT NULL,
  `age` INT NULL,
  `annual_income` DECIMAL(18,2) NULL,
  `purchase_amount` DECIMAL(18,2) NULL,
  `loyalty_score` DECIMAL(18,4) NULL,
  `purchase_frequency` INT NULL,
  PRIMARY KEY (`fact_customer_purchase_key`),
  CONSTRAINT `fk_fact_customer_purchase_region_key` FOREIGN KEY (`region_key`) REFERENCES `dim_region` (`region_key`),
  CONSTRAINT `fk_fact_customer_purchase_demographic_key` FOREIGN KEY (`demographic_key`) REFERENCES `dim_demographic` (`demographic_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL (staging -> dimensions -> fact) -------------------------

-- NULL-safe equality (<=>) is used in the joins so rows with blanks are not lost.

-- dim_region
INSERT INTO `dim_region` (`region`)
SELECT DISTINCT
  NULLIF(TRIM(s.`region`), '')
FROM `dmbi_customer_purchase_stg`.`stg_customer_purchase` s;

-- dim_demographic
INSERT INTO `dim_demographic` (`age_group`, `income_band`)
SELECT DISTINCT
  CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN '18-24' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '25-34' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 45 THEN '35-44' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 55 THEN '45-54' ELSE '55+' END,
  CASE WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`annual_income`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 40000 THEN 'Below 40k' WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`annual_income`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 60000 THEN '40k-59k' WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`annual_income`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 80000 THEN '60k-79k' ELSE '80k and above' END
FROM `dmbi_customer_purchase_stg`.`stg_customer_purchase` s;

-- fact_customer_purchase : one row per source row, foreign keys looked up from the dimensions
INSERT INTO `fact_customer_purchase` (`region_key`, `demographic_key`, `user_id`, `age`, `annual_income`, `purchase_amount`, `loyalty_score`, `purchase_frequency`)
SELECT
  d1.`region_key`,
  d2.`demographic_key`,
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`user_id`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`annual_income`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`purchase_amount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`loyalty_score`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`purchase_frequency`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `dmbi_customer_purchase_stg`.`stg_customer_purchase` s
LEFT JOIN `dim_region` d1 ON d1.`region` <=> NULLIF(TRIM(s.`region`), '')
LEFT JOIN `dim_demographic` d2 ON d2.`age_group` <=> CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN '18-24' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '25-34' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 45 THEN '35-44' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 55 THEN '45-54' ELSE '55+' END
       AND d2.`income_band` <=> CASE WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`annual_income`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 40000 THEN 'Below 40k' WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`annual_income`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 60000 THEN '40k-59k' WHEN (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`annual_income`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) < 80000 THEN '60k-79k' ELSE '80k and above' END;

-- ---- PART C : QUICK CHECK -------------------------------------------------
SELECT 'fact_customer_purchase' AS table_name, COUNT(*) AS row_count FROM `fact_customer_purchase` UNION ALL SELECT 'dim_region' AS table_name, COUNT(*) AS row_count FROM `dim_region` UNION ALL SELECT 'dim_demographic' AS table_name, COUNT(*) AS row_count FROM `dim_demographic`;
