-- ========================================================================
-- EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [HR_Analytics_Dataset]
-- OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).
-- Measure: Monthly Income (`monthly_income`)   Dimensions: department, job_role, gender
-- Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.
-- ========================================================================

USE `dmbi_hr_analytics_star`;
SET SESSION group_concat_max_len = 1000000;

-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------
SELECT d_job.`department` AS department, SUM(f.`monthly_income`) AS `Monthly Income`, SUM(f.`attrition_flag`) AS `Attrition Count`, COUNT(*) AS fact_rows
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
GROUP BY d_job.`department`
ORDER BY 2 DESC;

-- ---- 2. ROLL-UP (dimension hierarchy): department > job_role > ALL --------------------------------
SELECT IF(GROUPING(d_job.`department`), 'ALL', d_job.`department`) AS department_,
       IF(GROUPING(d_job.`job_role`), 'ALL', d_job.`job_role`) AS job_role_,
       SUM(f.`monthly_income`) AS `Monthly Income`
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
GROUP BY d_job.`department`, d_job.`job_role` WITH ROLLUP;

-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----
SET @top_a = (SELECT d_job.`department` FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key` GROUP BY d_job.`department` ORDER BY SUM(f.`monthly_income`) DESC LIMIT 1);
SET @top_b = (SELECT d_job.`job_role` FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key` GROUP BY d_job.`job_role` ORDER BY SUM(f.`monthly_income`) DESC LIMIT 1);
SELECT @top_a AS top_department, @top_b AS top_job_role;

-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------
-- Level 1 : by department
SELECT d_job.`department` AS department, SUM(f.`monthly_income`) AS `Monthly Income`
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
GROUP BY d_job.`department` ORDER BY 2 DESC;
-- Level 2 : drill into the top department, split by job_role
SELECT d_job.`department` AS department, d_job.`job_role` AS job_role, SUM(f.`monthly_income`) AS `Monthly Income`
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
WHERE d_job.`department` = @top_a
GROUP BY d_job.`department`, d_job.`job_role` ORDER BY 3 DESC;
-- Level 3 : drill further into the top job_role, split by gender
SELECT d_job.`department` AS department, d_job.`job_role` AS job_role, d_employee_demo.`gender` AS gender, SUM(f.`monthly_income`) AS `Monthly Income`
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
LEFT JOIN `dim_employee_demo` d_employee_demo ON f.`employee_demo_key` = d_employee_demo.`employee_demo_key`
WHERE d_job.`department` = @top_a AND d_job.`job_role` = @top_b
GROUP BY d_job.`department`, d_job.`job_role`, d_employee_demo.`gender` ORDER BY 4 DESC LIMIT 20;

-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------
SELECT d_job.`job_role` AS job_role, SUM(f.`monthly_income`) AS `Monthly Income`
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
WHERE d_job.`department` = @top_a            -- department fixed to its best member
GROUP BY d_job.`job_role` ORDER BY 2 DESC;

-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------
SELECT d_job.`department` AS department, d_job.`job_role` AS job_role, SUM(f.`monthly_income`) AS `Monthly Income`
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
WHERE d_job.`department` IN (SELECT member FROM (SELECT d_job.`department` AS member FROM `fact_employee_hr` f LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key` GROUP BY d_job.`department` ORDER BY SUM(f.`monthly_income`) DESC LIMIT 2) t_department)
  AND d_job.`job_role` IN (SELECT member FROM (SELECT d_job.`job_role` AS member FROM `fact_employee_hr` f LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key` GROUP BY d_job.`job_role` ORDER BY SUM(f.`monthly_income`) DESC LIMIT 3) t_job_role)
GROUP BY d_job.`department`, d_job.`job_role` ORDER BY 3 DESC;

-- ---- 7. PIVOT : rotate job_role into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------
SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_job.`job_role` = ', QUOTE(member), ' THEN f.`monthly_income` ELSE 0 END) AS `', member, '`') ORDER BY member SEPARATOR ', ') FROM (SELECT DISTINCT `job_role` AS member FROM `dim_job` WHERE `job_role` IS NOT NULL) x);
SET @pivot_sql = CONCAT('SELECT d_job.`department` AS `department`, ', @pivot_cols, ', SUM(f.`monthly_income`) AS `Total` FROM `fact_employee_hr` f LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key` GROUP BY d_job.`department` ORDER BY `Total` DESC');
PREPARE pivot_stmt FROM @pivot_sql;
EXECUTE pivot_stmt;
DEALLOCATE PREPARE pivot_stmt;

-- ---- 8. CUBE : every combination of (department, job_role) incl. sub-totals and grand total ----------
-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)
SELECT CAST(d_job.`department` AS CHAR) AS department_, CAST(d_job.`job_role` AS CHAR) AS job_role_, SUM(f.`monthly_income`) AS `Monthly Income`
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
GROUP BY d_job.`department`, d_job.`job_role`
UNION ALL
SELECT CAST(d_job.`department` AS CHAR), 'ALL', SUM(f.`monthly_income`)
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
GROUP BY d_job.`department`
UNION ALL
SELECT 'ALL', CAST(d_job.`job_role` AS CHAR), SUM(f.`monthly_income`)
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
GROUP BY d_job.`job_role`
UNION ALL
SELECT 'ALL', 'ALL', SUM(f.`monthly_income`)
FROM `fact_employee_hr` f;

-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %) --------------------
WITH by_member AS (
  SELECT d_job.`department` AS member, SUM(f.`monthly_income`) AS total
  FROM `fact_employee_hr` f
  LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
  GROUP BY d_job.`department`
)
SELECT member, total,
       RANK() OVER (ORDER BY total DESC) AS rank_,
       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct
FROM by_member ORDER BY rank_;

-- ---- 10. KPI RATIO per department : Attrition Rate % -------------------------------------------------
SELECT d_job.`department` AS department, ROUND(100.0*SUM(f.attrition_flag) / NULLIF(COUNT(*), 0), 2) AS `Attrition Rate %`
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
GROUP BY d_job.`department` ORDER BY 2 DESC;

-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------
DROP TABLE IF EXISTS `agg_hr_analytics_by_department_job_role`;
CREATE TABLE `agg_hr_analytics_by_department_job_role` AS
SELECT d_job.`department` AS department_, d_job.`job_role` AS job_role_, SUM(f.`monthly_income`) AS total_monthly_income, SUM(f.`attrition_flag`) AS total_attrition_flag, COUNT(*) AS fact_rows
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
GROUP BY d_job.`department`, d_job.`job_role`;
SELECT * FROM `agg_hr_analytics_by_department_job_role` ORDER BY total_monthly_income DESC LIMIT 10;   -- no joins needed any more
