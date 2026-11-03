-- ========================================================================
-- EXPERIMENT 1 - STEP 3 : SNOWFLAKE SCHEMA  [HR_Analytics_Dataset]
-- Same fact table as the star schema; dimensions are NORMALISED into sub-dimensions.
-- Sub-dimensions here: dim_age_group, dim_education_field, dim_department
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_hr_analytics_snow` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_hr_analytics_snow`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_employee_hr`;
DROP TABLE IF EXISTS `dim_age_group`;
DROP TABLE IF EXISTS `dim_education_field`;
DROP TABLE IF EXISTS `dim_department`;
DROP TABLE IF EXISTS `dim_employee_demo`;
DROP TABLE IF EXISTS `dim_education`;
DROP TABLE IF EXISTS `dim_job`;
DROP TABLE IF EXISTS `dim_work_profile`;
DROP TABLE IF EXISTS `dim_salary_slab`;
SET FOREIGN_KEY_CHECKS = 1;

-- ---- PART A : DDL (outer-most sub-dimensions first) ---------------------------

CREATE TABLE `dim_age_group` (
  `age_group_key` INT NOT NULL AUTO_INCREMENT,
  `age_group` VARCHAR(100) NULL,
  PRIMARY KEY (`age_group_key`),
  UNIQUE KEY `uq_dim_age_group` (`age_group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_education_field` (
  `education_field_key` INT NOT NULL AUTO_INCREMENT,
  `education_field` VARCHAR(100) NULL,
  PRIMARY KEY (`education_field_key`),
  UNIQUE KEY `uq_dim_education_field` (`education_field`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_department` (
  `department_key` INT NOT NULL AUTO_INCREMENT,
  `department` VARCHAR(100) NULL,
  PRIMARY KEY (`department_key`),
  UNIQUE KEY `uq_dim_department` (`department`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_employee_demo` (
  `employee_demo_key` INT NOT NULL AUTO_INCREMENT,
  `gender` VARCHAR(100) NULL,
  `marital_status` VARCHAR(100) NULL,
  `age_group_key` INT NULL,
  PRIMARY KEY (`employee_demo_key`),
  UNIQUE KEY `uq_dim_employee_demo` (`gender`, `marital_status`, `age_group_key`),
  CONSTRAINT `fk_dim_employee_demo_age_group_key` FOREIGN KEY (`age_group_key`) REFERENCES `dim_age_group` (`age_group_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_education` (
  `education_key` INT NOT NULL AUTO_INCREMENT,
  `education` INT NULL,
  `education_field_key` INT NULL,
  PRIMARY KEY (`education_key`),
  UNIQUE KEY `uq_dim_education` (`education`, `education_field_key`),
  CONSTRAINT `fk_dim_education_education_field_key` FOREIGN KEY (`education_field_key`) REFERENCES `dim_education_field` (`education_field_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_job` (
  `job_key` INT NOT NULL AUTO_INCREMENT,
  `job_role` VARCHAR(100) NULL,
  `job_level` INT NULL,
  `department_key` INT NULL,
  PRIMARY KEY (`job_key`),
  UNIQUE KEY `uq_dim_job` (`job_role`, `job_level`, `department_key`),
  CONSTRAINT `fk_dim_job_department_key` FOREIGN KEY (`department_key`) REFERENCES `dim_department` (`department_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_work_profile` (
  `work_profile_key` INT NOT NULL AUTO_INCREMENT,
  `business_travel` VARCHAR(100) NULL,
  `over_time` VARCHAR(100) NULL,
  PRIMARY KEY (`work_profile_key`),
  UNIQUE KEY `uq_dim_work_profile` (`business_travel`, `over_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_salary_slab` (
  `salary_slab_key` INT NOT NULL AUTO_INCREMENT,
  `salary_slab` VARCHAR(100) NULL,
  PRIMARY KEY (`salary_slab_key`),
  UNIQUE KEY `uq_dim_salary_slab` (`salary_slab`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_employee_hr` (
  `fact_employee_hr_key` BIGINT NOT NULL AUTO_INCREMENT,
  `employee_demo_key` INT NULL,
  `education_key` INT NULL,
  `job_key` INT NULL,
  `work_profile_key` INT NULL,
  `salary_slab_key` INT NULL,
  `emp_id` VARCHAR(100) NULL,
  `age` INT NULL,
  `attrition_flag` TINYINT NULL,
  `daily_rate` INT NULL,
  `hourly_rate` INT NULL,
  `monthly_rate` INT NULL,
  `monthly_income` INT NULL,
  `distance_from_home` INT NULL,
  `num_companies_worked` INT NULL,
  `percent_salary_hike` INT NULL,
  `performance_rating` INT NULL,
  `environment_satisfaction` INT NULL,
  `job_involvement` INT NULL,
  `job_satisfaction` INT NULL,
  `relationship_satisfaction` INT NULL,
  `work_life_balance` INT NULL,
  `stock_option_level` INT NULL,
  `total_working_years` INT NULL,
  `training_times_last_year` INT NULL,
  `years_at_company` INT NULL,
  `years_in_current_role` INT NULL,
  `years_since_last_promotion` INT NULL,
  `years_with_curr_manager` INT NULL,
  PRIMARY KEY (`fact_employee_hr_key`),
  CONSTRAINT `fk_fact_employee_hr_employee_demo_key` FOREIGN KEY (`employee_demo_key`) REFERENCES `dim_employee_demo` (`employee_demo_key`),
  CONSTRAINT `fk_fact_employee_hr_education_key` FOREIGN KEY (`education_key`) REFERENCES `dim_education` (`education_key`),
  CONSTRAINT `fk_fact_employee_hr_job_key` FOREIGN KEY (`job_key`) REFERENCES `dim_job` (`job_key`),
  CONSTRAINT `fk_fact_employee_hr_work_profile_key` FOREIGN KEY (`work_profile_key`) REFERENCES `dim_work_profile` (`work_profile_key`),
  CONSTRAINT `fk_fact_employee_hr_salary_slab_key` FOREIGN KEY (`salary_slab_key`) REFERENCES `dim_salary_slab` (`salary_slab_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL ------------------------------------------------------------

-- dim_age_group
INSERT INTO `dim_age_group` (`age_group`)
SELECT DISTINCT
  NULLIF(TRIM(s.`AgeGroup`), '')
FROM `dmbi_hr_analytics_stg`.`stg_hr_analytics` s;

-- dim_education_field
INSERT INTO `dim_education_field` (`education_field`)
SELECT DISTINCT
  NULLIF(TRIM(s.`EducationField`), '')
FROM `dmbi_hr_analytics_stg`.`stg_hr_analytics` s;

-- dim_department
INSERT INTO `dim_department` (`department`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Department`), '')
FROM `dmbi_hr_analytics_stg`.`stg_hr_analytics` s;

-- dim_employee_demo
INSERT INTO `dim_employee_demo` (`gender`, `marital_status`, `age_group_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Gender`), ''),
  NULLIF(TRIM(s.`MaritalStatus`), ''),
  x1.`age_group_key`
FROM `dmbi_hr_analytics_stg`.`stg_hr_analytics` s
LEFT JOIN `dim_age_group` x1 ON x1.`age_group` <=> NULLIF(TRIM(s.`AgeGroup`), '');

-- dim_education
INSERT INTO `dim_education` (`education`, `education_field_key`)
SELECT DISTINCT
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Education`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  x1.`education_field_key`
FROM `dmbi_hr_analytics_stg`.`stg_hr_analytics` s
LEFT JOIN `dim_education_field` x1 ON x1.`education_field` <=> NULLIF(TRIM(s.`EducationField`), '');

-- dim_job
INSERT INTO `dim_job` (`job_role`, `job_level`, `department_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`JobRole`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`JobLevel`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  x1.`department_key`
FROM `dmbi_hr_analytics_stg`.`stg_hr_analytics` s
LEFT JOIN `dim_department` x1 ON x1.`department` <=> NULLIF(TRIM(s.`Department`), '');

-- dim_work_profile
INSERT INTO `dim_work_profile` (`business_travel`, `over_time`)
SELECT DISTINCT
  NULLIF(TRIM(s.`BusinessTravel`), ''),
  NULLIF(TRIM(s.`OverTime`), '')
FROM `dmbi_hr_analytics_stg`.`stg_hr_analytics` s;

-- dim_salary_slab
INSERT INTO `dim_salary_slab` (`salary_slab`)
SELECT DISTINCT
  NULLIF(TRIM(s.`SalarySlab`), '')
FROM `dmbi_hr_analytics_stg`.`stg_hr_analytics` s;

-- fact_employee_hr
INSERT INTO `fact_employee_hr` (`employee_demo_key`, `education_key`, `job_key`, `work_profile_key`, `salary_slab_key`, `emp_id`, `age`, `attrition_flag`, `daily_rate`, `hourly_rate`, `monthly_rate`, `monthly_income`, `distance_from_home`, `num_companies_worked`, `percent_salary_hike`, `performance_rating`, `environment_satisfaction`, `job_involvement`, `job_satisfaction`, `relationship_satisfaction`, `work_life_balance`, `stock_option_level`, `total_working_years`, `training_times_last_year`, `years_at_company`, `years_in_current_role`, `years_since_last_promotion`, `years_with_curr_manager`)
SELECT
  d1.`employee_demo_key`,
  d2.`education_key`,
  d3.`job_key`,
  d4.`work_profile_key`,
  d5.`salary_slab_key`,
  NULLIF(TRIM(s.`EmpID`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CASE WHEN UPPER(TRIM(s.`Attrition`)) IN ('YES','Y','TRUE','1') THEN 1 ELSE 0 END,
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`DailyRate`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`HourlyRate`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`MonthlyRate`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`MonthlyIncome`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`DistanceFromHome`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`NumCompaniesWorked`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`PercentSalaryHike`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`PerformanceRating`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`EnvironmentSatisfaction`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`JobInvolvement`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`JobSatisfaction`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`RelationshipSatisfaction`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`WorkLifeBalance`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`StockOptionLevel`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`TotalWorkingYears`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`TrainingTimesLastYear`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`YearsAtCompany`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`YearsInCurrentRole`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`YearsSinceLastPromotion`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`YearsWithCurrManager`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `dmbi_hr_analytics_stg`.`stg_hr_analytics` s
LEFT JOIN `dim_age_group` x1 ON x1.`age_group` <=> NULLIF(TRIM(s.`AgeGroup`), '')
LEFT JOIN `dim_employee_demo` d1 ON d1.`gender` <=> NULLIF(TRIM(s.`Gender`), '')
       AND d1.`marital_status` <=> NULLIF(TRIM(s.`MaritalStatus`), '')
       AND d1.`age_group_key` <=> x1.`age_group_key`
LEFT JOIN `dim_education_field` x2 ON x2.`education_field` <=> NULLIF(TRIM(s.`EducationField`), '')
LEFT JOIN `dim_education` d2 ON d2.`education` <=> CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Education`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
       AND d2.`education_field_key` <=> x2.`education_field_key`
LEFT JOIN `dim_department` x3 ON x3.`department` <=> NULLIF(TRIM(s.`Department`), '')
LEFT JOIN `dim_job` d3 ON d3.`job_role` <=> NULLIF(TRIM(s.`JobRole`), '')
       AND d3.`job_level` <=> CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`JobLevel`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
       AND d3.`department_key` <=> x3.`department_key`
LEFT JOIN `dim_work_profile` d4 ON d4.`business_travel` <=> NULLIF(TRIM(s.`BusinessTravel`), '')
       AND d4.`over_time` <=> NULLIF(TRIM(s.`OverTime`), '')
LEFT JOIN `dim_salary_slab` d5 ON d5.`salary_slab` <=> NULLIF(TRIM(s.`SalarySlab`), '');

-- ---- PART C : QUICK CHECK ------------------------------------------------------
SELECT 'fact_employee_hr' AS table_name, COUNT(*) AS row_count FROM `fact_employee_hr` UNION ALL SELECT 'dim_age_group' AS table_name, COUNT(*) AS row_count FROM `dim_age_group` UNION ALL SELECT 'dim_education_field' AS table_name, COUNT(*) AS row_count FROM `dim_education_field` UNION ALL SELECT 'dim_department' AS table_name, COUNT(*) AS row_count FROM `dim_department` UNION ALL SELECT 'dim_employee_demo' AS table_name, COUNT(*) AS row_count FROM `dim_employee_demo` UNION ALL SELECT 'dim_education' AS table_name, COUNT(*) AS row_count FROM `dim_education` UNION ALL SELECT 'dim_job' AS table_name, COUNT(*) AS row_count FROM `dim_job` UNION ALL SELECT 'dim_work_profile' AS table_name, COUNT(*) AS row_count FROM `dim_work_profile` UNION ALL SELECT 'dim_salary_slab' AS table_name, COUNT(*) AS row_count FROM `dim_salary_slab`;
