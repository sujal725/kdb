-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [Online_Orders_Dataset]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_online_orders` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_online_orders_stg`;

DROP TABLE IF EXISTS `oltp_online_orders_audit`;
DROP TABLE IF EXISTS `oltp_online_orders`;
CREATE TABLE `oltp_online_orders` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `transaction_id` BIGINT NULL,
  `date` DATE NULL,
  `product_category` VARCHAR(100) NULL,
  `product_name` VARCHAR(100) NULL,
  `units_sold` INT NULL,
  `unit_price` DECIMAL(18,2) NULL,
  `total_revenue` DECIMAL(18,2) NULL,
  `region` VARCHAR(100) NULL,
  `payment_method` VARCHAR(100) NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_online_orders` (`transaction_id`, `date`, `product_category`, `product_name`, `units_sold`, `unit_price`, `total_revenue`, `region`, `payment_method`)
SELECT
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Transaction ID`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  DATE(STR_TO_DATE(TRIM(s.`Date`), '%Y-%m-%d')),
  NULLIF(TRIM(s.`Product Category`), ''),
  NULLIF(TRIM(s.`Product Name`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Units Sold`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Unit Price`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Total Revenue`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  NULLIF(TRIM(s.`Region`), ''),
  NULLIF(TRIM(s.`Payment Method`), '')
FROM `stg_online_orders` s;

CREATE INDEX `idx_online_orders_bk` ON `oltp_online_orders` (`transaction_id`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_online_orders`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_online_orders` WHERE oltp_id = 1;
SELECT * FROM `oltp_online_orders` WHERE `transaction_id` = (SELECT `transaction_id` FROM `oltp_online_orders` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_online_orders` (`transaction_id`, `date`, `product_category`, `product_name`, `units_sold`, `unit_price`, `total_revenue`, `region`, `payment_method`)
SELECT `transaction_id`, `date`, `product_category`, `product_name`, `units_sold`, `unit_price`, `total_revenue`, `region`, `payment_method` FROM `oltp_online_orders` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_online_orders` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_online_orders` SET `units_sold` = `units_sold` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `units_sold`, last_modified FROM `oltp_online_orders` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_online_orders` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_online_orders`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_online_orders` (`transaction_id`, `date`, `product_category`, `product_name`, `units_sold`, `unit_price`, `total_revenue`, `region`, `payment_method`) SELECT `transaction_id`, `date`, `product_category`, `product_name`, `units_sold`, `unit_price`, `total_revenue`, `region`, `payment_method` FROM `oltp_online_orders` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_online_orders` SET `units_sold` = `units_sold` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `units_sold` FROM `oltp_online_orders` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_online_orders`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_online_orders`;
START TRANSACTION;
DELETE FROM `oltp_online_orders` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_online_orders`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_online_orders`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_online_orders` SET `units_sold` = `units_sold` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_online_orders` SET `units_sold` = `units_sold` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `units_sold` FROM `oltp_online_orders` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_online_orders` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_online_orders` SET `units_sold` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_online_orders_audit`;
CREATE TABLE `oltp_online_orders_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_online_orders_audit`;
DELIMITER $$
CREATE TRIGGER `trg_online_orders_audit` AFTER UPDATE ON `oltp_online_orders`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`units_sold` <=> NEW.`units_sold`) THEN
    INSERT INTO `oltp_online_orders_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`units_sold`, NEW.`units_sold`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_online_orders` SET `units_sold` = `units_sold` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_online_orders_audit`;
UPDATE `oltp_online_orders` SET `units_sold` = `units_sold` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_online_orders` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `product_category`, SUM(`units_sold`) FROM `oltp_online_orders` GROUP BY `product_category`;    -- full table scan + temp table
