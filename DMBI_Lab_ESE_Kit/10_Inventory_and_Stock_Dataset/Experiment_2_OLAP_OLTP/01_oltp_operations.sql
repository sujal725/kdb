-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [Inventory_and_Stock_Dataset]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_inventory_stock` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_inventory_stock_stg`;

DROP TABLE IF EXISTS `oltp_inventory_stock_audit`;
DROP TABLE IF EXISTS `oltp_inventory_stock`;
CREATE TABLE `oltp_inventory_stock` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `date` DATE NULL,
  `store_id` VARCHAR(100) NULL,
  `product_id` VARCHAR(100) NULL,
  `category` VARCHAR(100) NULL,
  `region` VARCHAR(100) NULL,
  `inventory_level` INT NULL,
  `units_sold` INT NULL,
  `units_ordered` INT NULL,
  `demand_forecast` DECIMAL(18,4) NULL,
  `price` DECIMAL(18,2) NULL,
  `discount` INT NULL,
  `weather_condition` VARCHAR(100) NULL,
  `holiday_promotion` INT NULL,
  `competitor_pricing` DECIMAL(18,2) NULL,
  `seasonality` VARCHAR(100) NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_inventory_stock` (`date`, `store_id`, `product_id`, `category`, `region`, `inventory_level`, `units_sold`, `units_ordered`, `demand_forecast`, `price`, `discount`, `weather_condition`, `holiday_promotion`, `competitor_pricing`, `seasonality`)
SELECT
  DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')),
  NULLIF(TRIM(s.`Store ID`), ''),
  NULLIF(TRIM(s.`Product ID`), ''),
  NULLIF(TRIM(s.`Category`), ''),
  NULLIF(TRIM(s.`Region`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Inventory Level`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Ordered`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Demand Forecast`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`Weather Condition`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Holiday/Promotion`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Competitor Pricing`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  NULLIF(TRIM(s.`Seasonality`), '')
FROM `stg_inventory_stock` s;

CREATE INDEX `idx_inventory_stock_bk` ON `oltp_inventory_stock` (`store_id`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_inventory_stock`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_inventory_stock` WHERE oltp_id = 1;
SELECT * FROM `oltp_inventory_stock` WHERE `store_id` = (SELECT `store_id` FROM `oltp_inventory_stock` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_inventory_stock` (`date`, `store_id`, `product_id`, `category`, `region`, `inventory_level`, `units_sold`, `units_ordered`, `demand_forecast`, `price`, `discount`, `weather_condition`, `holiday_promotion`, `competitor_pricing`, `seasonality`)
SELECT `date`, `store_id`, `product_id`, `category`, `region`, `inventory_level`, `units_sold`, `units_ordered`, `demand_forecast`, `price`, `discount`, `weather_condition`, `holiday_promotion`, `competitor_pricing`, `seasonality` FROM `oltp_inventory_stock` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_inventory_stock` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_inventory_stock` SET `inventory_level` = `inventory_level` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `inventory_level`, last_modified FROM `oltp_inventory_stock` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_inventory_stock` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_inventory_stock`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_inventory_stock` (`date`, `store_id`, `product_id`, `category`, `region`, `inventory_level`, `units_sold`, `units_ordered`, `demand_forecast`, `price`, `discount`, `weather_condition`, `holiday_promotion`, `competitor_pricing`, `seasonality`) SELECT `date`, `store_id`, `product_id`, `category`, `region`, `inventory_level`, `units_sold`, `units_ordered`, `demand_forecast`, `price`, `discount`, `weather_condition`, `holiday_promotion`, `competitor_pricing`, `seasonality` FROM `oltp_inventory_stock` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_inventory_stock` SET `inventory_level` = `inventory_level` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `inventory_level` FROM `oltp_inventory_stock` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_inventory_stock`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_inventory_stock`;
START TRANSACTION;
DELETE FROM `oltp_inventory_stock` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_inventory_stock`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_inventory_stock`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_inventory_stock` SET `inventory_level` = `inventory_level` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_inventory_stock` SET `inventory_level` = `inventory_level` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `inventory_level` FROM `oltp_inventory_stock` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_inventory_stock` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_inventory_stock` SET `inventory_level` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_inventory_stock_audit`;
CREATE TABLE `oltp_inventory_stock_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_inventory_stock_audit`;
DELIMITER $$
CREATE TRIGGER `trg_inventory_stock_audit` AFTER UPDATE ON `oltp_inventory_stock`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`inventory_level` <=> NEW.`inventory_level`) THEN
    INSERT INTO `oltp_inventory_stock_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`inventory_level`, NEW.`inventory_level`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_inventory_stock` SET `inventory_level` = `inventory_level` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_inventory_stock_audit`;
UPDATE `oltp_inventory_stock` SET `inventory_level` = `inventory_level` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_inventory_stock` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `product_id`, SUM(`inventory_level`) FROM `oltp_inventory_stock` GROUP BY `product_id`;    -- full table scan + temp table
