-- ========================================================================
-- EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [Retail_Transactions_Dataset]
-- OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).
-- Measure: Total Cost (`total_cost`)   Dimensions: city, customer_category, payment_method
-- Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.
-- ========================================================================

USE `dmbi_retail_transactions_star`;
SET SESSION group_concat_max_len = 1000000;

-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------
SELECT d_store.`city` AS city, SUM(f.`total_cost`) AS `Total Cost`, SUM(f.`total_items`) AS `Total Items`, COUNT(*) AS fact_rows
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
GROUP BY d_store.`city`
ORDER BY 2 DESC;

-- ---- 2. ROLL-UP (time hierarchy): day > month > quarter > year > ALL ---------------
-- WITH ROLLUP adds sub-total and grand-total rows; GROUPING() labels them.
SELECT IF(GROUPING(d_date.year_num), 'ALL YEARS', d_date.year_num)       AS year_,
       IF(GROUPING(d_date.quarter_num), 'ALL QUARTERS', d_date.quarter_num) AS quarter_,
       IF(GROUPING(d_date.month_num), 'ALL MONTHS', d_date.month_num)    AS month_,
       SUM(f.`total_cost`) AS `Total Cost`
FROM `fact_transactions` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num WITH ROLLUP;

-- ---- 3. ROLL-UP (dimension hierarchy): city > customer_category > ALL --------------------------------
SELECT IF(GROUPING(d_store.`city`), 'ALL', d_store.`city`) AS city_,
       IF(GROUPING(d_customer.`customer_category`), 'ALL', d_customer.`customer_category`) AS customer_category_,
       SUM(f.`total_cost`) AS `Total Cost`
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_store.`city`, d_customer.`customer_category` WITH ROLLUP;

-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----
SET @top_a = (SELECT d_store.`city` FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key` GROUP BY d_store.`city` ORDER BY SUM(f.`total_cost`) DESC LIMIT 1);
SET @top_b = (SELECT d_customer.`customer_category` FROM `fact_transactions` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key` GROUP BY d_customer.`customer_category` ORDER BY SUM(f.`total_cost`) DESC LIMIT 1);
SELECT @top_a AS top_city, @top_b AS top_customer_category;

