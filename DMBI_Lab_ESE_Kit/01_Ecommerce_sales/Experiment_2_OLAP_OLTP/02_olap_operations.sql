-- ========================================================================
-- EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [Ecommerce_sales]
-- OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).
-- Measure: Net Revenue (`net_revenue`)   Dimensions: product_category, customer_segment, discount_band
-- Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.
-- ========================================================================

USE `dmbi_ecommerce_sales_star`;
SET SESSION group_concat_max_len = 1000000;

-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------
SELECT d_product_category.`product_category` AS product_category, SUM(f.`net_revenue`) AS `Net Revenue`, SUM(f.`units_sold`) AS `Units Sold`, COUNT(*) AS fact_rows
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
GROUP BY d_product_category.`product_category`
ORDER BY 2 DESC;

-- ---- 2. ROLL-UP (time hierarchy): day > month > quarter > year > ALL ---------------
-- WITH ROLLUP adds sub-total and grand-total rows; GROUPING() labels them.
SELECT IF(GROUPING(d_date.year_num), 'ALL YEARS', d_date.year_num)       AS year_,
       IF(GROUPING(d_date.quarter_num), 'ALL QUARTERS', d_date.quarter_num) AS quarter_,
       IF(GROUPING(d_date.month_num), 'ALL MONTHS', d_date.month_num)    AS month_,
       SUM(f.`net_revenue`) AS `Net Revenue`
FROM `fact_sales` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num WITH ROLLUP;

