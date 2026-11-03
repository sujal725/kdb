-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [Employee]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_employee` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_employee_stg`;

DROP TABLE IF EXISTS `oltp_employee_audit`;
DROP TABLE IF EXISTS `oltp_employee`;
CREATE TABLE `oltp_employee` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `education` VARCHAR(100) NULL,
  `joining_year` INT NULL,
  `city` VARCHAR(100) NULL,
  `payment_tier` INT NULL,
  `age` INT NULL,
  `gender` VARCHAR(100) NULL,
  `ever_benched` VARCHAR(100) NULL,
  `experience_in_current_domain` INT NULL,
  `leave_or_not` INT NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_employee` (`education`, `joining_year`, `city`, `payment_tier`, `age`, `gender`, `ever_benched`, `experience_in_current_domain`, `leave_or_not`)
SELECT
  NULLIF(TRIM(s.`Education`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`JoiningYear`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`City`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`PaymentTier`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`Gender`), ''),
  NULLIF(TRIM(s.`EverBenched`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`ExperienceInCurrentDomain`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`LeaveOrNot`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `stg_employee` s;

CREATE INDEX `idx_employee_bk` ON `oltp_employee` (`education`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_employee`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_employee` WHERE oltp_id = 1;
SELECT * FROM `oltp_employee` WHERE `education` = (SELECT `education` FROM `oltp_employee` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_employee` (`education`, `joining_year`, `city`, `payment_tier`, `age`, `gender`, `ever_benched`, `experience_in_current_domain`, `leave_or_not`)
SELECT `education`, `joining_year`, `city`, `payment_tier`, `age`, `gender`, `ever_benched`, `experience_in_current_domain`, `leave_or_not` FROM `oltp_employee` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_employee` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_employee` SET `age` = `age` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `age`, last_modified FROM `oltp_employee` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_employee` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_employee`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_employee` (`education`, `joining_year`, `city`, `payment_tier`, `age`, `gender`, `ever_benched`, `experience_in_current_domain`, `leave_or_not`) SELECT `education`, `joining_year`, `city`, `payment_tier`, `age`, `gender`, `ever_benched`, `experience_in_current_domain`, `leave_or_not` FROM `oltp_employee` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_employee` SET `age` = `age` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `age` FROM `oltp_employee` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_employee`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_employee`;
START TRANSACTION;
DELETE FROM `oltp_employee` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_employee`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_employee`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_employee` SET `age` = `age` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_employee` SET `age` = `age` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `age` FROM `oltp_employee` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_employee` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_employee` SET `age` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_employee_audit`;
CREATE TABLE `oltp_employee_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_employee_audit`;
DELIMITER $$
CREATE TRIGGER `trg_employee_audit` AFTER UPDATE ON `oltp_employee`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`age` <=> NEW.`age`) THEN
    INSERT INTO `oltp_employee_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`age`, NEW.`age`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_employee` SET `age` = `age` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_employee_audit`;
UPDATE `oltp_employee` SET `age` = `age` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_employee` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `city`, SUM(`age`) FROM `oltp_employee` GROUP BY `city`;    -- full table scan + temp table
