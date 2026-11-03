-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Online_Orders_Dataset]
-- Creates schema `dmbi_online_orders_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_online_orders_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_online_orders_stg`;

DROP TABLE IF EXISTS `stg_online_orders`;
CREATE TABLE `stg_online_orders` (
  `Transaction ID` VARCHAR(255) NULL,
  `Date` VARCHAR(255) NULL,
  `Product Category` VARCHAR(255) NULL,
  `Product Name` VARCHAR(255) NULL,
  `Units Sold` VARCHAR(255) NULL,
  `Unit Price` VARCHAR(255) NULL,
  `Total Revenue` VARCHAR(255) NULL,
  `Region` VARCHAR(255) NULL,
  `Payment Method` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Online_Orders_Dataset/Online Sales Data.csv'
INTO TABLE `stg_online_orders`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Online_Orders_Dataset/Online Sales Data.csv' INTO TABLE `stg_online_orders`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_online_orders` SET `Payment Method` = REPLACE(`Payment Method`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_online_orders`;
SELECT * FROM `stg_online_orders` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`Transaction ID` IS NULL OR TRIM(`Transaction ID`) = '') AS `blank_transaction_id`,
  SUM(`Date` IS NULL OR TRIM(`Date`) = '') AS `blank_date`,
  SUM(`Product Category` IS NULL OR TRIM(`Product Category`) = '') AS `blank_product_category`,
  SUM(`Product Name` IS NULL OR TRIM(`Product Name`) = '') AS `blank_product_name`,
  SUM(`Units Sold` IS NULL OR TRIM(`Units Sold`) = '') AS `blank_units_sold`,
  SUM(`Unit Price` IS NULL OR TRIM(`Unit Price`) = '') AS `blank_unit_price`,
  SUM(`Total Revenue` IS NULL OR TRIM(`Total Revenue`) = '') AS `blank_total_revenue`,
  SUM(`Region` IS NULL OR TRIM(`Region`) = '') AS `blank_region`,
  SUM(`Payment Method` IS NULL OR TRIM(`Payment Method`) = '') AS `blank_payment_method`
FROM `stg_online_orders`;
