-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Ecommerce_sales]
-- Creates schema `dmbi_ecommerce_sales_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_ecommerce_sales_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_ecommerce_sales_stg`;

DROP TABLE IF EXISTS `stg_ecommerce_sales`;
CREATE TABLE `stg_ecommerce_sales` (
  `Date` VARCHAR(255) NULL,
  `Product_Category` VARCHAR(255) NULL,
  `Price` VARCHAR(255) NULL,
  `Discount` VARCHAR(255) NULL,
  `Customer_Segment` VARCHAR(255) NULL,
  `Marketing_Spend` VARCHAR(255) NULL,
  `Units_Sold` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Ecommerce_sales/ecommerce_sales.csv'
INTO TABLE `stg_ecommerce_sales`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Ecommerce_sales/ecommerce_sales.csv' INTO TABLE `stg_ecommerce_sales`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_ecommerce_sales` SET `Units_Sold` = REPLACE(`Units_Sold`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_ecommerce_sales`;
SELECT * FROM `stg_ecommerce_sales` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`Date` IS NULL OR TRIM(`Date`) = '') AS `blank_date`,
  SUM(`Product_Category` IS NULL OR TRIM(`Product_Category`) = '') AS `blank_product_category`,
  SUM(`Price` IS NULL OR TRIM(`Price`) = '') AS `blank_price`,
  SUM(`Discount` IS NULL OR TRIM(`Discount`) = '') AS `blank_discount`,
  SUM(`Customer_Segment` IS NULL OR TRIM(`Customer_Segment`) = '') AS `blank_customer_segment`,
  SUM(`Marketing_Spend` IS NULL OR TRIM(`Marketing_Spend`) = '') AS `blank_marketing_spend`,
  SUM(`Units_Sold` IS NULL OR TRIM(`Units_Sold`) = '') AS `blank_units_sold`
FROM `stg_ecommerce_sales`;
