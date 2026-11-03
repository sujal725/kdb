-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [Retail_sales]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_retail_sales` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_retail_sales_stg`;

DROP TABLE IF EXISTS `oltp_retail_sales_audit`;
DROP TABLE IF EXISTS `oltp_retail_sales`;
CREATE TABLE `oltp_retail_sales` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `transaction_id` BIGINT NULL,
  `date` DATE NULL,
  `customer_id` VARCHAR(100) NULL,
  `gender` VARCHAR(100) NULL,
  `age` INT NULL,
  `product_category` VARCHAR(100) NULL,
  `quantity` INT NULL,
  `price_per_unit` DECIMAL(18,2) NULL,
  `total_amount` DECIMAL(18,2) NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_retail_sales` (`transaction_id`, `date`, `customer_id`, `gender`, `age`, `product_category`, `quantity`, `price_per_unit`, `total_amount`)
SELECT
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Transaction ID`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')),
  NULLIF(TRIM(s.`Customer ID`), ''),
  NULLIF(TRIM(s.`Gender`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`Product Category`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Quantity`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price per Unit`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total Amount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2))
FROM `stg_retail_sales` s;

CREATE INDEX `idx_retail_sales_bk` ON `oltp_retail_sales` (`transaction_id`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_retail_sales`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_retail_sales` WHERE oltp_id = 1;
SELECT * FROM `oltp_retail_sales` WHERE `transaction_id` = (SELECT `transaction_id` FROM `oltp_retail_sales` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_retail_sales` (`transaction_id`, `date`, `customer_id`, `gender`, `age`, `product_category`, `quantity`, `price_per_unit`, `total_amount`)
SELECT `transaction_id`, `date`, `customer_id`, `gender`, `age`, `product_category`, `quantity`, `price_per_unit`, `total_amount` FROM `oltp_retail_sales` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_retail_sales` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_retail_sales` SET `quantity` = `quantity` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `quantity`, last_modified FROM `oltp_retail_sales` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_retail_sales` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_retail_sales`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_retail_sales` (`transaction_id`, `date`, `customer_id`, `gender`, `age`, `product_category`, `quantity`, `price_per_unit`, `total_amount`) SELECT `transaction_id`, `date`, `customer_id`, `gender`, `age`, `product_category`, `quantity`, `price_per_unit`, `total_amount` FROM `oltp_retail_sales` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_retail_sales` SET `quantity` = `quantity` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `quantity` FROM `oltp_retail_sales` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_retail_sales`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_retail_sales`;
START TRANSACTION;
DELETE FROM `oltp_retail_sales` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_retail_sales`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_retail_sales`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_retail_sales` SET `quantity` = `quantity` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_retail_sales` SET `quantity` = `quantity` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `quantity` FROM `oltp_retail_sales` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_retail_sales` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_retail_sales` SET `quantity` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_retail_sales_audit`;
CREATE TABLE `oltp_retail_sales_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_retail_sales_audit`;
DELIMITER $$
CREATE TRIGGER `trg_retail_sales_audit` AFTER UPDATE ON `oltp_retail_sales`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`quantity` <=> NEW.`quantity`) THEN
    INSERT INTO `oltp_retail_sales_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`quantity`, NEW.`quantity`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_retail_sales` SET `quantity` = `quantity` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_retail_sales_audit`;
UPDATE `oltp_retail_sales` SET `quantity` = `quantity` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_retail_sales` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `customer_id`, SUM(`quantity`) FROM `oltp_retail_sales` GROUP BY `customer_id`;    -- full table scan + temp table
