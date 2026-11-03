-- ========================================================================
-- EXPERIMENT 1 - STEP 2 : STAR SCHEMA  [Banking_Customer_Dataset]
-- Fact  : fact_bank_customer   (grain: One row per bank customer.)
-- Dims  : dim_customer, dim_geography, dim_credit_band
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_banking_customer_star` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_banking_customer_star`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_bank_customer`;
DROP TABLE IF EXISTS `dim_customer`;
DROP TABLE IF EXISTS `dim_geography`;
DROP TABLE IF EXISTS `dim_credit_band`;
SET FOREIGN_KEY_CHECKS = 1;

-- ---- PART A : DDL (dimension tables, then the fact table) -------------------

CREATE TABLE `dim_customer` (
  `customer_key` INT NOT NULL AUTO_INCREMENT,
  `customer_id` BIGINT NULL,
  `surname` VARCHAR(100) NULL,
  `gender` VARCHAR(100) NULL,
  `age_group` VARCHAR(20) NULL,
  PRIMARY KEY (`customer_key`),
  UNIQUE KEY `uq_dim_customer` (`customer_id`, `surname`, `gender`, `age_group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_geography` (
  `geography_key` INT NOT NULL AUTO_INCREMENT,
  `geography` VARCHAR(100) NULL,
  PRIMARY KEY (`geography_key`),
  UNIQUE KEY `uq_dim_geography` (`geography`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_credit_band` (
  `credit_band_key` INT NOT NULL AUTO_INCREMENT,
  `credit_band` VARCHAR(30) NULL,
  PRIMARY KEY (`credit_band_key`),
  UNIQUE KEY `uq_dim_credit_band` (`credit_band`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_bank_customer` (
  `fact_bank_customer_key` BIGINT NOT NULL AUTO_INCREMENT,
  `customer_key` INT NULL,
  `geography_key` INT NULL,
  `credit_band_key` INT NULL,
  `src_row_number` INT NULL,
  `credit_score` INT NULL,
  `age` INT NULL,
  `tenure` INT NULL,
  `balance` DECIMAL(18,2) NULL,
  `num_of_products` INT NULL,
  `has_cr_card` INT NULL,
  `is_active_member` INT NULL,
  `estimated_salary` DECIMAL(18,2) NULL,
  `exited` INT NULL,
  PRIMARY KEY (`fact_bank_customer_key`),
  CONSTRAINT `fk_fact_bank_customer_customer_key` FOREIGN KEY (`customer_key`) REFERENCES `dim_customer` (`customer_key`),
  CONSTRAINT `fk_fact_bank_customer_geography_key` FOREIGN KEY (`geography_key`) REFERENCES `dim_geography` (`geography_key`),
  CONSTRAINT `fk_fact_bank_customer_credit_band_key` FOREIGN KEY (`credit_band_key`) REFERENCES `dim_credit_band` (`credit_band_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL (staging -> dimensions -> fact) -------------------------

-- NULL-safe equality (<=>) is used in the joins so rows with blanks are not lost.

-- dim_customer
INSERT INTO `dim_customer` (`customer_id`, `surname`, `gender`, `age_group`)
SELECT DISTINCT
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CustomerId`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`Surname`), ''),
  NULLIF(TRIM(s.`Gender`), ''),
  CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN '18-24' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '25-34' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 45 THEN '35-44' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 55 THEN '45-54' ELSE '55+' END
FROM `dmbi_banking_customer_stg`.`stg_banking_customer` s;

-- dim_geography
INSERT INTO `dim_geography` (`geography`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Geography`), '')
FROM `dmbi_banking_customer_stg`.`stg_banking_customer` s;

-- dim_credit_band
INSERT INTO `dim_credit_band` (`credit_band`)
SELECT DISTINCT
  CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CreditScore`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 580 THEN 'Poor (<580)' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CreditScore`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 670 THEN 'Fair (580-669)' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CreditScore`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 740 THEN 'Good (670-739)' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CreditScore`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 800 THEN 'Very Good (740-799)' ELSE 'Excellent (800+)' END
FROM `dmbi_banking_customer_stg`.`stg_banking_customer` s;

-- fact_bank_customer : one row per source row, foreign keys looked up from the dimensions
INSERT INTO `fact_bank_customer` (`customer_key`, `geography_key`, `credit_band_key`, `src_row_number`, `credit_score`, `age`, `tenure`, `balance`, `num_of_products`, `has_cr_card`, `is_active_member`, `estimated_salary`, `exited`)
SELECT
  d1.`customer_key`,
  d2.`geography_key`,
  d3.`credit_band_key`,
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`RowNumber`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CreditScore`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Tenure`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Balance`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`NumOfProducts`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`HasCrCard`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`IsActiveMember`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`EstimatedSalary`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Exited`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `dmbi_banking_customer_stg`.`stg_banking_customer` s
LEFT JOIN `dim_customer` d1 ON d1.`customer_id` <=> CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CustomerId`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
       AND d1.`surname` <=> NULLIF(TRIM(s.`Surname`), '')
       AND d1.`gender` <=> NULLIF(TRIM(s.`Gender`), '')
       AND d1.`age_group` <=> CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN '18-24' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '25-34' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 45 THEN '35-44' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 55 THEN '45-54' ELSE '55+' END
LEFT JOIN `dim_geography` d2 ON d2.`geography` <=> NULLIF(TRIM(s.`Geography`), '')
LEFT JOIN `dim_credit_band` d3 ON d3.`credit_band` <=> CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CreditScore`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 580 THEN 'Poor (<580)' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CreditScore`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 670 THEN 'Fair (580-669)' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CreditScore`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 740 THEN 'Good (670-739)' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CreditScore`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 800 THEN 'Very Good (740-799)' ELSE 'Excellent (800+)' END;

-- ---- PART C : QUICK CHECK -------------------------------------------------
SELECT 'fact_bank_customer' AS table_name, COUNT(*) AS row_count FROM `fact_bank_customer` UNION ALL SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM `dim_customer` UNION ALL SELECT 'dim_geography' AS table_name, COUNT(*) AS row_count FROM `dim_geography` UNION ALL SELECT 'dim_credit_band' AS table_name, COUNT(*) AS row_count FROM `dim_credit_band`;
