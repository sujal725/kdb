-- ========================================================================
-- EXPERIMENT 1 - STEP 3 : SNOWFLAKE SCHEMA  [Employee]
-- Same fact table as the star schema; dimensions are NORMALISED into sub-dimensions.
-- Sub-dimensions here: dim_gender, dim_age_band
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_employee_snow` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_employee_snow`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_employee`;
DROP TABLE IF EXISTS `dim_gender`;
DROP TABLE IF EXISTS `dim_age_band`;
DROP TABLE IF EXISTS `dim_education`;
DROP TABLE IF EXISTS `dim_city`;
DROP TABLE IF EXISTS `dim_joining_year`;
DROP TABLE IF EXISTS `dim_payment_tier`;
DROP TABLE IF EXISTS `dim_employee_profile`;
SET FOREIGN_KEY_CHECKS = 1;

-- ---- PART A : DDL (outer-most sub-dimensions first) ---------------------------

CREATE TABLE `dim_gender` (
  `gender_key` INT NOT NULL AUTO_INCREMENT,
  `gender` VARCHAR(100) NULL,
  PRIMARY KEY (`gender_key`),
  UNIQUE KEY `uq_dim_gender` (`gender`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_age_band` (
  `age_band_key` INT NOT NULL AUTO_INCREMENT,
  `age_band` VARCHAR(20) NULL,
  PRIMARY KEY (`age_band_key`),
  UNIQUE KEY `uq_dim_age_band` (`age_band`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_education` (
  `education_key` INT NOT NULL AUTO_INCREMENT,
  `education` VARCHAR(100) NULL,
  PRIMARY KEY (`education_key`),
  UNIQUE KEY `uq_dim_education` (`education`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_city` (
  `city_key` INT NOT NULL AUTO_INCREMENT,
  `city` VARCHAR(100) NULL,
  PRIMARY KEY (`city_key`),
  UNIQUE KEY `uq_dim_city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_joining_year` (
  `joining_year_key` INT NOT NULL AUTO_INCREMENT,
  `joining_year` INT NULL,
  PRIMARY KEY (`joining_year_key`),
  UNIQUE KEY `uq_dim_joining_year` (`joining_year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_payment_tier` (
  `payment_tier_key` INT NOT NULL AUTO_INCREMENT,
  `payment_tier` INT NULL,
  PRIMARY KEY (`payment_tier_key`),
  UNIQUE KEY `uq_dim_payment_tier` (`payment_tier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_employee_profile` (
  `employee_profile_key` INT NOT NULL AUTO_INCREMENT,
  `ever_benched` VARCHAR(100) NULL,
  `gender_key` INT NULL,
  `age_band_key` INT NULL,
  PRIMARY KEY (`employee_profile_key`),
  UNIQUE KEY `uq_dim_employee_profile` (`ever_benched`, `gender_key`, `age_band_key`),
  CONSTRAINT `fk_dim_employee_profile_gender_key` FOREIGN KEY (`gender_key`) REFERENCES `dim_gender` (`gender_key`),
  CONSTRAINT `fk_dim_employee_profile_age_band_key` FOREIGN KEY (`age_band_key`) REFERENCES `dim_age_band` (`age_band_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_employee` (
  `fact_employee_key` BIGINT NOT NULL AUTO_INCREMENT,
  `education_key` INT NULL,
  `city_key` INT NULL,
  `joining_year_key` INT NULL,
  `payment_tier_key` INT NULL,
  `employee_profile_key` INT NULL,
  `age` INT NULL,
  `experience_in_current_domain` INT NULL,
  `leave_or_not` INT NULL,
  PRIMARY KEY (`fact_employee_key`),
  CONSTRAINT `fk_fact_employee_education_key` FOREIGN KEY (`education_key`) REFERENCES `dim_education` (`education_key`),
  CONSTRAINT `fk_fact_employee_city_key` FOREIGN KEY (`city_key`) REFERENCES `dim_city` (`city_key`),
  CONSTRAINT `fk_fact_employee_joining_year_key` FOREIGN KEY (`joining_year_key`) REFERENCES `dim_joining_year` (`joining_year_key`),
  CONSTRAINT `fk_fact_employee_payment_tier_key` FOREIGN KEY (`payment_tier_key`) REFERENCES `dim_payment_tier` (`payment_tier_key`),
  CONSTRAINT `fk_fact_employee_employee_profile_key` FOREIGN KEY (`employee_profile_key`) REFERENCES `dim_employee_profile` (`employee_profile_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL ------------------------------------------------------------

-- dim_gender
INSERT INTO `dim_gender` (`gender`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Gender`), '')
FROM `dmbi_employee_stg`.`stg_employee` s;

-- dim_age_band
INSERT INTO `dim_age_band` (`age_band`)
SELECT DISTINCT
  CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN 'Under 25' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 30 THEN '25-29' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '30-34' ELSE '35+' END
FROM `dmbi_employee_stg`.`stg_employee` s;

-- dim_education
INSERT INTO `dim_education` (`education`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Education`), '')
FROM `dmbi_employee_stg`.`stg_employee` s;

-- dim_city
INSERT INTO `dim_city` (`city`)
SELECT DISTINCT
  NULLIF(TRIM(s.`City`), '')
FROM `dmbi_employee_stg`.`stg_employee` s;

-- dim_joining_year
INSERT INTO `dim_joining_year` (`joining_year`)
SELECT DISTINCT
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`JoiningYear`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `dmbi_employee_stg`.`stg_employee` s;

-- dim_payment_tier
INSERT INTO `dim_payment_tier` (`payment_tier`)
SELECT DISTINCT
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`PaymentTier`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `dmbi_employee_stg`.`stg_employee` s;

-- dim_employee_profile
INSERT INTO `dim_employee_profile` (`ever_benched`, `gender_key`, `age_band_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`EverBenched`), ''),
  x1.`gender_key`,
  x2.`age_band_key`
FROM `dmbi_employee_stg`.`stg_employee` s
LEFT JOIN `dim_gender` x1 ON x1.`gender` <=> NULLIF(TRIM(s.`Gender`), '')
LEFT JOIN `dim_age_band` x2 ON x2.`age_band` <=> CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN 'Under 25' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 30 THEN '25-29' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '30-34' ELSE '35+' END;

-- fact_employee
INSERT INTO `fact_employee` (`education_key`, `city_key`, `joining_year_key`, `payment_tier_key`, `employee_profile_key`, `age`, `experience_in_current_domain`, `leave_or_not`)
SELECT
  d1.`education_key`,
  d2.`city_key`,
  d3.`joining_year_key`,
  d4.`payment_tier_key`,
  d5.`employee_profile_key`,
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`ExperienceInCurrentDomain`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`LeaveOrNot`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `dmbi_employee_stg`.`stg_employee` s
LEFT JOIN `dim_education` d1 ON d1.`education` <=> NULLIF(TRIM(s.`Education`), '')
LEFT JOIN `dim_city` d2 ON d2.`city` <=> NULLIF(TRIM(s.`City`), '')
LEFT JOIN `dim_joining_year` d3 ON d3.`joining_year` <=> CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`JoiningYear`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
LEFT JOIN `dim_payment_tier` d4 ON d4.`payment_tier` <=> CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`PaymentTier`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
LEFT JOIN `dim_gender` x1 ON x1.`gender` <=> NULLIF(TRIM(s.`Gender`), '')
LEFT JOIN `dim_age_band` x2 ON x2.`age_band` <=> CASE WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 25 THEN 'Under 25' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 30 THEN '25-29' WHEN (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) < 35 THEN '30-34' ELSE '35+' END
LEFT JOIN `dim_employee_profile` d5 ON d5.`ever_benched` <=> NULLIF(TRIM(s.`EverBenched`), '')
       AND d5.`gender_key` <=> x1.`gender_key`
       AND d5.`age_band_key` <=> x2.`age_band_key`;

-- ---- PART C : QUICK CHECK ------------------------------------------------------
SELECT 'fact_employee' AS table_name, COUNT(*) AS row_count FROM `fact_employee` UNION ALL SELECT 'dim_gender' AS table_name, COUNT(*) AS row_count FROM `dim_gender` UNION ALL SELECT 'dim_age_band' AS table_name, COUNT(*) AS row_count FROM `dim_age_band` UNION ALL SELECT 'dim_education' AS table_name, COUNT(*) AS row_count FROM `dim_education` UNION ALL SELECT 'dim_city' AS table_name, COUNT(*) AS row_count FROM `dim_city` UNION ALL SELECT 'dim_joining_year' AS table_name, COUNT(*) AS row_count FROM `dim_joining_year` UNION ALL SELECT 'dim_payment_tier' AS table_name, COUNT(*) AS row_count FROM `dim_payment_tier` UNION ALL SELECT 'dim_employee_profile' AS table_name, COUNT(*) AS row_count FROM `dim_employee_profile`;
