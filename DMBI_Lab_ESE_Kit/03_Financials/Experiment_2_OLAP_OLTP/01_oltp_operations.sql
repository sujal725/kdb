-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [Financials]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_financials` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_financials_stg`;

DROP TABLE IF EXISTS `oltp_financials_audit`;
DROP TABLE IF EXISTS `oltp_financials`;
CREATE TABLE `oltp_financials` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `segment` VARCHAR(100) NULL,
  `country` VARCHAR(100) NULL,
  `product` VARCHAR(100) NULL,
  `discount_band` VARCHAR(100) NULL,
  `units_sold` DECIMAL(18,2) NULL,
  `manufacturing_price` DECIMAL(18,2) NULL,
  `sale_price` DECIMAL(18,2) NULL,
  `gross_sales` DECIMAL(18,2) NULL,
  `discounts` DECIMAL(18,2) NULL,
  `sales` DECIMAL(18,2) NULL,
  `cogs` DECIMAL(18,2) NULL,
  `profit` DECIMAL(18,2) NULL,
  `date` DATE NULL,
  `month_number` VARCHAR(100) NULL,
  `month_name` VARCHAR(100) NULL,
  `year` VARCHAR(100) NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_financials` (`segment`, `country`, `product`, `discount_band`, `units_sold`, `manufacturing_price`, `sale_price`, `gross_sales`, `discounts`, `sales`, `cogs`, `profit`, `date`, `month_number`, `month_name`, `year`)
SELECT
  NULLIF(TRIM(s.`Segment`), ''),
  NULLIF(TRIM(s.`Country`), ''),
  NULLIF(TRIM(s.`Product`), ''),
  NULLIF(TRIM(s.`Discount Band`), ''),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Manufacturing Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Sale Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Gross Sales`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discounts`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Sales`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`COGS`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Profit`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  STR_TO_DATE(CONCAT(REPLACE(s.`Year`, ',', ''), '-', s.`Month Number`, '-01'), '%Y-%m-%d'),
  NULLIF(TRIM(s.`Month Number`), ''),
  NULLIF(TRIM(s.`Month Name`), ''),
  NULLIF(TRIM(s.`Year`), '')
FROM `stg_financials` s;

CREATE INDEX `idx_financials_bk` ON `oltp_financials` (`segment`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_financials`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_financials` WHERE oltp_id = 1;
SELECT * FROM `oltp_financials` WHERE `segment` = (SELECT `segment` FROM `oltp_financials` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_financials` (`segment`, `country`, `product`, `discount_band`, `units_sold`, `manufacturing_price`, `sale_price`, `gross_sales`, `discounts`, `sales`, `cogs`, `profit`, `date`, `month_number`, `month_name`, `year`)
SELECT `segment`, `country`, `product`, `discount_band`, `units_sold`, `manufacturing_price`, `sale_price`, `gross_sales`, `discounts`, `sales`, `cogs`, `profit`, `date`, `month_number`, `month_name`, `year` FROM `oltp_financials` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_financials` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_financials` SET `units_sold` = `units_sold` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `units_sold`, last_modified FROM `oltp_financials` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_financials` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_financials`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_financials` (`segment`, `country`, `product`, `discount_band`, `units_sold`, `manufacturing_price`, `sale_price`, `gross_sales`, `discounts`, `sales`, `cogs`, `profit`, `date`, `month_number`, `month_name`, `year`) SELECT `segment`, `country`, `product`, `discount_band`, `units_sold`, `manufacturing_price`, `sale_price`, `gross_sales`, `discounts`, `sales`, `cogs`, `profit`, `date`, `month_number`, `month_name`, `year` FROM `oltp_financials` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_financials` SET `units_sold` = `units_sold` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `units_sold` FROM `oltp_financials` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_financials`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_financials`;
START TRANSACTION;
DELETE FROM `oltp_financials` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_financials`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_financials`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_financials` SET `units_sold` = `units_sold` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_financials` SET `units_sold` = `units_sold` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `units_sold` FROM `oltp_financials` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_financials` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_financials` SET `units_sold` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_financials_audit`;
CREATE TABLE `oltp_financials_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_financials_audit`;
DELIMITER $$
CREATE TRIGGER `trg_financials_audit` AFTER UPDATE ON `oltp_financials`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`units_sold` <=> NEW.`units_sold`) THEN
    INSERT INTO `oltp_financials_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`units_sold`, NEW.`units_sold`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_financials` SET `units_sold` = `units_sold` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_financials_audit`;
UPDATE `oltp_financials` SET `units_sold` = `units_sold` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_financials` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `country`, SUM(`units_sold`) FROM `oltp_financials` GROUP BY `country`;    -- full table scan + temp table
