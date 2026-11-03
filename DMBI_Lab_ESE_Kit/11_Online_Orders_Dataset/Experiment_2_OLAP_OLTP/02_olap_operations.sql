-- ========================================================================
-- EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [Online_Orders_Dataset]
-- OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).
-- Measure: Total Revenue (`total_revenue`)   Dimensions: product_category, region, payment_method
-- Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.
-- ========================================================================

USE `dmbi_online_orders_star`;
SET SESSION group_concat_max_len = 1000000;

-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------
SELECT d_product.`product_category` AS product_category, SUM(f.`total_revenue`) AS `Total Revenue`, SUM(f.`units_sold`) AS `Units Sold`, COUNT(*) AS fact_rows
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
GROUP BY d_product.`product_category`
ORDER BY 2 DESC;

-- ---- 2. ROLL-UP (time hierarchy): day > month > quarter > year > ALL ---------------
-- WITH ROLLUP adds sub-total and grand-total rows; GROUPING() labels them.
SELECT IF(GROUPING(d_date.year_num), 'ALL YEARS', d_date.year_num)       AS year_,
       IF(GROUPING(d_date.quarter_num), 'ALL QUARTERS', d_date.quarter_num) AS quarter_,
       IF(GROUPING(d_date.month_num), 'ALL MONTHS', d_date.month_num)    AS month_,
       SUM(f.`total_revenue`) AS `Total Revenue`
FROM `fact_orders` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num WITH ROLLUP;

-- ---- 3. ROLL-UP (dimension hierarchy): product_category > region > ALL --------------------------------
SELECT IF(GROUPING(d_product.`product_category`), 'ALL', d_product.`product_category`) AS product_category_,
       IF(GROUPING(d_region.`region`), 'ALL', d_region.`region`) AS region_,
       SUM(f.`total_revenue`) AS `Total Revenue`
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
GROUP BY d_product.`product_category`, d_region.`region` WITH ROLLUP;

-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----
SET @top_a = (SELECT d_product.`product_category` FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key` GROUP BY d_product.`product_category` ORDER BY SUM(f.`total_revenue`) DESC LIMIT 1);
SET @top_b = (SELECT d_region.`region` FROM `fact_orders` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key` GROUP BY d_region.`region` ORDER BY SUM(f.`total_revenue`) DESC LIMIT 1);
SELECT @top_a AS top_product_category, @top_b AS top_region;

-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------
-- Level 1 : by product_category
SELECT d_product.`product_category` AS product_category, SUM(f.`total_revenue`) AS `Total Revenue`
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
GROUP BY d_product.`product_category` ORDER BY 2 DESC;
-- Level 2 : drill into the top product_category, split by region
SELECT d_product.`product_category` AS product_category, d_region.`region` AS region, SUM(f.`total_revenue`) AS `Total Revenue`
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
WHERE d_product.`product_category` = @top_a
GROUP BY d_product.`product_category`, d_region.`region` ORDER BY 3 DESC;
-- Level 3 : drill further into the top region, split by payment_method
SELECT d_product.`product_category` AS product_category, d_region.`region` AS region, d_payment_method.`payment_method` AS payment_method, SUM(f.`total_revenue`) AS `Total Revenue`
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
LEFT JOIN `dim_payment_method` d_payment_method ON f.`payment_method_key` = d_payment_method.`payment_method_key`
WHERE d_product.`product_category` = @top_a AND d_region.`region` = @top_b
GROUP BY d_product.`product_category`, d_region.`region`, d_payment_method.`payment_method` ORDER BY 4 DESC LIMIT 20;

-- Time drill-down : year > quarter > month (for the latest year)
SET @last_year = (SELECT MAX(year_num) FROM dim_date);
SELECT d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name, SUM(f.`total_revenue`) AS `Total Revenue`
FROM `fact_orders` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = @last_year
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name ORDER BY d_date.month_num;

-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------
SELECT d_region.`region` AS region, SUM(f.`total_revenue`) AS `Total Revenue`
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
WHERE d_product.`product_category` = @top_a            -- product_category fixed to its best member
GROUP BY d_region.`region` ORDER BY 2 DESC;

-- Slice on time : only the latest year
SELECT d_product.`product_category` AS product_category, SUM(f.`total_revenue`) AS `Total Revenue`
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = (SELECT MAX(year_num) FROM dim_date)
GROUP BY d_product.`product_category` ORDER BY 2 DESC;

