-- ========================================================================
-- EXPERIMENT 2 - PART A : OLTP OPERATIONS  [HR_Analytics_Dataset]
-- OLTP = many small, fast read/write transactions on a normalised, indexed table.
-- We build a typed OLTP table `oltp_hr_analytics` from the staging data and run INSERT / UPDATE / DELETE / transactions on it.
-- Run Experiment 1 step 1 (staging) first.
-- ========================================================================

USE `dmbi_hr_analytics_stg`;

DROP TABLE IF EXISTS `oltp_hr_analytics_audit`;
DROP TABLE IF EXISTS `oltp_hr_analytics`;
CREATE TABLE `oltp_hr_analytics` (
  `oltp_id` BIGINT NOT NULL AUTO_INCREMENT,
  `emp_id` VARCHAR(100) NULL,
  `age` INT NULL,
  `age_group` VARCHAR(100) NULL,
  `attrition_flag` TINYINT NULL,
  `business_travel` VARCHAR(100) NULL,
  `daily_rate` INT NULL,
  `department` VARCHAR(100) NULL,
  `distance_from_home` INT NULL,
  `education` INT NULL,
  `education_field` VARCHAR(100) NULL,
  `employee_count` INT NULL,
  `employee_number` INT NULL,
  `environment_satisfaction` INT NULL,
  `gender` VARCHAR(100) NULL,
  `hourly_rate` INT NULL,
  `job_involvement` INT NULL,
  `job_level` INT NULL,
  `job_role` VARCHAR(100) NULL,
  `job_satisfaction` INT NULL,
  `marital_status` VARCHAR(100) NULL,
  `monthly_income` INT NULL,
  `salary_slab` VARCHAR(100) NULL,
  `monthly_rate` INT NULL,
  `num_companies_worked` INT NULL,
  `over18` VARCHAR(100) NULL,
  `over_time` VARCHAR(100) NULL,
  `percent_salary_hike` INT NULL,
  `performance_rating` INT NULL,
  `relationship_satisfaction` INT NULL,
  `standard_hours` INT NULL,
  `stock_option_level` INT NULL,
  `total_working_years` INT NULL,
  `training_times_last_year` INT NULL,
  `work_life_balance` INT NULL,
  `years_at_company` INT NULL,
  `years_in_current_role` INT NULL,
  `years_since_last_promotion` INT NULL,
  `years_with_curr_manager` INT NULL,
  `last_modified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`oltp_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `oltp_hr_analytics` (`emp_id`, `age`, `age_group`, `attrition_flag`, `business_travel`, `daily_rate`, `department`, `distance_from_home`, `education`, `education_field`, `employee_count`, `employee_number`, `environment_satisfaction`, `gender`, `hourly_rate`, `job_involvement`, `job_level`, `job_role`, `job_satisfaction`, `marital_status`, `monthly_income`, `salary_slab`, `monthly_rate`, `num_companies_worked`, `over18`, `over_time`, `percent_salary_hike`, `performance_rating`, `relationship_satisfaction`, `standard_hours`, `stock_option_level`, `total_working_years`, `training_times_last_year`, `work_life_balance`, `years_at_company`, `years_in_current_role`, `years_since_last_promotion`, `years_with_curr_manager`)
SELECT
  NULLIF(TRIM(s.`EmpID`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Age`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`AgeGroup`), ''),
  CASE WHEN UPPER(TRIM(s.`Attrition`)) IN ('YES','Y','TRUE','1') THEN 1 ELSE 0 END,
  NULLIF(TRIM(s.`BusinessTravel`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`DailyRate`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`Department`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`DistanceFromHome`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`Education`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`EducationField`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`EmployeeCount`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`EmployeeNumber`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`EnvironmentSatisfaction`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`Gender`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`HourlyRate`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`JobInvolvement`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`JobLevel`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`JobRole`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`JobSatisfaction`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`MaritalStatus`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`MonthlyIncome`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`SalarySlab`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`MonthlyRate`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`NumCompaniesWorked`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  NULLIF(TRIM(s.`Over18`), ''),
  NULLIF(TRIM(s.`OverTime`), ''),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`PercentSalaryHike`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`PerformanceRating`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`RelationshipSatisfaction`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`StandardHours`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`StockOptionLevel`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`TotalWorkingYears`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`TrainingTimesLastYear`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`WorkLifeBalance`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`YearsAtCompany`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`YearsInCurrentRole`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`YearsSinceLastPromotion`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED),
  CAST(CAST(NULLIF(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(s.`YearsWithCurrManager`),'$',''),',',''),'(','-'),')',''),'') AS DECIMAL(20,2)) AS SIGNED)
FROM `stg_hr_analytics` s;

CREATE INDEX `idx_hr_analytics_bk` ON `oltp_hr_analytics` (`emp_id`);
SELECT COUNT(*) AS oltp_rows FROM `oltp_hr_analytics`;

-- ---- 1. READ : point lookups (primary key and business key) -----------------
SELECT * FROM `oltp_hr_analytics` WHERE oltp_id = 1;
SELECT * FROM `oltp_hr_analytics` WHERE `emp_id` = (SELECT `emp_id` FROM `oltp_hr_analytics` WHERE oltp_id = 1) LIMIT 10;

-- ---- 2. CREATE : INSERT a new record (clone of row 1, then we edit it) ---------
INSERT INTO `oltp_hr_analytics` (`emp_id`, `age`, `age_group`, `attrition_flag`, `business_travel`, `daily_rate`, `department`, `distance_from_home`, `education`, `education_field`, `employee_count`, `employee_number`, `environment_satisfaction`, `gender`, `hourly_rate`, `job_involvement`, `job_level`, `job_role`, `job_satisfaction`, `marital_status`, `monthly_income`, `salary_slab`, `monthly_rate`, `num_companies_worked`, `over18`, `over_time`, `percent_salary_hike`, `performance_rating`, `relationship_satisfaction`, `standard_hours`, `stock_option_level`, `total_working_years`, `training_times_last_year`, `work_life_balance`, `years_at_company`, `years_in_current_role`, `years_since_last_promotion`, `years_with_curr_manager`)
SELECT `emp_id`, `age`, `age_group`, `attrition_flag`, `business_travel`, `daily_rate`, `department`, `distance_from_home`, `education`, `education_field`, `employee_count`, `employee_number`, `environment_satisfaction`, `gender`, `hourly_rate`, `job_involvement`, `job_level`, `job_role`, `job_satisfaction`, `marital_status`, `monthly_income`, `salary_slab`, `monthly_rate`, `num_companies_worked`, `over18`, `over_time`, `percent_salary_hike`, `performance_rating`, `relationship_satisfaction`, `standard_hours`, `stock_option_level`, `total_working_years`, `training_times_last_year`, `work_life_balance`, `years_at_company`, `years_in_current_role`, `years_since_last_promotion`, `years_with_curr_manager` FROM `oltp_hr_analytics` WHERE oltp_id = 1;
SET @new_id = LAST_INSERT_ID();
SELECT * FROM `oltp_hr_analytics` WHERE oltp_id = @new_id;

-- ---- 3. UPDATE : change one column of that record ----------------------------
UPDATE `oltp_hr_analytics` SET `age` = `age` * 1.10 WHERE oltp_id = @new_id;
SELECT oltp_id, `age`, last_modified FROM `oltp_hr_analytics` WHERE oltp_id = @new_id;

-- ---- 4. DELETE : remove the record ---------------------------------------------
DELETE FROM `oltp_hr_analytics` WHERE oltp_id = @new_id;
SELECT COUNT(*) AS rows_after_delete FROM `oltp_hr_analytics`;

-- ---- 5. TRANSACTION with COMMIT (ACID: all-or-nothing, then durable) ---------
START TRANSACTION;
INSERT INTO `oltp_hr_analytics` (`emp_id`, `age`, `age_group`, `attrition_flag`, `business_travel`, `daily_rate`, `department`, `distance_from_home`, `education`, `education_field`, `employee_count`, `employee_number`, `environment_satisfaction`, `gender`, `hourly_rate`, `job_involvement`, `job_level`, `job_role`, `job_satisfaction`, `marital_status`, `monthly_income`, `salary_slab`, `monthly_rate`, `num_companies_worked`, `over18`, `over_time`, `percent_salary_hike`, `performance_rating`, `relationship_satisfaction`, `standard_hours`, `stock_option_level`, `total_working_years`, `training_times_last_year`, `work_life_balance`, `years_at_company`, `years_in_current_role`, `years_since_last_promotion`, `years_with_curr_manager`) SELECT `emp_id`, `age`, `age_group`, `attrition_flag`, `business_travel`, `daily_rate`, `department`, `distance_from_home`, `education`, `education_field`, `employee_count`, `employee_number`, `environment_satisfaction`, `gender`, `hourly_rate`, `job_involvement`, `job_level`, `job_role`, `job_satisfaction`, `marital_status`, `monthly_income`, `salary_slab`, `monthly_rate`, `num_companies_worked`, `over18`, `over_time`, `percent_salary_hike`, `performance_rating`, `relationship_satisfaction`, `standard_hours`, `stock_option_level`, `total_working_years`, `training_times_last_year`, `work_life_balance`, `years_at_company`, `years_in_current_role`, `years_since_last_promotion`, `years_with_curr_manager` FROM `oltp_hr_analytics` WHERE oltp_id = 1;
SET @tx_id = LAST_INSERT_ID();
UPDATE `oltp_hr_analytics` SET `age` = `age` + 1 WHERE oltp_id = @tx_id;
SELECT oltp_id, `age` FROM `oltp_hr_analytics` WHERE oltp_id = @tx_id;   -- visible inside the transaction
COMMIT;
SELECT COUNT(*) AS rows_after_commit FROM `oltp_hr_analytics`;

-- ---- 6. TRANSACTION with ROLLBACK (undo) ----------------------------------------
SELECT COUNT(*) AS before_tx FROM `oltp_hr_analytics`;
START TRANSACTION;
DELETE FROM `oltp_hr_analytics` WHERE oltp_id <= 10;
SELECT COUNT(*) AS inside_tx FROM `oltp_hr_analytics`;
ROLLBACK;
SELECT COUNT(*) AS after_rollback FROM `oltp_hr_analytics`;   -- same as before_tx

-- ---- 7. SAVEPOINT : partial rollback -------------------------------------------
START TRANSACTION;
UPDATE `oltp_hr_analytics` SET `age` = `age` + 1 WHERE oltp_id = 1;
SAVEPOINT after_first_update;
UPDATE `oltp_hr_analytics` SET `age` = `age` + 1000 WHERE oltp_id = 2;
ROLLBACK TO SAVEPOINT after_first_update;   -- undoes only the 2nd update
SELECT oltp_id, `age` FROM `oltp_hr_analytics` WHERE oltp_id IN (1, 2);
ROLLBACK;                                   -- undo everything

-- ---- 8. LOCKING (try in two Workbench tabs) --------------------------------------
-- Session 1:  START TRANSACTION; SELECT * FROM `oltp_hr_analytics` WHERE oltp_id = 1 FOR UPDATE;   (row is locked)
-- Session 2:  UPDATE `oltp_hr_analytics` SET `age` = 0 WHERE oltp_id = 1;                            (waits until session 1 COMMIT/ROLLBACK)

-- ---- 9. TRIGGER : automatic audit trail of every update ------------------------
DROP TABLE IF EXISTS `oltp_hr_analytics_audit`;
CREATE TABLE `oltp_hr_analytics_audit` (audit_id INT AUTO_INCREMENT PRIMARY KEY, oltp_id BIGINT, old_value DECIMAL(20,4), new_value DECIMAL(20,4), changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TRIGGER IF EXISTS `trg_hr_analytics_audit`;
DELIMITER $$
CREATE TRIGGER `trg_hr_analytics_audit` AFTER UPDATE ON `oltp_hr_analytics`
FOR EACH ROW
BEGIN
  IF NOT (OLD.`age` <=> NEW.`age`) THEN
    INSERT INTO `oltp_hr_analytics_audit` (oltp_id, old_value, new_value) VALUES (OLD.oltp_id, OLD.`age`, NEW.`age`);
  END IF;
END$$
DELIMITER ;
UPDATE `oltp_hr_analytics` SET `age` = `age` + 5 WHERE oltp_id = 3;
SELECT * FROM `oltp_hr_analytics_audit`;
UPDATE `oltp_hr_analytics` SET `age` = `age` - 5 WHERE oltp_id = 3;   -- restore

-- ---- 10. WHY OLTP IS FAST FOR POINT QUERIES BUT NOT FOR ANALYSIS -------------------
EXPLAIN SELECT * FROM `oltp_hr_analytics` WHERE oltp_id = 1;                        -- type=const : index lookup, 1 row
EXPLAIN SELECT `age_group`, SUM(`age`) FROM `oltp_hr_analytics` GROUP BY `age_group`;    -- full table scan + temp table
