-- ========================================================================
-- EXPERIMENT 1 - STEP 3 : SNOWFLAKE SCHEMA  [Inventory_and_Stock_Dataset]
-- Same fact table as the star schema; dimensions are NORMALISED into sub-dimensions.
-- Sub-dimensions here: dim_region, dim_category; date chain dim_date > dim_month > dim_quarter > dim_year
-- Run 01_staging_load.sql first. Requires MySQL 8.0+.
-- ========================================================================

CREATE DATABASE IF NOT EXISTS `dmbi_inventory_stock_snow` DEFAULT CHARACTER SET utf8mb4;
USE `dmbi_inventory_stock_snow`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `fact_inventory`;
DROP TABLE IF EXISTS `dim_date`;
DROP TABLE IF EXISTS `dim_month`;
DROP TABLE IF EXISTS `dim_quarter`;
DROP TABLE IF EXISTS `dim_year`;
DROP TABLE IF EXISTS `dim_region`;
DROP TABLE IF EXISTS `dim_category`;
DROP TABLE IF EXISTS `dim_store`;
DROP TABLE IF EXISTS `dim_product`;
DROP TABLE IF EXISTS `dim_weather`;
DROP TABLE IF EXISTS `dim_season`;
SET FOREIGN_KEY_CHECKS = 1;

-- ---- PART A : DDL (outer-most sub-dimensions first) ---------------------------

