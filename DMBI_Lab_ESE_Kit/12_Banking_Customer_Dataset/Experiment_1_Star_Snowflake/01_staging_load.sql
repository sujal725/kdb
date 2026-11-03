-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Banking_Customer_Dataset]
-- Creates schema `dmbi_banking_customer_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_banking_customer_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_banking_customer_stg`;

DROP TABLE IF EXISTS `stg_banking_customer`;
CREATE TABLE `stg_banking_customer` (
  `RowNumber` VARCHAR(255) NULL,
  `CustomerId` VARCHAR(255) NULL,
  `Surname` VARCHAR(255) NULL,
  `CreditScore` VARCHAR(255) NULL,
  `Geography` VARCHAR(255) NULL,
  `Gender` VARCHAR(255) NULL,
  `Age` VARCHAR(255) NULL,
  `Tenure` VARCHAR(255) NULL,
  `Balance` VARCHAR(255) NULL,
  `NumOfProducts` VARCHAR(255) NULL,
  `HasCrCard` VARCHAR(255) NULL,
  `IsActiveMember` VARCHAR(255) NULL,
  `EstimatedSalary` VARCHAR(255) NULL,
  `Exited` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Banking_Customer_Dataset/Churn_Modelling.csv'
INTO TABLE `stg_banking_customer`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Banking_Customer_Dataset/Churn_Modelling.csv' INTO TABLE `stg_banking_customer`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_banking_customer` SET `Exited` = REPLACE(`Exited`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_banking_customer`;
SELECT * FROM `stg_banking_customer` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`RowNumber` IS NULL OR TRIM(`RowNumber`) = '') AS `blank_row_number`,
  SUM(`CustomerId` IS NULL OR TRIM(`CustomerId`) = '') AS `blank_customer_id`,
  SUM(`Surname` IS NULL OR TRIM(`Surname`) = '') AS `blank_surname`,
  SUM(`CreditScore` IS NULL OR TRIM(`CreditScore`) = '') AS `blank_credit_score`,
  SUM(`Geography` IS NULL OR TRIM(`Geography`) = '') AS `blank_geography`,
  SUM(`Gender` IS NULL OR TRIM(`Gender`) = '') AS `blank_gender`,
  SUM(`Age` IS NULL OR TRIM(`Age`) = '') AS `blank_age`,
  SUM(`Tenure` IS NULL OR TRIM(`Tenure`) = '') AS `blank_tenure`,
  SUM(`Balance` IS NULL OR TRIM(`Balance`) = '') AS `blank_balance`,
  SUM(`NumOfProducts` IS NULL OR TRIM(`NumOfProducts`) = '') AS `blank_num_of_products`,
  SUM(`HasCrCard` IS NULL OR TRIM(`HasCrCard`) = '') AS `blank_has_cr_card`,
  SUM(`IsActiveMember` IS NULL OR TRIM(`IsActiveMember`) = '') AS `blank_is_active_member`,
  SUM(`EstimatedSalary` IS NULL OR TRIM(`EstimatedSalary`) = '') AS `blank_estimated_salary`,
  SUM(`Exited` IS NULL OR TRIM(`Exited`) = '') AS `blank_exited`
FROM `stg_banking_customer`;
