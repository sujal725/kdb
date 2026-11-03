-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [HR_Analytics_Dataset]
-- Creates schema `dmbi_hr_analytics_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_hr_analytics_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_hr_analytics_stg`;

DROP TABLE IF EXISTS `stg_hr_analytics`;
CREATE TABLE `stg_hr_analytics` (
  `EmpID` VARCHAR(255) NULL,
  `Age` VARCHAR(255) NULL,
  `AgeGroup` VARCHAR(255) NULL,
  `Attrition` VARCHAR(255) NULL,
  `BusinessTravel` VARCHAR(255) NULL,
  `DailyRate` VARCHAR(255) NULL,
  `Department` VARCHAR(255) NULL,
  `DistanceFromHome` VARCHAR(255) NULL,
  `Education` VARCHAR(255) NULL,
  `EducationField` VARCHAR(255) NULL,
  `EmployeeCount` VARCHAR(255) NULL,
  `EmployeeNumber` VARCHAR(255) NULL,
  `EnvironmentSatisfaction` VARCHAR(255) NULL,
  `Gender` VARCHAR(255) NULL,
  `HourlyRate` VARCHAR(255) NULL,
  `JobInvolvement` VARCHAR(255) NULL,
  `JobLevel` VARCHAR(255) NULL,
  `JobRole` VARCHAR(255) NULL,
  `JobSatisfaction` VARCHAR(255) NULL,
  `MaritalStatus` VARCHAR(255) NULL,
  `MonthlyIncome` VARCHAR(255) NULL,
  `SalarySlab` VARCHAR(255) NULL,
  `MonthlyRate` VARCHAR(255) NULL,
  `NumCompaniesWorked` VARCHAR(255) NULL,
  `Over18` VARCHAR(255) NULL,
  `OverTime` VARCHAR(255) NULL,
  `PercentSalaryHike` VARCHAR(255) NULL,
  `PerformanceRating` VARCHAR(255) NULL,
  `RelationshipSatisfaction` VARCHAR(255) NULL,
  `StandardHours` VARCHAR(255) NULL,
  `StockOptionLevel` VARCHAR(255) NULL,
  `TotalWorkingYears` VARCHAR(255) NULL,
  `TrainingTimesLastYear` VARCHAR(255) NULL,
  `WorkLifeBalance` VARCHAR(255) NULL,
  `YearsAtCompany` VARCHAR(255) NULL,
  `YearsInCurrentRole` VARCHAR(255) NULL,
  `YearsSinceLastPromotion` VARCHAR(255) NULL,
  `YearsWithCurrManager` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/HR_Analytics_Dataset/HR_Analytics.csv'
INTO TABLE `stg_hr_analytics`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/HR_Analytics_Dataset/HR_Analytics.csv' INTO TABLE `stg_hr_analytics`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_hr_analytics` SET `YearsWithCurrManager` = REPLACE(`YearsWithCurrManager`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_hr_analytics`;
SELECT * FROM `stg_hr_analytics` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`EmpID` IS NULL OR TRIM(`EmpID`) = '') AS `blank_emp_id`,
  SUM(`Age` IS NULL OR TRIM(`Age`) = '') AS `blank_age`,
  SUM(`AgeGroup` IS NULL OR TRIM(`AgeGroup`) = '') AS `blank_age_group`,
  SUM(`Attrition` IS NULL OR TRIM(`Attrition`) = '') AS `blank_attrition`,
  SUM(`BusinessTravel` IS NULL OR TRIM(`BusinessTravel`) = '') AS `blank_business_travel`,
  SUM(`DailyRate` IS NULL OR TRIM(`DailyRate`) = '') AS `blank_daily_rate`,
  SUM(`Department` IS NULL OR TRIM(`Department`) = '') AS `blank_department`,
  SUM(`DistanceFromHome` IS NULL OR TRIM(`DistanceFromHome`) = '') AS `blank_distance_from_home`,
  SUM(`Education` IS NULL OR TRIM(`Education`) = '') AS `blank_education`,
  SUM(`EducationField` IS NULL OR TRIM(`EducationField`) = '') AS `blank_education_field`,
  SUM(`EmployeeCount` IS NULL OR TRIM(`EmployeeCount`) = '') AS `blank_employee_count`,
  SUM(`EmployeeNumber` IS NULL OR TRIM(`EmployeeNumber`) = '') AS `blank_employee_number`,
  SUM(`EnvironmentSatisfaction` IS NULL OR TRIM(`EnvironmentSatisfaction`) = '') AS `blank_environment_satisfaction`,
  SUM(`Gender` IS NULL OR TRIM(`Gender`) = '') AS `blank_gender`,
  SUM(`HourlyRate` IS NULL OR TRIM(`HourlyRate`) = '') AS `blank_hourly_rate`,
  SUM(`JobInvolvement` IS NULL OR TRIM(`JobInvolvement`) = '') AS `blank_job_involvement`,
  SUM(`JobLevel` IS NULL OR TRIM(`JobLevel`) = '') AS `blank_job_level`,
  SUM(`JobRole` IS NULL OR TRIM(`JobRole`) = '') AS `blank_job_role`,
  SUM(`JobSatisfaction` IS NULL OR TRIM(`JobSatisfaction`) = '') AS `blank_job_satisfaction`,
  SUM(`MaritalStatus` IS NULL OR TRIM(`MaritalStatus`) = '') AS `blank_marital_status`,
  SUM(`MonthlyIncome` IS NULL OR TRIM(`MonthlyIncome`) = '') AS `blank_monthly_income`,
  SUM(`SalarySlab` IS NULL OR TRIM(`SalarySlab`) = '') AS `blank_salary_slab`,
  SUM(`MonthlyRate` IS NULL OR TRIM(`MonthlyRate`) = '') AS `blank_monthly_rate`,
  SUM(`NumCompaniesWorked` IS NULL OR TRIM(`NumCompaniesWorked`) = '') AS `blank_num_companies_worked`,
  SUM(`Over18` IS NULL OR TRIM(`Over18`) = '') AS `blank_over18`,
  SUM(`OverTime` IS NULL OR TRIM(`OverTime`) = '') AS `blank_over_time`,
  SUM(`PercentSalaryHike` IS NULL OR TRIM(`PercentSalaryHike`) = '') AS `blank_percent_salary_hike`,
  SUM(`PerformanceRating` IS NULL OR TRIM(`PerformanceRating`) = '') AS `blank_performance_rating`,
  SUM(`RelationshipSatisfaction` IS NULL OR TRIM(`RelationshipSatisfaction`) = '') AS `blank_relationship_satisfaction`,
  SUM(`StandardHours` IS NULL OR TRIM(`StandardHours`) = '') AS `blank_standard_hours`,
  SUM(`StockOptionLevel` IS NULL OR TRIM(`StockOptionLevel`) = '') AS `blank_stock_option_level`,
  SUM(`TotalWorkingYears` IS NULL OR TRIM(`TotalWorkingYears`) = '') AS `blank_total_working_years`,
  SUM(`TrainingTimesLastYear` IS NULL OR TRIM(`TrainingTimesLastYear`) = '') AS `blank_training_times_last_year`,
  SUM(`WorkLifeBalance` IS NULL OR TRIM(`WorkLifeBalance`) = '') AS `blank_work_life_balance`,
  SUM(`YearsAtCompany` IS NULL OR TRIM(`YearsAtCompany`) = '') AS `blank_years_at_company`,
  SUM(`YearsInCurrentRole` IS NULL OR TRIM(`YearsInCurrentRole`) = '') AS `blank_years_in_current_role`,
  SUM(`YearsSinceLastPromotion` IS NULL OR TRIM(`YearsSinceLastPromotion`) = '') AS `blank_years_since_last_promotion`,
  SUM(`YearsWithCurrManager` IS NULL OR TRIM(`YearsWithCurrManager`) = '') AS `blank_years_with_curr_manager`
FROM `stg_hr_analytics`;