CREATE TABLE `dim_year` (
  `year_key` INT NOT NULL,
  `year_num` SMALLINT NULL,
  PRIMARY KEY (`year_key`),
  UNIQUE KEY `uq_dim_year` (`year_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_quarter` (
  `quarter_key` INT NOT NULL,
  `quarter_num` TINYINT NULL,
  `year_key` INT NULL,
  PRIMARY KEY (`quarter_key`),
  UNIQUE KEY `uq_dim_quarter` (`quarter_num`, `year_key`),
  CONSTRAINT `fk_dim_quarter_year_key` FOREIGN KEY (`year_key`) REFERENCES `dim_year` (`year_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_month` (
  `month_key` INT NOT NULL,
  `month_num` TINYINT NULL,
  `month_name` VARCHAR(10) NULL,
  `quarter_key` INT NULL,
  PRIMARY KEY (`month_key`),
  UNIQUE KEY `uq_dim_month` (`month_num`, `quarter_key`),
  CONSTRAINT `fk_dim_month_quarter_key` FOREIGN KEY (`quarter_key`) REFERENCES `dim_quarter` (`quarter_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_date` (
  `date_key` INT NOT NULL,
  `full_date` DATE NULL,
  `day_of_month` TINYINT NULL,
  `day_name` VARCHAR(10) NULL,
  `is_weekend` TINYINT NULL,
  `month_key` INT NULL,
  PRIMARY KEY (`date_key`),
  UNIQUE KEY `uq_dim_date` (`full_date`),
  CONSTRAINT `fk_dim_date_month_key` FOREIGN KEY (`month_key`) REFERENCES `dim_month` (`month_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_region` (
  `region_key` INT NOT NULL AUTO_INCREMENT,
  `region` VARCHAR(100) NULL,
  PRIMARY KEY (`region_key`),
  UNIQUE KEY `uq_dim_region` (`region`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_category` (
  `category_key` INT NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(100) NULL,
  PRIMARY KEY (`category_key`),
  UNIQUE KEY `uq_dim_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_store` (
  `store_key` INT NOT NULL AUTO_INCREMENT,
  `store_id` VARCHAR(100) NULL,
  `region_key` INT NULL,
  PRIMARY KEY (`store_key`),
  UNIQUE KEY `uq_dim_store` (`store_id`, `region_key`),
  CONSTRAINT `fk_dim_store_region_key` FOREIGN KEY (`region_key`) REFERENCES `dim_region` (`region_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_product` (
  `product_key` INT NOT NULL AUTO_INCREMENT,
  `product_id` VARCHAR(100) NULL,
  `category_key` INT NULL,
  PRIMARY KEY (`product_key`),
  UNIQUE KEY `uq_dim_product` (`product_id`, `category_key`),
  CONSTRAINT `fk_dim_product_category_key` FOREIGN KEY (`category_key`) REFERENCES `dim_category` (`category_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_weather` (
  `weather_key` INT NOT NULL AUTO_INCREMENT,
  `weather_condition` VARCHAR(100) NULL,
  PRIMARY KEY (`weather_key`),
  UNIQUE KEY `uq_dim_weather` (`weather_condition`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `dim_season` (
  `season_key` INT NOT NULL AUTO_INCREMENT,
  `seasonality` VARCHAR(100) NULL,
  PRIMARY KEY (`season_key`),
  UNIQUE KEY `uq_dim_season` (`seasonality`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `fact_inventory` (
  `fact_inventory_key` BIGINT NOT NULL AUTO_INCREMENT,
  `date_key` INT NULL,
  `store_key` INT NULL,
  `product_key` INT NULL,
  `weather_key` INT NULL,
  `season_key` INT NULL,
  `inventory_level` INT NULL,
  `units_sold` INT NULL,
  `units_ordered` INT NULL,
  `demand_forecast` DECIMAL(18,4) NULL,
  `price` DECIMAL(18,2) NULL,
  `discount` INT NULL,
  `holiday_promotion` INT NULL,
  `competitor_pricing` DECIMAL(18,2) NULL,
  `revenue` DECIMAL(18,2) NULL,
  `stock_gap` INT NULL,
  `forecast_error` DOUBLE NULL,
  PRIMARY KEY (`fact_inventory_key`),
  CONSTRAINT `fk_fact_inventory_date_key` FOREIGN KEY (`date_key`) REFERENCES `dim_date` (`date_key`),
  CONSTRAINT `fk_fact_inventory_store_key` FOREIGN KEY (`store_key`) REFERENCES `dim_store` (`store_key`),
  CONSTRAINT `fk_fact_inventory_product_key` FOREIGN KEY (`product_key`) REFERENCES `dim_product` (`product_key`),
  CONSTRAINT `fk_fact_inventory_weather_key` FOREIGN KEY (`weather_key`) REFERENCES `dim_weather` (`weather_key`),
  CONSTRAINT `fk_fact_inventory_season_key` FOREIGN KEY (`season_key`) REFERENCES `dim_season` (`season_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- PART B : ETL ------------------------------------------------------------

-- date hierarchy: year > quarter > month > date
INSERT INTO `dim_year` (year_key, year_num)
SELECT DISTINCT YEAR(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_quarter` (quarter_key, quarter_num, year_key)
SELECT DISTINCT YEAR(d) * 10 + QUARTER(d), QUARTER(d), YEAR(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_month` (month_key, month_num, month_name, quarter_key)
SELECT DISTINCT YEAR(d) * 100 + MONTH(d), MONTH(d), MONTHNAME(d), YEAR(d) * 10 + QUARTER(d) FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s) x WHERE d IS NOT NULL;

INSERT INTO `dim_date` (date_key, full_date, day_of_month, day_name, is_weekend, month_key)
SELECT DISTINCT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d),
       IF(DAYOFWEEK(d) IN (1, 7), 1, 0), YEAR(d) * 100 + MONTH(d)
FROM (SELECT DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')) AS d FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s) x WHERE d IS NOT NULL;

-- dim_region
INSERT INTO `dim_region` (`region`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Region`), '')
FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s;

-- dim_category
INSERT INTO `dim_category` (`category`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Category`), '')
FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s;

-- dim_store
INSERT INTO `dim_store` (`store_id`, `region_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Store ID`), ''),
  x1.`region_key`
FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s
LEFT JOIN `dim_region` x1 ON x1.`region` <=> NULLIF(TRIM(s.`Region`), '');

-- dim_product
INSERT INTO `dim_product` (`product_id`, `category_key`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Product ID`), ''),
  x1.`category_key`
FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s
LEFT JOIN `dim_category` x1 ON x1.`category` <=> NULLIF(TRIM(s.`Category`), '');

-- dim_weather
INSERT INTO `dim_weather` (`weather_condition`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Weather Condition`), '')
FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s;

-- dim_season
INSERT INTO `dim_season` (`seasonality`)
SELECT DISTINCT
  NULLIF(TRIM(s.`Seasonality`), '')
FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s;

-- fact_inventory
INSERT INTO `fact_inventory` (`date_key`, `store_key`, `product_key`, `weather_key`, `season_key`, `inventory_level`, `units_sold`, `units_ordered`, `demand_forecast`, `price`, `discount`, `holiday_promotion`, `competitor_pricing`, `revenue`, `stock_gap`, `forecast_error`)
SELECT
  CAST(DATE_FORMAT(DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')), '%Y%m%d') AS UNSIGNED),
  d1.`store_key`,
  d2.`product_key`,
  d3.`weather_key`,
  d4.`season_key`,
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Inventory Level`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Ordered`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Demand Forecast`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Holiday/Promotion`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Competitor Pricing`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))) * (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)),
  (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Inventory Level`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) - (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)),
  (CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)) - (CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Demand Forecast`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)))
FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock` s
LEFT JOIN `dim_region` x1 ON x1.`region` <=> NULLIF(TRIM(s.`Region`), '')
LEFT JOIN `dim_store` d1 ON d1.`store_id` <=> NULLIF(TRIM(s.`Store ID`), '')
       AND d1.`region_key` <=> x1.`region_key`
LEFT JOIN `dim_category` x2 ON x2.`category` <=> NULLIF(TRIM(s.`Category`), '')
LEFT JOIN `dim_product` d2 ON d2.`product_id` <=> NULLIF(TRIM(s.`Product ID`), '')
       AND d2.`category_key` <=> x2.`category_key`
LEFT JOIN `dim_weather` d3 ON d3.`weather_condition` <=> NULLIF(TRIM(s.`Weather Condition`), '')
LEFT JOIN `dim_season` d4 ON d4.`seasonality` <=> NULLIF(TRIM(s.`Seasonality`), '');

-- ---- PART C : QUICK CHECK ------------------------------------------------------
SELECT 'fact_inventory' AS table_name, COUNT(*) AS row_count FROM `fact_inventory` UNION ALL SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM `dim_date` UNION ALL SELECT 'dim_month' AS table_name, COUNT(*) AS row_count FROM `dim_month` UNION ALL SELECT 'dim_quarter' AS table_name, COUNT(*) AS row_count FROM `dim_quarter` UNION ALL SELECT 'dim_year' AS table_name, COUNT(*) AS row_count FROM `dim_year` UNION ALL SELECT 'dim_region' AS table_name, COUNT(*) AS row_count FROM `dim_region` UNION ALL SELECT 'dim_category' AS table_name, COUNT(*) AS row_count FROM `dim_category` UNION ALL SELECT 'dim_store' AS table_name, COUNT(*) AS row_count FROM `dim_store` UNION ALL SELECT 'dim_product' AS table_name, COUNT(*) AS row_count FROM `dim_product` UNION ALL SELECT 'dim_weather' AS table_name, COUNT(*) AS row_count FROM `dim_weather` UNION ALL SELECT 'dim_season' AS table_name, COUNT(*) AS row_count FROM `dim_season`;
