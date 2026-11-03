-- ========================================================================
-- EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [Employee]
-- OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).
-- Measure: Employees Left (`leave_or_not`)   Dimensions: city, education, payment_tier
-- Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.
-- ========================================================================

USE `dmbi_employee_star`;
SET SESSION group_concat_max_len = 1000000;

-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------
SELECT d_city.`city` AS city, SUM(f.`leave_or_not`) AS `Employees Left`, SUM(f.`experience_in_current_domain`) AS `Total Experience Years`, COUNT(*) AS fact_rows
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
GROUP BY d_city.`city`
ORDER BY 2 DESC;

-- ---- 2. ROLL-UP (dimension hierarchy): city > education > ALL --------------------------------
SELECT IF(GROUPING(d_city.`city`), 'ALL', d_city.`city`) AS city_,
       IF(GROUPING(d_education.`education`), 'ALL', d_education.`education`) AS education_,
       SUM(f.`leave_or_not`) AS `Employees Left`
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key`
GROUP BY d_city.`city`, d_education.`education` WITH ROLLUP;

-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----
SET @top_a = (SELECT d_city.`city` FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key` GROUP BY d_city.`city` ORDER BY SUM(f.`leave_or_not`) DESC LIMIT 1);
SET @top_b = (SELECT d_education.`education` FROM `fact_employee` f
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key` GROUP BY d_education.`education` ORDER BY SUM(f.`leave_or_not`) DESC LIMIT 1);
SELECT @top_a AS top_city, @top_b AS top_education;

-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------
-- Level 1 : by city
SELECT d_city.`city` AS city, SUM(f.`leave_or_not`) AS `Employees Left`
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
GROUP BY d_city.`city` ORDER BY 2 DESC;
-- Level 2 : drill into the top city, split by education
SELECT d_city.`city` AS city, d_education.`education` AS education, SUM(f.`leave_or_not`) AS `Employees Left`
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key`
WHERE d_city.`city` = @top_a
GROUP BY d_city.`city`, d_education.`education` ORDER BY 3 DESC;
-- Level 3 : drill further into the top education, split by payment_tier
SELECT d_city.`city` AS city, d_education.`education` AS education, d_payment_tier.`payment_tier` AS payment_tier, SUM(f.`leave_or_not`) AS `Employees Left`
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key`
LEFT JOIN `dim_payment_tier` d_payment_tier ON f.`payment_tier_key` = d_payment_tier.`payment_tier_key`
WHERE d_city.`city` = @top_a AND d_education.`education` = @top_b
GROUP BY d_city.`city`, d_education.`education`, d_payment_tier.`payment_tier` ORDER BY 4 DESC LIMIT 20;

-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------
SELECT d_education.`education` AS education, SUM(f.`leave_or_not`) AS `Employees Left`
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key`
WHERE d_city.`city` = @top_a            -- city fixed to its best member
GROUP BY d_education.`education` ORDER BY 2 DESC;

-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------
SELECT d_city.`city` AS city, d_education.`education` AS education, SUM(f.`leave_or_not`) AS `Employees Left`
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key`
WHERE d_city.`city` IN (SELECT member FROM (SELECT d_city.`city` AS member FROM `fact_employee` f LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key` GROUP BY d_city.`city` ORDER BY SUM(f.`leave_or_not`) DESC LIMIT 2) t_city)
  AND d_education.`education` IN (SELECT member FROM (SELECT d_education.`education` AS member FROM `fact_employee` f LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key` GROUP BY d_education.`education` ORDER BY SUM(f.`leave_or_not`) DESC LIMIT 3) t_education)
GROUP BY d_city.`city`, d_education.`education` ORDER BY 3 DESC;

-- ---- 7. PIVOT : rotate education into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------
SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_education.`education` = ', QUOTE(member), ' THEN f.`leave_or_not` ELSE 0 END) AS `', member, '`') ORDER BY member SEPARATOR ', ') FROM (SELECT DISTINCT `education` AS member FROM `dim_education` WHERE `education` IS NOT NULL) x);
SET @pivot_sql = CONCAT('SELECT d_city.`city` AS `city`, ', @pivot_cols, ', SUM(f.`leave_or_not`) AS `Total` FROM `fact_employee` f LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key` LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key` GROUP BY d_city.`city` ORDER BY `Total` DESC');
PREPARE pivot_stmt FROM @pivot_sql;
EXECUTE pivot_stmt;
DEALLOCATE PREPARE pivot_stmt;

-- ---- 8. CUBE : every combination of (city, education) incl. sub-totals and grand total ----------
-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)
SELECT CAST(d_city.`city` AS CHAR) AS city_, CAST(d_education.`education` AS CHAR) AS education_, SUM(f.`leave_or_not`) AS `Employees Left`
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key`
GROUP BY d_city.`city`, d_education.`education`
UNION ALL
SELECT CAST(d_city.`city` AS CHAR), 'ALL', SUM(f.`leave_or_not`)
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
GROUP BY d_city.`city`
UNION ALL
SELECT 'ALL', CAST(d_education.`education` AS CHAR), SUM(f.`leave_or_not`)
FROM `fact_employee` f
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key`
GROUP BY d_education.`education`
UNION ALL
SELECT 'ALL', 'ALL', SUM(f.`leave_or_not`)
FROM `fact_employee` f;

-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %) --------------------
WITH by_member AS (
  SELECT d_city.`city` AS member, SUM(f.`leave_or_not`) AS total
  FROM `fact_employee` f
  LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
  GROUP BY d_city.`city`
)
SELECT member, total,
       RANK() OVER (ORDER BY total DESC) AS rank_,
       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct
FROM by_member ORDER BY rank_;

-- ---- 10. KPI RATIO per city : Attrition Rate % -------------------------------------------------
SELECT d_city.`city` AS city, ROUND(100.0*SUM(f.leave_or_not) / NULLIF(COUNT(*), 0), 2) AS `Attrition Rate %`
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
GROUP BY d_city.`city` ORDER BY 2 DESC;

-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------
DROP TABLE IF EXISTS `agg_employee_by_city_education`;
CREATE TABLE `agg_employee_by_city_education` AS
SELECT d_city.`city` AS city_, d_education.`education` AS education_, SUM(f.`leave_or_not`) AS total_leave_or_not, SUM(f.`experience_in_current_domain`) AS total_experience_in_current_domain, COUNT(*) AS fact_rows
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key`
GROUP BY d_city.`city`, d_education.`education`;
SELECT * FROM `agg_employee_by_city_education` ORDER BY total_leave_or_not DESC LIMIT 10;   -- no joins needed any more
