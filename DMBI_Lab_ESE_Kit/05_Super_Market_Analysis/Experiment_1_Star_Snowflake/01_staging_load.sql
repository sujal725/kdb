-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Super_Market_Analysis]
-- Creates schema `dmbi_super_market_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_super_market_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_super_market_stg`;

DROP TABLE IF EXISTS `stg_super_market`;
CREATE TABLE `stg_super_market` (
  `Invoice ID` VARCHAR(255) NULL,
  `Branch` VARCHAR(255) NULL,
  `City` VARCHAR(255) NULL,
  `Customer type` VARCHAR(255) NULL,
  `Gender` VARCHAR(255) NULL,
  `Product line` VARCHAR(255) NULL,
  `Unit price` VARCHAR(255) NULL,
  `Quantity` VARCHAR(255) NULL,
  `Tax 5%` VARCHAR(255) NULL,
  `Total` VARCHAR(255) NULL,
  `Date` VARCHAR(255) NULL,
  `Time` VARCHAR(255) NULL,
  `Payment` VARCHAR(255) NULL,
  `cogs` VARCHAR(255) NULL,
  `gross margin percentage` VARCHAR(255) NULL,
  `gross income` VARCHAR(255) NULL,
  `Rating` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Super_Market_Analysis/supermarket_sales.csv'
INTO TABLE `stg_super_market`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Super_Market_Analysis/supermarket_sales.csv' INTO TABLE `stg_super_market`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_super_market` SET `Rating` = REPLACE(`Rating`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_super_market`;
SELECT * FROM `stg_super_market` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`Invoice ID` IS NULL OR TRIM(`Invoice ID`) = '') AS `blank_invoice_id`,
  SUM(`Branch` IS NULL OR TRIM(`Branch`) = '') AS `blank_branch`,
  SUM(`City` IS NULL OR TRIM(`City`) = '') AS `blank_city`,
  SUM(`Customer type` IS NULL OR TRIM(`Customer type`) = '') AS `blank_customer_type`,
  SUM(`Gender` IS NULL OR TRIM(`Gender`) = '') AS `blank_gender`,
  SUM(`Product line` IS NULL OR TRIM(`Product line`) = '') AS `blank_product_line`,
  SUM(`Unit price` IS NULL OR TRIM(`Unit price`) = '') AS `blank_unit_price`,
  SUM(`Quantity` IS NULL OR TRIM(`Quantity`) = '') AS `blank_quantity`,
  SUM(`Tax 5%` IS NULL OR TRIM(`Tax 5%`) = '') AS `blank_tax_5`,
  SUM(`Total` IS NULL OR TRIM(`Total`) = '') AS `blank_total`,
  SUM(`Date` IS NULL OR TRIM(`Date`) = '') AS `blank_date`,
  SUM(`Time` IS NULL OR TRIM(`Time`) = '') AS `blank_time`,
  SUM(`Payment` IS NULL OR TRIM(`Payment`) = '') AS `blank_payment`,
  SUM(`cogs` IS NULL OR TRIM(`cogs`) = '') AS `blank_cogs`,
  SUM(`gross margin percentage` IS NULL OR TRIM(`gross margin percentage`) = '') AS `blank_gross_margin_percentage`,
  SUM(`gross income` IS NULL OR TRIM(`gross income`) = '') AS `blank_gross_income`,
  SUM(`Rating` IS NULL OR TRIM(`Rating`) = '') AS `blank_rating`
FROM `stg_super_market`;
