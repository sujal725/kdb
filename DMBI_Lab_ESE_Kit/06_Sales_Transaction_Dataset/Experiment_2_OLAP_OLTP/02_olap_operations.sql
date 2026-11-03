-- ========================================================================
-- EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [Sales_Transaction_Dataset]
-- OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).
-- Measure: Sales Amount (`sales_amount`)   Dimensions: country, month_name, product_name
-- Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.
-- ========================================================================

USE `dmbi_sales_transaction_star`;
SET SESSION group_concat_max_len = 1000000;

-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------
SELECT d_customer.`country` AS country, SUM(f.`sales_amount`) AS `Sales Amount`, SUM(f.`quantity`) AS `Quantity`, COUNT(*) AS fact_rows
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_customer.`country`
ORDER BY 2 DESC;

-- ---- 2. ROLL-UP (time hierarchy): day > month > quarter > year > ALL ---------------
-- WITH ROLLUP adds sub-total and grand-total rows; GROUPING() labels them.
SELECT IF(GROUPING(d_date.year_num), 'ALL YEARS', d_date.year_num)       AS year_,
       IF(GROUPING(d_date.quarter_num), 'ALL QUARTERS', d_date.quarter_num) AS quarter_,
       IF(GROUPING(d_date.month_num), 'ALL MONTHS', d_date.month_num)    AS month_,
       SUM(f.`sales_amount`) AS `Sales Amount`
FROM `fact_sales` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num WITH ROLLUP;

-- ---- 3. ROLL-UP (dimension hierarchy): country > month_name > ALL --------------------------------
SELECT IF(GROUPING(d_customer.`country`), 'ALL', d_customer.`country`) AS country_,
       IF(GROUPING(d_date.`month_name`), 'ALL', d_date.`month_name`) AS month_name_,
       SUM(f.`sales_amount`) AS `Sales Amount`
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
GROUP BY d_customer.`country`, d_date.`month_name` WITH ROLLUP;

-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----
SET @top_a = (SELECT d_customer.`country` FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key` GROUP BY d_customer.`country` ORDER BY SUM(f.`sales_amount`) DESC LIMIT 1);
SET @top_b = (SELECT d_date.`month_name` FROM `fact_sales` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key` GROUP BY d_date.`month_name` ORDER BY SUM(f.`sales_amount`) DESC LIMIT 1);
SELECT @top_a AS top_country, @top_b AS top_month_name;

-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------
-- Level 1 : by country
SELECT d_customer.`country` AS country, SUM(f.`sales_amount`) AS `Sales Amount`
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_customer.`country` ORDER BY 2 DESC;
-- Level 2 : drill into the top country, split by month_name
SELECT d_customer.`country` AS country, d_date.`month_name` AS month_name, SUM(f.`sales_amount`) AS `Sales Amount`
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_customer.`country` = @top_a
GROUP BY d_customer.`country`, d_date.`month_name` ORDER BY 3 DESC;
-- Level 3 : drill further into the top month_name, split by product_name
SELECT d_customer.`country` AS country, d_date.`month_name` AS month_name, d_product.`product_name` AS product_name, SUM(f.`sales_amount`) AS `Sales Amount`
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
WHERE d_customer.`country` = @top_a AND d_date.`month_name` = @top_b
GROUP BY d_customer.`country`, d_date.`month_name`, d_product.`product_name` ORDER BY 4 DESC LIMIT 20;

-- Time drill-down : year > quarter > month (for the latest year)
SET @last_year = (SELECT MAX(year_num) FROM dim_date);
SELECT d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name, SUM(f.`sales_amount`) AS `Sales Amount`
FROM `fact_sales` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = @last_year
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name ORDER BY d_date.month_num;

-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------
SELECT d_date.`month_name` AS month_name, SUM(f.`sales_amount`) AS `Sales Amount`
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_customer.`country` = @top_a            -- country fixed to its best member
GROUP BY d_date.`month_name` ORDER BY 2 DESC;

-- Slice on time : only the latest year
SELECT d_customer.`country` AS country, SUM(f.`sales_amount`) AS `Sales Amount`
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = (SELECT MAX(year_num) FROM dim_date)
GROUP BY d_customer.`country` ORDER BY 2 DESC;

