-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [Retail_Transactions_Dataset]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_retail_transactions` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_retail_transactions_stg`;

DROP TABLE IF EXISTS `oltp_retail_transactions_audit`;
DROP TABLE IF EXISTS `oltp_retail_transactions`;
CREATE TABLE `oltp_retail_transactions` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `transaction_id` BIGINT NULL,
  `date` DATE NULL,
  `customer_name` VARCHAR(100) NULL,
  `product` VARCHAR(500) NULL,
  `total_items` INT NULL,
  `total_cost` DECIMAL(18,2) NULL,
  `payment_method` VARCHAR(100) NULL,
  `city` VARCHAR(100) NULL,
  `store_type` VARCHAR(100) NULL,
  `discount_applied` TINYINT NULL,
  `customer_category` VARCHAR(100) NULL,
  `season` VARCHAR(100) NULL,
  `promotion` VARCHAR(100) NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_retail_transactions` (`transaction_id`, `date`, `customer_name`, `product`, `total_items`, `total_cost`, `payment_method`, `city`, `store_type`, `discount_applied`, `customer_category`, `season`, `promotion`)
SELECT
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Transaction_ID`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d %H:%i:%s')),
  NULLIF(TRIM(s.`Customer_Name`), ''),
  NULLIF(TRIM(s.`Product`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total_Items`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total_Cost`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  NULLIF(TRIM(s.`Payment_Method`), ''),
  NULLIF(TRIM(s.`City`), ''),
  NULLIF(TRIM(s.`Store_Type`), ''),
  CASE WHEN UPPER(TRIM(s.`Discount_Applied`)) IN ('YES','Y','TRUE','1') THEN 1 ELSE 0 END,
  NULLIF(TRIM(s.`Customer_Category`), ''),
  NULLIF(TRIM(s.`Season`), ''),
  NULLIF(TRIM(s.`Promotion`), '')
FROM `stg_retail_transactions` s;

CREATE INDEX `idx_retail_transactions_bk` ON `oltp_retail_transactions` (`transaction_id`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_retail_transactions`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_retail_transactions` WHERE oltp_id = 1;
SELECT * FROM `oltp_retail_transactions` WHERE `transaction_id` = (SELECT `transaction_id` FROM `oltp_retail_transactions` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_retail_transactions` (`transaction_id`, `date`, `customer_name`, `product`, `total_items`, `total_cost`, `payment_method`, `city`, `store_type`, `discount_applied`, `customer_category`, `season`, `promotion`)
SELECT `transaction_id`, `date`, `customer_name`, `product`, `total_items`, `total_cost`, `payment_method`, `city`, `store_type`, `discount_applied`, `customer_category`, `season`, `promotion` FROM `oltp_retail_transactions` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_retail_transactions` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_retail_transactions` SET `total_items` = `total_items` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `total_items`, last_modified FROM `oltp_retail_transactions` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_retail_transactions` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_retail_transactions`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_retail_transactions` (`transaction_id`, `date`, `customer_name`, `product`, `total_items`, `total_cost`, `payment_method`, `city`, `store_type`, `discount_applied`, `customer_category`, `season`, `promotion`) SELECT `transaction_id`, `date`, `customer_name`, `product`, `total_items`, `total_cost`, `payment_method`, `city`, `store_type`, `discount_applied`, `customer_category`, `season`, `promotion` FROM `oltp_retail_transactions` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_retail_transactions` SET `total_items` = `total_items` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `total_items` FROM `oltp_retail_transactions` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_retail_transactions`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_retail_transactions`;
START TRANSACTION;
DELETE FROM `oltp_retail_transactions` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_retail_transactions`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_retail_transactions`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_retail_transactions` SET `total_items` = `total_items` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_retail_transactions` SET `total_items` = `total_items` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `total_items` FROM `oltp_retail_transactions` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_retail_transactions` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_retail_transactions` SET `total_items` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_retail_transactions_audit`;
CREATE TABLE `oltp_retail_transactions_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_retail_transactions_audit`;
DELIMITER $$
CREATE TRIGGER `trg_retail_transactions_audit` AFTER UPDATE ON `oltp_retail_transactions`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`total_items` <=> NEW.`total_items`) THEN
    INSERT INTO `oltp_retail_transactions_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`total_items`, NEW.`total_items`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_retail_transactions` SET `total_items` = `total_items` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_retail_transactions_audit`;
UPDATE `oltp_retail_transactions` SET `total_items` = `total_items` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_retail_transactions` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `customer_name`, SUM(`total_items`) FROM `oltp_retail_transactions` GROUP BY `customer_name`;    -- full table scan + temp table