-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------
SELECT d_product.`product_category` AS product_category, d_region.`region` AS region, SUM(f.`total_revenue`) AS `Total Revenue`
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
WHERE d_product.`product_category` IN (SELECT member FROM (SELECT d_product.`product_category` AS member FROM `fact_orders` f LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key` GROUP BY d_product.`product_category` ORDER BY SUM(f.`total_revenue`) DESC LIMIT 2) t_product_category)
  AND d_region.`region` IN (SELECT member FROM (SELECT d_region.`region` AS member FROM `fact_orders` f LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key` GROUP BY d_region.`region` ORDER BY SUM(f.`total_revenue`) DESC LIMIT 3) t_region)
GROUP BY d_product.`product_category`, d_region.`region` ORDER BY 3 DESC;

-- ---- 7. PIVOT : rotate month into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------
SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_date.month_num = ', month_num, ' THEN f.`total_revenue` ELSE 0 END) AS `', month_name, '`') ORDER BY month_num SEPARATOR ', ') FROM (SELECT DISTINCT month_num, month_name FROM `dim_date`) x);
SET @pivot_sql = CONCAT('SELECT d_product.`product_category` AS `product_category`, ', @pivot_cols, ', SUM(f.`total_revenue`) AS `Total` FROM `fact_orders` f LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key` LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key` GROUP BY d_product.`product_category` ORDER BY `Total` DESC');
PREPARE pivot_stmt FROM @pivot_sql;
EXECUTE pivot_stmt;
DEALLOCATE PREPARE pivot_stmt;

-- ---- 8. CUBE : every combination of (product_category, region) incl. sub-totals and grand total ----------
-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)
SELECT CAST(d_product.`product_category` AS CHAR) AS product_category_, CAST(d_region.`region` AS CHAR) AS region_, SUM(f.`total_revenue`) AS `Total Revenue`
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
GROUP BY d_product.`product_category`, d_region.`region`
UNION ALL
SELECT CAST(d_product.`product_category` AS CHAR), 'ALL', SUM(f.`total_revenue`)
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
GROUP BY d_product.`product_category`
UNION ALL
SELECT 'ALL', CAST(d_region.`region` AS CHAR), SUM(f.`total_revenue`)
FROM `fact_orders` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
GROUP BY d_region.`region`
UNION ALL
SELECT 'ALL', 'ALL', SUM(f.`total_revenue`)
FROM `fact_orders` f;

-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %) --------------------
WITH by_member AS (
  SELECT d_product.`product_category` AS member, SUM(f.`total_revenue`) AS total
  FROM `fact_orders` f
  LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
  GROUP BY d_product.`product_category`
)
SELECT member, total,
       RANK() OVER (ORDER BY total DESC) AS rank_,
       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct
FROM by_member ORDER BY rank_;

-- Running total and month-over-month change
WITH monthly AS (
  SELECT d_date.year_num AS yr, d_date.month_num AS mon, SUM(f.`total_revenue`) AS total
  FROM `fact_orders` f
  LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
  GROUP BY d_date.year_num, d_date.month_num
)
SELECT yr, mon, total,
       SUM(total) OVER (PARTITION BY yr ORDER BY mon) AS year_to_date,
       LAG(total) OVER (ORDER BY yr, mon) AS previous_month,
       ROUND(100 * (total - LAG(total) OVER (ORDER BY yr, mon)) / NULLIF(LAG(total) OVER (ORDER BY yr, mon), 0), 2) AS mom_change_pct
FROM monthly ORDER BY yr, mon;

-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------
DROP TABLE IF EXISTS `agg_online_orders_by_product_category_region`;
CREATE TABLE `agg_online_orders_by_product_category_region` AS
SELECT d_product.`product_category` AS product_category_, d_region.`region` AS region_, SUM(f.`total_revenue`) AS total_total_revenue, SUM(f.`units_sold`) AS total_units_sold, COUNT(*) AS fact_rows
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
GROUP BY d_product.`product_category`, d_region.`region`;
SELECT * FROM `agg_online_orders_by_product_category_region` ORDER BY total_total_revenue DESC LIMIT 10;   -- no joins needed any more
