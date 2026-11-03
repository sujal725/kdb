-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [Customer_Purchase_History_Dataset]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_customer_purchase` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_customer_purchase_stg`;

DROP TABLE IF EXISTS `oltp_customer_purchase_audit`;
DROP TABLE IF EXISTS `oltp_customer_purchase`;
CREATE TABLE `oltp_customer_purchase` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` INT NULL,
  `age` INT NULL,
  `annual_income` DECIMAL(18,2) NULL,
  `purchase_amount` DECIMAL(18,2) NULL,
  `loyalty_score` DECIMAL(18,4) NULL,
  `region` VARCHAR(100) NULL,
  `purchase_frequency` INT NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_customer_purchase` (`user_id`, `age`, `annual_income`, `purchase_amount`, `loyalty_score`, `region`, `purchase_frequency`)
SELECT
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`user_id`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`annual_income`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`purchase_amount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`loyalty_score`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,4)),
  NULLIF(TRIM(s.`region`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`purchase_frequency`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `stg_customer_purchase` s;

CREATE INDEX `idx_customer_purchase_bk` ON `oltp_customer_purchase` (`user_id`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_customer_purchase`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_customer_purchase` WHERE oltp_id = 1;
SELECT * FROM `oltp_customer_purchase` WHERE `user_id` = (SELECT `user_id` FROM `oltp_customer_purchase` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_customer_purchase` (`user_id`, `age`, `annual_income`, `purchase_amount`, `loyalty_score`, `region`, `purchase_frequency`)
SELECT `user_id`, `age`, `annual_income`, `purchase_amount`, `loyalty_score`, `region`, `purchase_frequency` FROM `oltp_customer_purchase` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_customer_purchase` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_customer_purchase` SET `age` = `age` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `age`, last_modified FROM `oltp_customer_purchase` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_customer_purchase` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_customer_purchase`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_customer_purchase` (`user_id`, `age`, `annual_income`, `purchase_amount`, `loyalty_score`, `region`, `purchase_frequency`) SELECT `user_id`, `age`, `annual_income`, `purchase_amount`, `loyalty_score`, `region`, `purchase_frequency` FROM `oltp_customer_purchase` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_customer_purchase` SET `age` = `age` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `age` FROM `oltp_customer_purchase` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_customer_purchase`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_customer_purchase`;
START TRANSACTION;
DELETE FROM `oltp_customer_purchase` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_customer_purchase`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_customer_purchase`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_customer_purchase` SET `age` = `age` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_customer_purchase` SET `age` = `age` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `age` FROM `oltp_customer_purchase` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_customer_purchase` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_customer_purchase` SET `age` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_customer_purchase_audit`;
CREATE TABLE `oltp_customer_purchase_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_customer_purchase_audit`;
DELIMITER $$
CREATE TRIGGER `trg_customer_purchase_audit` AFTER UPDATE ON `oltp_customer_purchase`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`age` <=> NEW.`age`) THEN
    INSERT INTO `oltp_customer_purchase_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`age`, NEW.`age`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_customer_purchase` SET `age` = `age` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_customer_purchase_audit`;
UPDATE `oltp_customer_purchase` SET `age` = `age` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_customer_purchase` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `region`, SUM(`age`) FROM `oltp_customer_purchase` GROUP BY `region`;    -- full table scan + temp table
