-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [Ecommerce_sales]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_ecommerce_sales` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_ecommerce_sales_stg`;

DROP TABLE IF EXISTS `oltp_ecommerce_sales_audit`;
DROP TABLE IF EXISTS `oltp_ecommerce_sales`;
CREATE TABLE `oltp_ecommerce_sales` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `date` DATE NULL,
  `product_category` VARCHAR(100) NULL,
  `price` DECIMAL(18,2) NULL,
  `discount` DECIMAL(18,2) NULL,
  `customer_segment` VARCHAR(100) NULL,
  `marketing_spend` DECIMAL(18,2) NULL,
  `units_sold` INT NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_ecommerce_sales` (`date`, `product_category`, `price`, `discount`, `customer_segment`, `marketing_spend`, `units_sold`)
SELECT
  DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')),
  NULLIF(TRIM(s.`Product_Category`), ''),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Discount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  NULLIF(TRIM(s.`Customer_Segment`), ''),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Marketing_Spend`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units_Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `stg_ecommerce_sales` s;

CREATE INDEX `idx_ecommerce_sales_bk` ON `oltp_ecommerce_sales` (`product_category`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_ecommerce_sales`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_ecommerce_sales` WHERE oltp_id = 1;
SELECT * FROM `oltp_ecommerce_sales` WHERE `product_category` = (SELECT `product_category` FROM `oltp_ecommerce_sales` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_ecommerce_sales` (`date`, `product_category`, `price`, `discount`, `customer_segment`, `marketing_spend`, `units_sold`)
SELECT `date`, `product_category`, `price`, `discount`, `customer_segment`, `marketing_spend`, `units_sold` FROM `oltp_ecommerce_sales` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_ecommerce_sales` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_ecommerce_sales` SET `price` = `price` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `price`, last_modified FROM `oltp_ecommerce_sales` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_ecommerce_sales` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_ecommerce_sales`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_ecommerce_sales` (`date`, `product_category`, `price`, `discount`, `customer_segment`, `marketing_spend`, `units_sold`) SELECT `date`, `product_category`, `price`, `discount`, `customer_segment`, `marketing_spend`, `units_sold` FROM `oltp_ecommerce_sales` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_ecommerce_sales` SET `price` = `price` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `price` FROM `oltp_ecommerce_sales` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_ecommerce_sales`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_ecommerce_sales`;
START TRANSACTION;
DELETE FROM `oltp_ecommerce_sales` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_ecommerce_sales`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_ecommerce_sales`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_ecommerce_sales` SET `price` = `price` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_ecommerce_sales` SET `price` = `price` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `price` FROM `oltp_ecommerce_sales` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_ecommerce_sales` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_ecommerce_sales` SET `price` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_ecommerce_sales_audit`;
CREATE TABLE `oltp_ecommerce_sales_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_ecommerce_sales_audit`;
DELIMITER $$
CREATE TRIGGER `trg_ecommerce_sales_audit` AFTER UPDATE ON `oltp_ecommerce_sales`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`price` <=> NEW.`price`) THEN
    INSERT INTO `oltp_ecommerce_sales_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`price`, NEW.`price`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_ecommerce_sales` SET `price` = `price` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_ecommerce_sales_audit`;
UPDATE `oltp_ecommerce_sales` SET `price` = `price` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_ecommerce_sales` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `customer_segment`, SUM(`price`) FROM `oltp_ecommerce_sales` GROUP BY `customer_segment`;    -- full table scan + temp table
