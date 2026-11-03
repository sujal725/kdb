-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Employee]
-- Creates schema `dmbi_employee_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_employee_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_employee_stg`;

DROP TABLE IF EXISTS `stg_employee`;
CREATE TABLE `stg_employee` (
  `Education` VARCHAR(255) NULL,
  `JoiningYear` VARCHAR(255) NULL,
  `City` VARCHAR(255) NULL,
  `PaymentTier` VARCHAR(255) NULL,
  `Age` VARCHAR(255) NULL,
  `Gender` VARCHAR(255) NULL,
  `EverBenched` VARCHAR(255) NULL,
  `ExperienceInCurrentDomain` VARCHAR(255) NULL,
  `LeaveOrNot` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Employee/Employee.csv'
INTO TABLE `stg_employee`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Employee/Employee.csv' INTO TABLE `stg_employee`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_employee` SET `LeaveOrNot` = REPLACE(`LeaveOrNot`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_employee`;
SELECT * FROM `stg_employee` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`Education` IS NULL OR TRIM(`Education`) = '') AS `blank_education`,
  SUM(`JoiningYear` IS NULL OR TRIM(`JoiningYear`) = '') AS `blank_joining_year`,
  SUM(`City` IS NULL OR TRIM(`City`) = '') AS `blank_city`,
  SUM(`PaymentTier` IS NULL OR TRIM(`PaymentTier`) = '') AS `blank_payment_tier`,
  SUM(`Age` IS NULL OR TRIM(`Age`) = '') AS `blank_age`,
  SUM(`Gender` IS NULL OR TRIM(`Gender`) = '') AS `blank_gender`,
  SUM(`EverBenched` IS NULL OR TRIM(`EverBenched`) = '') AS `blank_ever_benched`,
  SUM(`ExperienceInCurrentDomain` IS NULL OR TRIM(`ExperienceInCurrentDomain`) = '') AS `blank_experience_in_current_domain`,
  SUM(`LeaveOrNot` IS NULL OR TRIM(`LeaveOrNot`) = '') AS `blank_leave_or_not`
FROM `stg_employee`;
