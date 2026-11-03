-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [Super_Market_Analysis]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_super_market` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_super_market_stg`;

DROP TABLE IF EXISTS `oltp_super_market_audit`;
DROP TABLE IF EXISTS `oltp_super_market`;
CREATE TABLE `oltp_super_market` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `invoice_id` VARCHAR(100) NULL,
  `branch` VARCHAR(100) NULL,
  `city` VARCHAR(100) NULL,
  `customer_type` VARCHAR(100) NULL,
  `gender` VARCHAR(100) NULL,
  `product_line` VARCHAR(100) NULL,
  `unit_price` DECIMAL(18,4) NULL,
  `quantity` INT NULL,
  `tax_5` DECIMAL(18,4) NULL,
  `total` DECIMAL(18,4) NULL,
  `date` DATE NULL,
  `time` TIME NULL,
  `payment` VARCHAR(100) NULL,
  `cogs` DECIMAL(18,4) NULL,
  `gross_margin_percentage` DECIMAL(18,4) NULL,
  `gross_income` DECIMAL(18,4) NULL,
  `rating` DECIMAL(18,4) NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_super_market` (`invoice_id`, `branch`, `city`, `customer_type`, `gender`, `product_line`, `unit_price`, `quantity`, `tax_5`, `total`, `date`, `time`, `payment`, `cogs`, `gross_margin_percentage`, `gross_income`, `rating`)
SELECT
  NULLIF(TRIM(s.`Invoice ID`), ''),
  NULLIF(TRIM(s.`Branch`), ''),
  NULLIF(TRIM(s.`City`), ''),
  NULLIF(TRIM(s.`Customer type`), ''),
  NULLIF(TRIM(s.`Gender`), ''),
  NULLIF(TRIM(s.`Product line`), ''),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Unit price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Quantity`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Tax 5%`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  DATE(STR_TO_DATE(TRIM(s.`Date`), '%m/%d/%Y')),
  TIME(STR_TO_DATE(TRIM(s.`Time`), '%H:%i')),
  NULLIF(TRIM(s.`Payment`), ''),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`cogs`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`gross margin percentage`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`gross income`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Rating`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4))
FROM `stg_super_market` s;

CREATE INDEX `idx_super_market_bk` ON `oltp_super_market` (`invoice_id`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_super_market`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_super_market` WHERE oltp_id = 1;
SELECT * FROM `oltp_super_market` WHERE `invoice_id` = (SELECT `invoice_id` FROM `oltp_super_market` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_super_market` (`invoice_id`, `branch`, `city`, `customer_type`, `gender`, `product_line`, `unit_price`, `quantity`, `tax_5`, `total`, `date`, `time`, `payment`, `cogs`, `gross_margin_percentage`, `gross_income`, `rating`)
SELECT `invoice_id`, `branch`, `city`, `customer_type`, `gender`, `product_line`, `unit_price`, `quantity`, `tax_5`, `total`, `date`, `time`, `payment`, `cogs`, `gross_margin_percentage`, `gross_income`, `rating` FROM `oltp_super_market` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_super_market` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_super_market` SET `unit_price` = `unit_price` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `unit_price`, last_modified FROM `oltp_super_market` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_super_market` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_super_market`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_super_market` (`invoice_id`, `branch`, `city`, `customer_type`, `gender`, `product_line`, `unit_price`, `quantity`, `tax_5`, `total`, `date`, `time`, `payment`, `cogs`, `gross_margin_percentage`, `gross_income`, `rating`) SELECT `invoice_id`, `branch`, `city`, `customer_type`, `gender`, `product_line`, `unit_price`, `quantity`, `tax_5`, `total`, `date`, `time`, `payment`, `cogs`, `gross_margin_percentage`, `gross_income`, `rating` FROM `oltp_super_market` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_super_market` SET `unit_price` = `unit_price` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `unit_price` FROM `oltp_super_market` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_super_market`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_super_market`;
START TRANSACTION;
DELETE FROM `oltp_super_market` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_super_market`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_super_market`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_super_market` SET `unit_price` = `unit_price` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_super_market` SET `unit_price` = `unit_price` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `unit_price` FROM `oltp_super_market` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_super_market` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_super_market` SET `unit_price` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_super_market_audit`;
CREATE TABLE `oltp_super_market_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_super_market_audit`;
DELIMITER $$
CREATE TRIGGER `trg_super_market_audit` AFTER UPDATE ON `oltp_super_market`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`unit_price` <=> NEW.`unit_price`) THEN
    INSERT INTO `oltp_super_market_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`unit_price`, NEW.`unit_price`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_super_market` SET `unit_price` = `unit_price` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_super_market_audit`;
UPDATE `oltp_super_market` SET `unit_price` = `unit_price` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_super_market` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `branch`, SUM(`unit_price`) FROM `oltp_super_market` GROUP BY `branch`;    -- full table scan + temp table