-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------
SELECT d_customer.`country` AS country, d_date.`month_name` AS month_name, SUM(f.`sales_amount`) AS `Sales Amount`
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_customer.`country` IN (SELECT member FROM (SELECT d_customer.`country` AS member FROM `fact_sales` f LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key` GROUP BY d_customer.`country` ORDER BY SUM(f.`sales_amount`) DESC LIMIT 2) t_country)
  AND d_date.`month_name` IN (SELECT member FROM (SELECT d_date.`month_name` AS member FROM `fact_sales` f LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key` GROUP BY d_date.`month_name` ORDER BY SUM(f.`sales_amount`) DESC LIMIT 3) t_month_name)
GROUP BY d_customer.`country`, d_date.`month_name` ORDER BY 3 DESC;

-- ---- 7. PIVOT : rotate month into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------
SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_date.month_num = ', month_num, ' THEN f.`sales_amount` ELSE 0 END) AS `', month_name, '`') ORDER BY month_num SEPARATOR ', ') FROM (SELECT DISTINCT month_num, month_name FROM `dim_date`) x);
SET @pivot_sql = CONCAT('SELECT d_customer.`country` AS `country`, ', @pivot_cols, ', SUM(f.`sales_amount`) AS `Total` FROM `fact_sales` f LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key` LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key` GROUP BY d_customer.`country` ORDER BY `Total` DESC');
PREPARE pivot_stmt FROM @pivot_sql;
EXECUTE pivot_stmt;
DEALLOCATE PREPARE pivot_stmt;

-- ---- 8. CUBE : every combination of (country, month_name) incl. sub-totals and grand total ----------
-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)
SELECT CAST(d_customer.`country` AS CHAR) AS country_, CAST(d_date.`month_name` AS CHAR) AS month_name_, SUM(f.`sales_amount`) AS `Sales Amount`
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
GROUP BY d_customer.`country`, d_date.`month_name`
UNION ALL
SELECT CAST(d_customer.`country` AS CHAR), 'ALL', SUM(f.`sales_amount`)
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_customer.`country`
UNION ALL
SELECT 'ALL', CAST(d_date.`month_name` AS CHAR), SUM(f.`sales_amount`)
FROM `fact_sales` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
GROUP BY d_date.`month_name`
UNION ALL
SELECT 'ALL', 'ALL', SUM(f.`sales_amount`)
FROM `fact_sales` f;

-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %) --------------------
WITH by_member AS (
  SELECT d_customer.`country` AS member, SUM(f.`sales_amount`) AS total
  FROM `fact_sales` f
  LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
  GROUP BY d_customer.`country`
)
SELECT member, total,
       RANK() OVER (ORDER BY total DESC) AS rank_,
       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct
FROM by_member ORDER BY rank_;

-- Running total and month-over-month change
WITH monthly AS (
  SELECT d_date.year_num AS yr, d_date.month_num AS mon, SUM(f.`sales_amount`) AS total
  FROM `fact_sales` f
  LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
  GROUP BY d_date.year_num, d_date.month_num
)
SELECT yr, mon, total,
       SUM(total) OVER (PARTITION BY yr ORDER BY mon) AS year_to_date,
       LAG(total) OVER (ORDER BY yr, mon) AS previous_month,
       ROUND(100 * (total - LAG(total) OVER (ORDER BY yr, mon)) / NULLIF(LAG(total) OVER (ORDER BY yr, mon), 0), 2) AS mom_change_pct
FROM monthly ORDER BY yr, mon;

-- ---- 10. KPI RATIO per country : Cancellation Rate % -------------------------------------------------
SELECT d_customer.`country` AS country, ROUND(100.0*SUM(f.is_cancellation) / NULLIF(COUNT(*), 0), 2) AS `Cancellation Rate %`
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_customer.`country` ORDER BY 2 DESC;

-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------
DROP TABLE IF EXISTS `agg_sales_transaction_by_country_month_name`;
CREATE TABLE `agg_sales_transaction_by_country_month_name` AS
SELECT d_customer.`country` AS country_, d_date.`month_name` AS month_name_, SUM(f.`sales_amount`) AS total_sales_amount, SUM(f.`quantity`) AS total_quantity, COUNT(*) AS fact_rows
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
GROUP BY d_customer.`country`, d_date.`month_name`;
SELECT * FROM `agg_sales_transaction_by_country_month_name` ORDER BY total_sales_amount DESC LIMIT 10;   -- no joins needed any more