-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------
-- Level 1 : by city
SELECT d_store.`city` AS city, SUM(f.`total_cost`) AS `Total Cost`
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
GROUP BY d_store.`city` ORDER BY 2 DESC;
-- Level 2 : drill into the top city, split by customer_category
SELECT d_store.`city` AS city, d_customer.`customer_category` AS customer_category, SUM(f.`total_cost`) AS `Total Cost`
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
WHERE d_store.`city` = @top_a
GROUP BY d_store.`city`, d_customer.`customer_category` ORDER BY 3 DESC;
-- Level 3 : drill further into the top customer_category, split by payment_method
SELECT d_store.`city` AS city, d_customer.`customer_category` AS customer_category, d_payment_method.`payment_method` AS payment_method, SUM(f.`total_cost`) AS `Total Cost`
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_payment_method` d_payment_method ON f.`payment_method_key` = d_payment_method.`payment_method_key`
WHERE d_store.`city` = @top_a AND d_customer.`customer_category` = @top_b
GROUP BY d_store.`city`, d_customer.`customer_category`, d_payment_method.`payment_method` ORDER BY 4 DESC LIMIT 20;

-- Time drill-down : year > quarter > month (for the latest year)
SET @last_year = (SELECT MAX(year_num) FROM dim_date);
SELECT d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name, SUM(f.`total_cost`) AS `Total Cost`
FROM `fact_transactions` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = @last_year
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name ORDER BY d_date.month_num;

-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------
SELECT d_customer.`customer_category` AS customer_category, SUM(f.`total_cost`) AS `Total Cost`
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
WHERE d_store.`city` = @top_a            -- city fixed to its best member
GROUP BY d_customer.`customer_category` ORDER BY 2 DESC;

-- Slice on time : only the latest year
SELECT d_store.`city` AS city, SUM(f.`total_cost`) AS `Total Cost`
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = (SELECT MAX(year_num) FROM dim_date)
GROUP BY d_store.`city` ORDER BY 2 DESC;

-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------
SELECT d_store.`city` AS city, d_customer.`customer_category` AS customer_category, SUM(f.`total_cost`) AS `Total Cost`
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
WHERE d_store.`city` IN (SELECT member FROM (SELECT d_store.`city` AS member FROM `fact_transactions` f LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key` GROUP BY d_store.`city` ORDER BY SUM(f.`total_cost`) DESC LIMIT 2) t_city)
  AND d_customer.`customer_category` IN (SELECT member FROM (SELECT d_customer.`customer_category` AS member FROM `fact_transactions` f LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key` GROUP BY d_customer.`customer_category` ORDER BY SUM(f.`total_cost`) DESC LIMIT 3) t_customer_category)
GROUP BY d_store.`city`, d_customer.`customer_category` ORDER BY 3 DESC;

-- ---- 7. PIVOT : rotate month into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------
SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_date.month_num = ', month_num, ' THEN f.`total_cost` ELSE 0 END) AS `', month_name, '`') ORDER BY month_num SEPARATOR ', ') FROM (SELECT DISTINCT month_num, month_name FROM `dim_date`) x);
SET @pivot_sql = CONCAT('SELECT d_store.`city` AS `city`, ', @pivot_cols, ', SUM(f.`total_cost`) AS `Total` FROM `fact_transactions` f LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key` LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key` GROUP BY d_store.`city` ORDER BY `Total` DESC');
PREPARE pivot_stmt FROM @pivot_sql;
EXECUTE pivot_stmt;
DEALLOCATE PREPARE pivot_stmt;

-- ---- 8. CUBE : every combination of (city, customer_category) incl. sub-totals and grand total ----------
-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)
SELECT CAST(d_store.`city` AS CHAR) AS city_, CAST(d_customer.`customer_category` AS CHAR) AS customer_category_, SUM(f.`total_cost`) AS `Total Cost`
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_store.`city`, d_customer.`customer_category`
UNION ALL
SELECT CAST(d_store.`city` AS CHAR), 'ALL', SUM(f.`total_cost`)
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
GROUP BY d_store.`city`
UNION ALL
SELECT 'ALL', CAST(d_customer.`customer_category` AS CHAR), SUM(f.`total_cost`)
FROM `fact_transactions` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_customer.`customer_category`
UNION ALL
SELECT 'ALL', 'ALL', SUM(f.`total_cost`)
FROM `fact_transactions` f;

-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %) --------------------
WITH by_member AS (
  SELECT d_store.`city` AS member, SUM(f.`total_cost`) AS total
  FROM `fact_transactions` f
  LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
  GROUP BY d_store.`city`
)
SELECT member, total,
       RANK() OVER (ORDER BY total DESC) AS rank_,
       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct
FROM by_member ORDER BY rank_;

-- Running total and month-over-month change
WITH monthly AS (
  SELECT d_date.year_num AS yr, d_date.month_num AS mon, SUM(f.`total_cost`) AS total
  FROM `fact_transactions` f
  LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
  GROUP BY d_date.year_num, d_date.month_num
)
SELECT yr, mon, total,
       SUM(total) OVER (PARTITION BY yr ORDER BY mon) AS year_to_date,
       LAG(total) OVER (ORDER BY yr, mon) AS previous_month,
       ROUND(100 * (total - LAG(total) OVER (ORDER BY yr, mon)) / NULLIF(LAG(total) OVER (ORDER BY yr, mon), 0), 2) AS mom_change_pct
FROM monthly ORDER BY yr, mon;

-- ---- 10. KPI RATIO per city : Discount Rate % -------------------------------------------------
SELECT d_store.`city` AS city, ROUND(100.0*SUM(f.discount_applied) / NULLIF(COUNT(*), 0), 2) AS `Discount Rate %`
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
GROUP BY d_store.`city` ORDER BY 2 DESC;

-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------
DROP TABLE IF EXISTS `agg_retail_transactions_by_city_customer_category`;
CREATE TABLE `agg_retail_transactions_by_city_customer_category` AS
SELECT d_store.`city` AS city_, d_customer.`customer_category` AS customer_category_, SUM(f.`total_cost`) AS total_total_cost, SUM(f.`total_items`) AS total_total_items, COUNT(*) AS fact_rows
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_store.`city`, d_customer.`customer_category`;
SELECT * FROM `agg_retail_transactions_by_city_customer_category` ORDER BY total_total_cost DESC LIMIT 10;   -- no joins needed any more
