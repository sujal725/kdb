-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [Banking_Customer_Dataset]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_banking_customer` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_banking_customer_stg`;

DROP TABLE IF EXISTS `oltp_banking_customer_audit`;
DROP TABLE IF EXISTS `oltp_banking_customer`;
CREATE TABLE `oltp_banking_customer` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `src_row_number` INT NULL,
  `customer_id` BIGINT NULL,
  `surname` VARCHAR(100) NULL,
  `credit_score` INT NULL,
  `geography` VARCHAR(100) NULL,
  `gender` VARCHAR(100) NULL,
  `age` INT NULL,
  `tenure` INT NULL,
  `balance` DECIMAL(18,2) NULL,
  `num_of_products` INT NULL,
  `has_cr_card` INT NULL,
  `is_active_member` INT NULL,
  `estimated_salary` DECIMAL(18,2) NULL,
  `exited` INT NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_banking_customer` (`src_row_number`, `customer_id`, `surname`, `credit_score`, `geography`, `gender`, `age`, `tenure`, `balance`, `num_of_products`, `has_cr_card`, `is_active_member`, `estimated_salary`, `exited`)
SELECT
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`RowNumber`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CustomerId`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`Surname`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`CreditScore`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`Geography`), ''),
  NULLIF(TRIM(s.`Gender`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Tenure`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Balance`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`NumOfProducts`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`HasCrCard`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`IsActiveMember`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`EstimatedSalary`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(18,2)),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Exited`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `stg_banking_customer` s;

CREATE INDEX `idx_banking_customer_bk` ON `oltp_banking_customer` (`src_row_number`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_banking_customer`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_banking_customer` WHERE oltp_id = 1;
SELECT * FROM `oltp_banking_customer` WHERE `src_row_number` = (SELECT `src_row_number` FROM `oltp_banking_customer` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_banking_customer` (`src_row_number`, `customer_id`, `surname`, `credit_score`, `geography`, `gender`, `age`, `tenure`, `balance`, `num_of_products`, `has_cr_card`, `is_active_member`, `estimated_salary`, `exited`)
SELECT `src_row_number`, `customer_id`, `surname`, `credit_score`, `geography`, `gender`, `age`, `tenure`, `balance`, `num_of_products`, `has_cr_card`, `is_active_member`, `estimated_salary`, `exited` FROM `oltp_banking_customer` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_banking_customer` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_banking_customer` SET `credit_score` = `credit_score` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `credit_score`, last_modified FROM `oltp_banking_customer` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_banking_customer` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_banking_customer`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_banking_customer` (`src_row_number`, `customer_id`, `surname`, `credit_score`, `geography`, `gender`, `age`, `tenure`, `balance`, `num_of_products`, `has_cr_card`, `is_active_member`, `estimated_salary`, `exited`) SELECT `src_row_number`, `customer_id`, `surname`, `credit_score`, `geography`, `gender`, `age`, `tenure`, `balance`, `num_of_products`, `has_cr_card`, `is_active_member`, `estimated_salary`, `exited` FROM `oltp_banking_customer` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_banking_customer` SET `credit_score` = `credit_score` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `credit_score` FROM `oltp_banking_customer` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_banking_customer`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_banking_customer`;
START TRANSACTION;
DELETE FROM `oltp_banking_customer` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_banking_customer`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_banking_customer`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_banking_customer` SET `credit_score` = `credit_score` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_banking_customer` SET `credit_score` = `credit_score` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `credit_score` FROM `oltp_banking_customer` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_banking_customer` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_banking_customer` SET `credit_score` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_banking_customer_audit`;
CREATE TABLE `oltp_banking_customer_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_banking_customer_audit`;
DELIMITER $$
CREATE TRIGGER `trg_banking_customer_audit` AFTER UPDATE ON `oltp_banking_customer`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`credit_score` <=> NEW.`credit_score`) THEN
    INSERT INTO `oltp_banking_customer_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`credit_score`, NEW.`credit_score`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_banking_customer` SET `credit_score` = `credit_score` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_banking_customer_audit`;
UPDATE `oltp_banking_customer` SET `credit_score` = `credit_score` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_banking_customer` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `surname`, SUM(`credit_score`) FROM `oltp_banking_customer` GROUP BY `surname`;    -- full table scan + temp table
