-- ========================================================================
-- EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [Super_Market_Analysis]
-- OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).
-- Measure: Total Sales (`total`)   Dimensions: product_line, city, customer_type
-- Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.
-- ========================================================================

USE `dmbi_super_market_star`;
SET SESSION group_concat_max_len = 1000000;

-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------
SELECT d_product_line.`product_line` AS product_line, SUM(f.`total`) AS `Total Sales`, SUM(f.`gross_income`) AS `Gross Income`, COUNT(*) AS fact_rows
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
GROUP BY d_product_line.`product_line`
ORDER BY 2 DESC;

-- ---- 2. ROLL-UP (time hierarchy): day > month > quarter > year > ALL ---------------
-- WITH ROLLUP adds sub-total and grand-total rows; GROUPING() labels them.
SELECT IF(GROUPING(d_date.year_num), 'ALL YEARS', d_date.year_num)       AS year_,
       IF(GROUPING(d_date.quarter_num), 'ALL QUARTERS', d_date.quarter_num) AS quarter_,
       IF(GROUPING(d_date.month_num), 'ALL MONTHS', d_date.month_num)    AS month_,
       SUM(f.`total`) AS `Total Sales`
FROM `fact_sales` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num WITH ROLLUP;

-- ---- 3. ROLL-UP (dimension hierarchy): product_line > city > ALL --------------------------------
SELECT IF(GROUPING(d_product_line.`product_line`), 'ALL', d_product_line.`product_line`) AS product_line_,
       IF(GROUPING(d_branch.`city`), 'ALL', d_branch.`city`) AS city_,
       SUM(f.`total`) AS `Total Sales`
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key`
GROUP BY d_product_line.`product_line`, d_branch.`city` WITH ROLLUP;

-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----
SET @top_a = (SELECT d_product_line.`product_line` FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key` GROUP BY d_product_line.`product_line` ORDER BY SUM(f.`total`) DESC LIMIT 1);
SET @top_b = (SELECT d_branch.`city` FROM `fact_sales` f
LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key` GROUP BY d_branch.`city` ORDER BY SUM(f.`total`) DESC LIMIT 1);
SELECT @top_a AS top_product_line, @top_b AS top_city;

-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------
-- Level 1 : by product_line
SELECT d_product_line.`product_line` AS product_line, SUM(f.`total`) AS `Total Sales`
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
GROUP BY d_product_line.`product_line` ORDER BY 2 DESC;
-- Level 2 : drill into the top product_line, split by city
SELECT d_product_line.`product_line` AS product_line, d_branch.`city` AS city, SUM(f.`total`) AS `Total Sales`
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key`
WHERE d_product_line.`product_line` = @top_a
GROUP BY d_product_line.`product_line`, d_branch.`city` ORDER BY 3 DESC;
-- Level 3 : drill further into the top city, split by customer_type
SELECT d_product_line.`product_line` AS product_line, d_branch.`city` AS city, d_customer.`customer_type` AS customer_type, SUM(f.`total`) AS `Total Sales`
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
WHERE d_product_line.`product_line` = @top_a AND d_branch.`city` = @top_b
GROUP BY d_product_line.`product_line`, d_branch.`city`, d_customer.`customer_type` ORDER BY 4 DESC LIMIT 20;

-- Time drill-down : year > quarter > month (for the latest year)
SET @last_year = (SELECT MAX(year_num) FROM dim_date);
SELECT d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name, SUM(f.`total`) AS `Total Sales`
FROM `fact_sales` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = @last_year
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name ORDER BY d_date.month_num;

-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------
SELECT d_branch.`city` AS city, SUM(f.`total`) AS `Total Sales`
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key`
WHERE d_product_line.`product_line` = @top_a            -- product_line fixed to its best member
GROUP BY d_branch.`city` ORDER BY 2 DESC;

-- Slice on time : only the latest year
SELECT d_product_line.`product_line` AS product_line, SUM(f.`total`) AS `Total Sales`
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = (SELECT MAX(year_num) FROM dim_date)
GROUP BY d_product_line.`product_line` ORDER BY 2 DESC;

-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------
SELECT d_product_line.`product_line` AS product_line, d_branch.`city` AS city, SUM(f.`total`) AS `Total Sales`
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key`
WHERE d_product_line.`product_line` IN (SELECT member FROM (SELECT d_product_line.`product_line` AS member FROM `fact_sales` f LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key` GROUP BY d_product_line.`product_line` ORDER BY SUM(f.`total`) DESC LIMIT 2) t_product_line)
  AND d_branch.`city` IN (SELECT member FROM (SELECT d_branch.`city` AS member FROM `fact_sales` f LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key` GROUP BY d_branch.`city` ORDER BY SUM(f.`total`) DESC LIMIT 3) t_city)
GROUP BY d_product_line.`product_line`, d_branch.`city` ORDER BY 3 DESC;

-- ---- 7. PIVOT : rotate month into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------
SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_date.month_num = ', month_num, ' THEN f.`total` ELSE 0 END) AS `', month_name, '`') ORDER BY month_num SEPARATOR ', ') FROM (SELECT DISTINCT month_num, month_name FROM `dim_date`) x);
SET @pivot_sql = CONCAT('SELECT d_product_line.`product_line` AS `product_line`, ', @pivot_cols, ', SUM(f.`total`) AS `Total` FROM `fact_sales` f LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key` LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key` GROUP BY d_product_line.`product_line` ORDER BY `Total` DESC');
PREPARE pivot_stmt FROM @pivot_sql;
EXECUTE pivot_stmt;
DEALLOCATE PREPARE pivot_stmt;

