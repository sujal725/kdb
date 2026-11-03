-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Sales_Transaction_Dataset]
-- Creates schema `dmbi_sales_transaction_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_sales_transaction_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_sales_transaction_stg`;

DROP TABLE IF EXISTS `stg_sales_transaction`;
CREATE TABLE `stg_sales_transaction` (
  `TransactionNo` VARCHAR(255) NULL,
  `Date` VARCHAR(255) NULL,
  `ProductNo` VARCHAR(255) NULL,
  `ProductName` VARCHAR(255) NULL,
  `Price` VARCHAR(255) NULL,
  `Quantity` VARCHAR(255) NULL,
  `CustomerNo` VARCHAR(255) NULL,
  `Country` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Sales_Transaction_Dataset/Sales Transaction v.4a.csv'
INTO TABLE `stg_sales_transaction`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Sales_Transaction_Dataset/Sales Transaction v.4a.csv' INTO TABLE `stg_sales_transaction`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_sales_transaction` SET `Country` = REPLACE(`Country`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_sales_transaction`;
SELECT * FROM `stg_sales_transaction` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`TransactionNo` IS NULL OR TRIM(`TransactionNo`) = '') AS `blank_transaction_no`,
  SUM(`Date` IS NULL OR TRIM(`Date`) = '') AS `blank_date`,
  SUM(`ProductNo` IS NULL OR TRIM(`ProductNo`) = '') AS `blank_product_no`,
  SUM(`ProductName` IS NULL OR TRIM(`ProductName`) = '') AS `blank_product_name`,
  SUM(`Price` IS NULL OR TRIM(`Price`) = '') AS `blank_price`,
  SUM(`Quantity` IS NULL OR TRIM(`Quantity`) = '') AS `blank_quantity`,
  SUM(`CustomerNo` IS NULL OR TRIM(`CustomerNo`) = '') AS `blank_customer_no`,
  SUM(`Country` IS NULL OR TRIM(`Country`) = '') AS `blank_country`
FROM `stg_sales_transaction`;