-- ---- 3. ROLL-UP (dimension hierarchy): product_category > customer_segment > ALL --------------------------------
SELECT IF(GROUPING(d_product_category.`product_category`), 'ALL', d_product_category.`product_category`) AS product_category_,
       IF(GROUPING(d_customer_segment.`customer_segment`), 'ALL', d_customer_segment.`customer_segment`) AS customer_segment_,
       SUM(f.`net_revenue`) AS `Net Revenue`
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key`
GROUP BY d_product_category.`product_category`, d_customer_segment.`customer_segment` WITH ROLLUP;

-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----
SET @top_a = (SELECT d_product_category.`product_category` FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key` GROUP BY d_product_category.`product_category` ORDER BY SUM(f.`net_revenue`) DESC LIMIT 1);
SET @top_b = (SELECT d_customer_segment.`customer_segment` FROM `fact_sales` f
LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key` GROUP BY d_customer_segment.`customer_segment` ORDER BY SUM(f.`net_revenue`) DESC LIMIT 1);
SELECT @top_a AS top_product_category, @top_b AS top_customer_segment;

-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------
-- Level 1 : by product_category
SELECT d_product_category.`product_category` AS product_category, SUM(f.`net_revenue`) AS `Net Revenue`
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
GROUP BY d_product_category.`product_category` ORDER BY 2 DESC;
-- Level 2 : drill into the top product_category, split by customer_segment
SELECT d_product_category.`product_category` AS product_category, d_customer_segment.`customer_segment` AS customer_segment, SUM(f.`net_revenue`) AS `Net Revenue`
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key`
WHERE d_product_category.`product_category` = @top_a
GROUP BY d_product_category.`product_category`, d_customer_segment.`customer_segment` ORDER BY 3 DESC;
-- Level 3 : drill further into the top customer_segment, split by discount_band
SELECT d_product_category.`product_category` AS product_category, d_customer_segment.`customer_segment` AS customer_segment, d_discount_band.`discount_band` AS discount_band, SUM(f.`net_revenue`) AS `Net Revenue`
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key`
LEFT JOIN `dim_discount_band` d_discount_band ON f.`discount_band_key` = d_discount_band.`discount_band_key`
WHERE d_product_category.`product_category` = @top_a AND d_customer_segment.`customer_segment` = @top_b
GROUP BY d_product_category.`product_category`, d_customer_segment.`customer_segment`, d_discount_band.`discount_band` ORDER BY 4 DESC LIMIT 20;

-- Time drill-down : year > quarter > month (for the latest year)
SET @last_year = (SELECT MAX(year_num) FROM dim_date);
SELECT d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name, SUM(f.`net_revenue`) AS `Net Revenue`
FROM `fact_sales` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = @last_year
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name ORDER BY d_date.month_num;

-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------
SELECT d_customer_segment.`customer_segment` AS customer_segment, SUM(f.`net_revenue`) AS `Net Revenue`
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key`
WHERE d_product_category.`product_category` = @top_a            -- product_category fixed to its best member
GROUP BY d_customer_segment.`customer_segment` ORDER BY 2 DESC;

-- Slice on time : only the latest year
SELECT d_product_category.`product_category` AS product_category, SUM(f.`net_revenue`) AS `Net Revenue`
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = (SELECT MAX(year_num) FROM dim_date)
GROUP BY d_product_category.`product_category` ORDER BY 2 DESC;

-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------
SELECT d_product_category.`product_category` AS product_category, d_customer_segment.`customer_segment` AS customer_segment, SUM(f.`net_revenue`) AS `Net Revenue`
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key`
WHERE d_product_category.`product_category` IN (SELECT member FROM (SELECT d_product_category.`product_category` AS member FROM `fact_sales` f LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key` GROUP BY d_product_category.`product_category` ORDER BY SUM(f.`net_revenue`) DESC LIMIT 2) t_product_category)
  AND d_customer_segment.`customer_segment` IN (SELECT member FROM (SELECT d_customer_segment.`customer_segment` AS member FROM `fact_sales` f LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key` GROUP BY d_customer_segment.`customer_segment` ORDER BY SUM(f.`net_revenue`) DESC LIMIT 3) t_customer_segment)
GROUP BY d_product_category.`product_category`, d_customer_segment.`customer_segment` ORDER BY 3 DESC;

-- ---- 7. PIVOT : rotate month into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------
SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_date.month_num = ', month_num, ' THEN f.`net_revenue` ELSE 0 END) AS `', month_name, '`') ORDER BY month_num SEPARATOR ', ') FROM (SELECT DISTINCT month_num, month_name FROM `dim_date`) x);
SET @pivot_sql = CONCAT('SELECT d_product_category.`product_category` AS `product_category`, ', @pivot_cols, ', SUM(f.`net_revenue`) AS `Total` FROM `fact_sales` f LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key` LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key` GROUP BY d_product_category.`product_category` ORDER BY `Total` DESC');
PREPARE pivot_stmt FROM @pivot_sql;
EXECUTE pivot_stmt;
DEALLOCATE PREPARE pivot_stmt;

-- ---- 8. CUBE : every combination of (product_category, customer_segment) incl. sub-totals and grand total ----------
-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)
SELECT CAST(d_product_category.`product_category` AS CHAR) AS product_category_, CAST(d_customer_segment.`customer_segment` AS CHAR) AS customer_segment_, SUM(f.`net_revenue`) AS `Net Revenue`
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key`
GROUP BY d_product_category.`product_category`, d_customer_segment.`customer_segment`
UNION ALL
SELECT CAST(d_product_category.`product_category` AS CHAR), 'ALL', SUM(f.`net_revenue`)
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
GROUP BY d_product_category.`product_category`
UNION ALL
SELECT 'ALL', CAST(d_customer_segment.`customer_segment` AS CHAR), SUM(f.`net_revenue`)
FROM `fact_sales` f
LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key`
GROUP BY d_customer_segment.`customer_segment`
UNION ALL
SELECT 'ALL', 'ALL', SUM(f.`net_revenue`)
FROM `fact_sales` f;

-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %) --------------------
WITH by_member AS (
  SELECT d_product_category.`product_category` AS member, SUM(f.`net_revenue`) AS total
  FROM `fact_sales` f
  LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
  GROUP BY d_product_category.`product_category`
)
SELECT member, total,
       RANK() OVER (ORDER BY total DESC) AS rank_,
       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct
FROM by_member ORDER BY rank_;

-- Running total and month-over-month change
WITH monthly AS (
  SELECT d_date.year_num AS yr, d_date.month_num AS mon, SUM(f.`net_revenue`) AS total
  FROM `fact_sales` f
  LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
  GROUP BY d_date.year_num, d_date.month_num
)
SELECT yr, mon, total,
       SUM(total) OVER (PARTITION BY yr ORDER BY mon) AS year_to_date,
       LAG(total) OVER (ORDER BY yr, mon) AS previous_month,
       ROUND(100 * (total - LAG(total) OVER (ORDER BY yr, mon)) / NULLIF(LAG(total) OVER (ORDER BY yr, mon), 0), 2) AS mom_change_pct
FROM monthly ORDER BY yr, mon;

-- ---- 10. KPI RATIO per product_category : Revenue per Marketing Rupee -------------------------------------------------
SELECT d_product_category.`product_category` AS product_category, ROUND(SUM(f.net_revenue) / NULLIF(SUM(f.marketing_spend), 0), 2) AS `Revenue per Marketing Rupee`
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
GROUP BY d_product_category.`product_category` ORDER BY 2 DESC;

-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------
DROP TABLE IF EXISTS `agg_ecommerce_sales_by_product_category_customer_segment`;
CREATE TABLE `agg_ecommerce_sales_by_product_category_customer_segment` AS
SELECT d_product_category.`product_category` AS product_category_, d_customer_segment.`customer_segment` AS customer_segment_, SUM(f.`net_revenue`) AS total_net_revenue, SUM(f.`units_sold`) AS total_units_sold, COUNT(*) AS fact_rows
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key`
GROUP BY d_product_category.`product_category`, d_customer_segment.`customer_segment`;
SELECT * FROM `agg_ecommerce_sales_by_product_category_customer_segment` ORDER BY total_net_revenue DESC LIMIT 10;   -- no joins needed any more
