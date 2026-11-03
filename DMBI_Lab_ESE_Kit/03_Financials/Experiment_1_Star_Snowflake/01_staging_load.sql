-- ========================================================================
-- EXPERIMENT 1 - STEP 1 : STAGING TABLE + LOAD CSV  [Financials]
-- Creates schema `dmbi_financials_stg` and loads the raw CSV (all columns as text).
-- Cleaning / typing is done later in the ETL of the star and snowflake scripts.
-- EDIT the file path in the LOAD DATA line before running.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_financials_stg` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_financials_stg`;

DROP TABLE IF EXISTS `stg_financials`;
CREATE TABLE `stg_financials` (
  `Segment` VARCHAR(255) NULL,
  `Country` VARCHAR(255) NULL,
  `Product` VARCHAR(255) NULL,
  `Discount Band` VARCHAR(255) NULL,
  `Units Sold` VARCHAR(255) NULL,
  `Manufacturing Price` VARCHAR(255) NULL,
  `Sale Price` VARCHAR(255) NULL,
  `Gross Sales` VARCHAR(255) NULL,
  `Discounts` VARCHAR(255) NULL,
  `Sales` VARCHAR(255) NULL,
  `COGS` VARCHAR(255) NULL,
  `Profit` VARCHAR(255) NULL,
  `Date` VARCHAR(255) NULL,
  `Month Number` VARCHAR(255) NULL,
  `Month Name` VARCHAR(255) NULL,
  `Year` VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- LOAD THE CSV -------------------------------------------------------
-- Needs the client started with:  mysql -u root -p --local-infile=1
-- (Workbench: Edit connection > Advanced > Others > add line  OPT_LOCAL_INFILE=1)
-- If MySQL says 'local_infile disabled', run once as admin:  SET GLOBAL local_infile = 1;
-- Use FORWARD slashes even on Windows. Replace YOUR_USER and the folder name.
-- No luck with LOAD DATA?  Use Workbench: right click table > Table Data Import Wizard.
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/Users/YOUR_USER/Music/Financials/Financials.csv'
INTO TABLE `stg_financials`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
-- LINUX / macOS alternative (comment the Windows line above, uncomment this block):
-- LOAD DATA LOCAL INFILE '/home/YOUR_USER/Music/Financials/Financials.csv' INTO TABLE `stg_financials`
-- CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- Windows files end lines with CR+LF: remove the stray CR from the last column.
SET SQL_SAFE_UPDATES = 0;
UPDATE `stg_financials` SET `Year` = REPLACE(`Year`, CHAR(13), '');
SET SQL_SAFE_UPDATES = 1;

-- ---- CHECK THE LOAD -------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM `stg_financials`;
SELECT * FROM `stg_financials` LIMIT 5;

-- ---- DATA PROFILE: blank/missing values per column -------------------------
SELECT COUNT(*) AS total_rows,
  SUM(`Segment` IS NULL OR TRIM(`Segment`) = '') AS `blank_segment`,
  SUM(`Country` IS NULL OR TRIM(`Country`) = '') AS `blank_country`,
  SUM(`Product` IS NULL OR TRIM(`Product`) = '') AS `blank_product`,
  SUM(`Discount Band` IS NULL OR TRIM(`Discount Band`) = '') AS `blank_discount_band`,
  SUM(`Units Sold` IS NULL OR TRIM(`Units Sold`) = '') AS `blank_units_sold`,
  SUM(`Manufacturing Price` IS NULL OR TRIM(`Manufacturing Price`) = '') AS `blank_manufacturing_price`,
  SUM(`Sale Price` IS NULL OR TRIM(`Sale Price`) = '') AS `blank_sale_price`,
  SUM(`Gross Sales` IS NULL OR TRIM(`Gross Sales`) = '') AS `blank_gross_sales`,
  SUM(`Discounts` IS NULL OR TRIM(`Discounts`) = '') AS `blank_discounts`,
  SUM(`Sales` IS NULL OR TRIM(`Sales`) = '') AS `blank_sales`,
  SUM(`COGS` IS NULL OR TRIM(`COGS`) = '') AS `blank_cogs`,
  SUM(`Profit` IS NULL OR TRIM(`Profit`) = '') AS `blank_profit`,
  SUM(`Date` IS NULL OR TRIM(`Date`) = '') AS `blank_date`,
  SUM(`Month Number` IS NULL OR TRIM(`Month Number`) = '') AS `blank_month_number`,
  SUM(`Month Name` IS NULL OR TRIM(`Month Name`) = '') AS `blank_month_name`,
  SUM(`Year` IS NULL OR TRIM(`Year`) = '') AS `blank_year`
FROM `stg_financials`;