-- ---- 8. CUBE : every combination of (product_line, city) incl. sub-totals and grand total ----------
-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)
SELECT CAST(d_product_line.`product_line` AS CHAR) AS product_line_, CAST(d_branch.`city` AS CHAR) AS city_, SUM(f.`total`) AS `Total Sales`
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key`
GROUP BY d_product_line.`product_line`, d_branch.`city`
UNION ALL
SELECT CAST(d_product_line.`product_line` AS CHAR), 'ALL', SUM(f.`total`)
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
GROUP BY d_product_line.`product_line`
UNION ALL
SELECT 'ALL', CAST(d_branch.`city` AS CHAR), SUM(f.`total`)
FROM `fact_sales` f
LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key`
GROUP BY d_branch.`city`
UNION ALL
SELECT 'ALL', 'ALL', SUM(f.`total`)
FROM `fact_sales` f;

-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %) --------------------
WITH by_member AS (
  SELECT d_product_line.`product_line` AS member, SUM(f.`total`) AS total
  FROM `fact_sales` f
  LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
  GROUP BY d_product_line.`product_line`
)
SELECT member, total,
       RANK() OVER (ORDER BY total DESC) AS rank_,
       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct
FROM by_member ORDER BY rank_;

-- Running total and month-over-month change
WITH monthly AS (
  SELECT d_date.year_num AS yr, d_date.month_num AS mon, SUM(f.`total`) AS total
  FROM `fact_sales` f
  LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
  GROUP BY d_date.year_num, d_date.month_num
)
SELECT yr, mon, total,
       SUM(total) OVER (PARTITION BY yr ORDER BY mon) AS year_to_date,
       LAG(total) OVER (ORDER BY yr, mon) AS previous_month,
       ROUND(100 * (total - LAG(total) OVER (ORDER BY yr, mon)) / NULLIF(LAG(total) OVER (ORDER BY yr, mon), 0), 2) AS mom_change_pct
FROM monthly ORDER BY yr, mon;

-- ---- 10. KPI RATIO per product_line : Gross Income % of Sales -------------------------------------------------
SELECT d_product_line.`product_line` AS product_line, ROUND(100.0*SUM(f.gross_income) / NULLIF(SUM(f.total), 0), 2) AS `Gross Income % of Sales`
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
GROUP BY d_product_line.`product_line` ORDER BY 2 DESC;

-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------
DROP TABLE IF EXISTS `agg_super_market_by_product_line_city`;
CREATE TABLE `agg_super_market_by_product_line_city` AS
SELECT d_product_line.`product_line` AS product_line_, d_branch.`city` AS city_, SUM(f.`total`) AS total_total, SUM(f.`gross_income`) AS total_gross_income, COUNT(*) AS fact_rows
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key`
GROUP BY d_product_line.`product_line`, d_branch.`city`;
SELECT * FROM `agg_super_market_by_product_line_city` ORDER BY total_total DESC LIMIT 10;   -- no joins needed any more
