-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Inventory_and_Stock_Dataset]
-- Creates schema `dmbi_inventory_stock_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_inventory_stock_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_inventory_stock_stg`;

DROP TABLE IF EXISTS `stg_inventory_stock`;
CREATE TABLE `stg_inventory_stock` (
  `Date` VARCHAR(255) NULL,
  `Store ID` VARCHAR(255) NULL,
  `Product ID` VARCHAR(255) NULL,
  `Category` VARCHAR(255) NULL,
  `Region` VARCHAR(255) NULL,
  `Inventory Level` VARCHAR(255) NULL,
  `Units Sold` VARCHAR(255) NULL,
  `Units Ordered` VARCHAR(255) NULL,
  `Demand Forecast` VARCHAR(255) NULL,
  `Price` VARCHAR(255) NULL,
  `Discount` VARCHAR(255) NULL,
  `Weather Condition` VARCHAR(255) NULL,
  `Holiday/Promotion` VARCHAR(255) NULL,
  `Competitor Pricing` VARCHAR(255) NULL,
  `Seasonality` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Inventory_and_Stock_Dataset/retail_store_inventory.csv'
INTO TABLE `stg_inventory_stock`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Inventory_and_Stock_Dataset/retail_store_inventory.csv' INTO TABLE `stg_inventory_stock`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_inventory_stock` SET `Seasonality` = REPLACE(`Seasonality`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_inventory_stock`;
SELECT * FROM `stg_inventory_stock` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`Date` IS NULL OR TRIM(`Date`) = '') AS `blank_date`,
  SUM(`Store ID` IS NULL OR TRIM(`Store ID`) = '') AS `blank_store_id`,
  SUM(`Product ID` IS NULL OR TRIM(`Product ID`) = '') AS `blank_product_id`,
  SUM(`Category` IS NULL OR TRIM(`Category`) = '') AS `blank_category`,
  SUM(`Region` IS NULL OR TRIM(`Region`) = '') AS `blank_region`,
  SUM(`Inventory Level` IS NULL OR TRIM(`Inventory Level`) = '') AS `blank_inventory_level`,
  SUM(`Units Sold` IS NULL OR TRIM(`Units Sold`) = '') AS `blank_units_sold`,
  SUM(`Units Ordered` IS NULL OR TRIM(`Units Ordered`) = '') AS `blank_units_ordered`,
  SUM(`Demand Forecast` IS NULL OR TRIM(`Demand Forecast`) = '') AS `blank_demand_forecast`,
  SUM(`Price` IS NULL OR TRIM(`Price`) = '') AS `blank_price`,
  SUM(`Discount` IS NULL OR TRIM(`Discount`) = '') AS `blank_discount`,
  SUM(`Weather Condition` IS NULL OR TRIM(`Weather Condition`) = '') AS `blank_weather_condition`,
  SUM(`Holiday/Promotion` IS NULL OR TRIM(`Holiday/Promotion`) = '') AS `blank_holiday_promotion`,
  SUM(`Competitor Pricing` IS NULL OR TRIM(`Competitor Pricing`) = '') AS `blank_competitor_pricing`,
  SUM(`Seasonality` IS NULL OR TRIM(`Seasonality`) = '') AS `blank_seasonality`
FROM `stg_inventory_stock`;
