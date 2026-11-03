-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Retail_Transactions_Dataset]
-- Creates schema `dmbi_retail_transactions_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_retail_transactions_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_retail_transactions_stg`;

DROP TABLE IF EXISTS `stg_retail_transactions`;
CREATE TABLE `stg_retail_transactions` (
  `Transaction_ID` VARCHAR(255) NULL,
  `Date` VARCHAR(255) NULL,
  `Customer_Name` VARCHAR(255) NULL,
  `Product` VARCHAR(500) NULL,
  `Total_Items` VARCHAR(255) NULL,
  `Total_Cost` VARCHAR(255) NULL,
  `Payment_Method` VARCHAR(255) NULL,
  `City` VARCHAR(255) NULL,
  `Store_Type` VARCHAR(255) NULL,
  `Discount_Applied` VARCHAR(255) NULL,
  `Customer_Category` VARCHAR(255) NULL,
  `Season` VARCHAR(255) NULL,
  `Promotion` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Retail_Transactions_Dataset/Retail_Transaction_Dataset.csv'
INTO TABLE `stg_retail_transactions`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Retail_Transactions_Dataset/Retail_Transaction_Dataset.csv' INTO TABLE `stg_retail_transactions`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_retail_transactions` SET `Promotion` = REPLACE(`Promotion`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_retail_transactions`;
SELECT * FROM `stg_retail_transactions` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`Transaction_ID` IS NULL OR TRIM(`Transaction_ID`) = '') AS `blank_transaction_id`,
  SUM(`Date` IS NULL OR TRIM(`Date`) = '') AS `blank_date`,
  SUM(`Customer_Name` IS NULL OR TRIM(`Customer_Name`) = '') AS `blank_customer_name`,
  SUM(`Product` IS NULL OR TRIM(`Product`) = '') AS `blank_product`,
  SUM(`Total_Items` IS NULL OR TRIM(`Total_Items`) = '') AS `blank_total_items`,
  SUM(`Total_Cost` IS NULL OR TRIM(`Total_Cost`) = '') AS `blank_total_cost`,
  SUM(`Payment_Method` IS NULL OR TRIM(`Payment_Method`) = '') AS `blank_payment_method`,
  SUM(`City` IS NULL OR TRIM(`City`) = '') AS `blank_city`,
  SUM(`Store_Type` IS NULL OR TRIM(`Store_Type`) = '') AS `blank_store_type`,
  SUM(`Discount_Applied` IS NULL OR TRIM(`Discount_Applied`) = '') AS `blank_discount_applied`,
  SUM(`Customer_Category` IS NULL OR TRIM(`Customer_Category`) = '') AS `blank_customer_category`,
  SUM(`Season` IS NULL OR TRIM(`Season`) = '') AS `blank_season`,
  SUM(`Promotion` IS NULL OR TRIM(`Promotion`) = '') AS `blank_promotion`
FROM `stg_retail_transactions`;
