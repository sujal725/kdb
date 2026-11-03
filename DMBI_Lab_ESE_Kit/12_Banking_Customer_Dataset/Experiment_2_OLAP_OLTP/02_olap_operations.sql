-- ========================================================================
-- EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [Banking_Customer_Dataset]
-- OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).
-- Measure: Total Balance (`balance`)   Dimensions: geography, gender, credit_band
-- Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.
-- ========================================================================

USE `dmbi_banking_customer_star`;
SET SESSION group_concat_max_len = 1000000;

-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------
SELECT d_geography.`geography` AS geography, SUM(f.`balance`) AS `Total Balance`, SUM(f.`estimated_salary`) AS `Total Estimated Salary`, COUNT(*) AS fact_rows
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
GROUP BY d_geography.`geography`
ORDER BY 2 DESC;

-- ---- 2. ROLL-UP (dimension hierarchy): geography > gender > ALL --------------------------------
SELECT IF(GROUPING(d_geography.`geography`), 'ALL', d_geography.`geography`) AS geography_,
       IF(GROUPING(d_customer.`gender`), 'ALL', d_customer.`gender`) AS gender_,
       SUM(f.`balance`) AS `Total Balance`
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_geography.`geography`, d_customer.`gender` WITH ROLLUP;

-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----
SET @top_a = (SELECT d_geography.`geography` FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key` GROUP BY d_geography.`geography` ORDER BY SUM(f.`balance`) DESC LIMIT 1);
SET @top_b = (SELECT d_customer.`gender` FROM `fact_bank_customer` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key` GROUP BY d_customer.`gender` ORDER BY SUM(f.`balance`) DESC LIMIT 1);
SELECT @top_a AS top_geography, @top_b AS top_gender;

-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------
-- Level 1 : by geography
SELECT d_geography.`geography` AS geography, SUM(f.`balance`) AS `Total Balance`
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
GROUP BY d_geography.`geography` ORDER BY 2 DESC;
-- Level 2 : drill into the top geography, split by gender
SELECT d_geography.`geography` AS geography, d_customer.`gender` AS gender, SUM(f.`balance`) AS `Total Balance`
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
WHERE d_geography.`geography` = @top_a
GROUP BY d_geography.`geography`, d_customer.`gender` ORDER BY 3 DESC;
-- Level 3 : drill further into the top gender, split by credit_band
SELECT d_geography.`geography` AS geography, d_customer.`gender` AS gender, d_credit_band.`credit_band` AS credit_band, SUM(f.`balance`) AS `Total Balance`
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_credit_band` d_credit_band ON f.`credit_band_key` = d_credit_band.`credit_band_key`
WHERE d_geography.`geography` = @top_a AND d_customer.`gender` = @top_b
GROUP BY d_geography.`geography`, d_customer.`gender`, d_credit_band.`credit_band` ORDER BY 4 DESC LIMIT 20;

-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------
SELECT d_customer.`gender` AS gender, SUM(f.`balance`) AS `Total Balance`
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
WHERE d_geography.`geography` = @top_a            -- geography fixed to its best member
GROUP BY d_customer.`gender` ORDER BY 2 DESC;

-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------
SELECT d_geography.`geography` AS geography, d_customer.`gender` AS gender, SUM(f.`balance`) AS `Total Balance`
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
WHERE d_geography.`geography` IN (SELECT member FROM (SELECT d_geography.`geography` AS member FROM `fact_bank_customer` f LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key` GROUP BY d_geography.`geography` ORDER BY SUM(f.`balance`) DESC LIMIT 2) t_geography)
  AND d_customer.`gender` IN (SELECT member FROM (SELECT d_customer.`gender` AS member FROM `fact_bank_customer` f LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key` GROUP BY d_customer.`gender` ORDER BY SUM(f.`balance`) DESC LIMIT 3) t_gender)
GROUP BY d_geography.`geography`, d_customer.`gender` ORDER BY 3 DESC;

-- ---- 7. PIVOT : rotate gender into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------
SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_customer.`gender` = ', QUOTE(member), ' THEN f.`balance` ELSE 0 END) AS `', member, '`') ORDER BY member SEPARATOR ', ') FROM (SELECT DISTINCT `gender` AS member FROM `dim_customer` WHERE `gender` IS NOT NULL) x);
SET @pivot_sql = CONCAT('SELECT d_geography.`geography` AS `geography`, ', @pivot_cols, ', SUM(f.`balance`) AS `Total` FROM `fact_bank_customer` f LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key` LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key` GROUP BY d_geography.`geography` ORDER BY `Total` DESC');
PREPARE pivot_stmt FROM @pivot_sql;
EXECUTE pivot_stmt;
DEALLOCATE PREPARE pivot_stmt;

-- ---- 8. CUBE : every combination of (geography, gender) incl. sub-totals and grand total ----------
-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)
SELECT CAST(d_geography.`geography` AS CHAR) AS geography_, CAST(d_customer.`gender` AS CHAR) AS gender_, SUM(f.`balance`) AS `Total Balance`
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_geography.`geography`, d_customer.`gender`
UNION ALL
SELECT CAST(d_geography.`geography` AS CHAR), 'ALL', SUM(f.`balance`)
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
GROUP BY d_geography.`geography`
UNION ALL
SELECT 'ALL', CAST(d_customer.`gender` AS CHAR), SUM(f.`balance`)
FROM `fact_bank_customer` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_customer.`gender`
UNION ALL
SELECT 'ALL', 'ALL', SUM(f.`balance`)
FROM `fact_bank_customer` f;

-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %) --------------------
WITH by_member AS (
  SELECT d_geography.`geography` AS member, SUM(f.`balance`) AS total
  FROM `fact_bank_customer` f
  LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
  GROUP BY d_geography.`geography`
)
SELECT member, total,
       RANK() OVER (ORDER BY total DESC) AS rank_,
       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct
FROM by_member ORDER BY rank_;

-- ---- 10. KPI RATIO per geography : Churn Rate % -------------------------------------------------
SELECT d_geography.`geography` AS geography, ROUND(100.0*SUM(f.exited) / NULLIF(COUNT(*), 0), 2) AS `Churn Rate %`
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
GROUP BY d_geography.`geography` ORDER BY 2 DESC;

-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------
DROP TABLE IF EXISTS `agg_banking_customer_by_geography_gender`;
CREATE TABLE `agg_banking_customer_by_geography_gender` AS
SELECT d_geography.`geography` AS geography_, d_customer.`gender` AS gender_, SUM(f.`balance`) AS total_balance, SUM(f.`estimated_salary`) AS total_estimated_salary, COUNT(*) AS fact_rows
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_geography.`geography`, d_customer.`gender`;
SELECT * FROM `agg_banking_customer_by_geography_gender` ORDER BY total_balance DESC LIMIT 10;   -- no joins needed any more
