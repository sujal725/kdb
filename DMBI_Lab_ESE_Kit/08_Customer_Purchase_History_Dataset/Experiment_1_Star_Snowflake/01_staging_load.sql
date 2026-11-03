-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Customer_Purchase_History_Dataset]
-- Creates schema `dmbi_customer_purchase_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_customer_purchase_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_customer_purchase_stg`;

DROP TABLE IF EXISTS `stg_customer_purchase`;
CREATE TABLE `stg_customer_purchase` (
  `user_id` VARCHAR(255) NULL,
  `age` VARCHAR(255) NULL,
  `annual_income` VARCHAR(255) NULL,
  `purchase_amount` VARCHAR(255) NULL,
  `loyalty_score` VARCHAR(255) NULL,
  `region` VARCHAR(255) NULL,
  `purchase_frequency` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Customer_Purchase_History_Dataset/Customer Purchasing Behaviors.csv'
INTO TABLE `stg_customer_purchase`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Customer_Purchase_History_Dataset/Customer Purchasing Behaviors.csv' INTO TABLE `stg_customer_purchase`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_customer_purchase` SET `purchase_frequency` = REPLACE(`purchase_frequency`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_customer_purchase`;
SELECT * FROM `stg_customer_purchase` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`user_id` IS NULL OR TRIM(`user_id`) = '') AS `blank_user_id`,
  SUM(`age` IS NULL OR TRIM(`age`) = '') AS `blank_age`,
  SUM(`annual_income` IS NULL OR TRIM(`annual_income`) = '') AS `blank_annual_income`,
  SUM(`purchase_amount` IS NULL OR TRIM(`purchase_amount`) = '') AS `blank_purchase_amount`,
  SUM(`loyalty_score` IS NULL OR TRIM(`loyalty_score`) = '') AS `blank_loyalty_score`,
  SUM(`region` IS NULL OR TRIM(`region`) = '') AS `blank_region`,
  SUM(`purchase_frequency` IS NULL OR TRIM(`purchase_frequency`) = '') AS `blank_purchase_frequency`
FROM `stg_customer_purchase`;
