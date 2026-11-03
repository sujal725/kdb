-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Retail_sales]
-- Creates schema `dmbi_retail_sales_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_retail_sales_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_retail_sales_stg`;

DROP TABLE IF EXISTS `stg_retail_sales`;
CREATE TABLE `stg_retail_sales` (
  `Transaction ID` VARCHAR(255) NULL,
  `Date` VARCHAR(255) NULL,
  `Customer ID` VARCHAR(255) NULL,
  `Gender` VARCHAR(255) NULL,
  `Age` VARCHAR(255) NULL,
  `Product Category` VARCHAR(255) NULL,
  `Quantity` VARCHAR(255) NULL,
  `Price per Unit` VARCHAR(255) NULL,
  `Total Amount` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Retail_sales/retail_sales_dataset.csv'
INTO TABLE `stg_retail_sales`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Retail_sales/retail_sales_dataset.csv' INTO TABLE `stg_retail_sales`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_retail_sales` SET `Total Amount` = REPLACE(`Total Amount`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_retail_sales`;
SELECT * FROM `stg_retail_sales` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`Transaction ID` IS NULL OR TRIM(`Transaction ID`) = '') AS `blank_transaction_id`,
  SUM(`Date` IS NULL OR TRIM(`Date`) = '') AS `blank_date`,
  SUM(`Customer ID` IS NULL OR TRIM(`Customer ID`) = '') AS `blank_customer_id`,
  SUM(`Gender` IS NULL OR TRIM(`Gender`) = '') AS `blank_gender`,
  SUM(`Age` IS NULL OR TRIM(`Age`) = '') AS `blank_age`,
  SUM(`Product Category` IS NULL OR TRIM(`Product Category`) = '') AS `blank_product_category`,
  SUM(`Quantity` IS NULL OR TRIM(`Quantity`) = '') AS `blank_quantity`,
  SUM(`Price per Unit` IS NULL OR TRIM(`Price per Unit`) = '') AS `blank_price_per_unit`,
  SUM(`Total Amount` IS NULL OR TRIM(`Total Amount`) = '') AS `blank_total_amount`
FROM `stg_retail_sales`;
