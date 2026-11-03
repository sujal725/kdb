-- ========================================================================
-- EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [Financials]
-- OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).
-- Measure: Sales (`sales`)   Dimensions: segment, country, product
-- Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.
-- ========================================================================

USE `dmbi_financials_star`;
SET SESSION group_concat_max_len = 1000000;

-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------
SELECT d_segment.`segment` AS segment, SUM(f.`sales`) AS `Sales`, SUM(f.`profit`) AS `Profit`, COUNT(*) AS fact_rows
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
GROUP BY d_segment.`segment`
ORDER BY 2 DESC;

-- ---- 2. ROLL-UP (time hierarchy): day > month > quarter > year > ALL ---------------
-- WITH ROLLUP adds sub-total and grand-total rows; GROUPING() labels them.
SELECT IF(GROUPING(d_date.year_num), 'ALL YEARS', d_date.year_num)       AS year_,
       IF(GROUPING(d_date.quarter_num), 'ALL QUARTERS', d_date.quarter_num) AS quarter_,
       IF(GROUPING(d_date.month_num), 'ALL MONTHS', d_date.month_num)    AS month_,
       SUM(f.`sales`) AS `Sales`
FROM `fact_sales` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num WITH ROLLUP;

-- ---- 3. ROLL-UP (dimension hierarchy): segment > country > ALL --------------------------------
SELECT IF(GROUPING(d_segment.`segment`), 'ALL', d_segment.`segment`) AS segment_,
       IF(GROUPING(d_country.`country`), 'ALL', d_country.`country`) AS country_,
       SUM(f.`sales`) AS `Sales`
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key`
GROUP BY d_segment.`segment`, d_country.`country` WITH ROLLUP;

-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----
SET @top_a = (SELECT d_segment.`segment` FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key` GROUP BY d_segment.`segment` ORDER BY SUM(f.`sales`) DESC LIMIT 1);
SET @top_b = (SELECT d_country.`country` FROM `fact_sales` f
LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key` GROUP BY d_country.`country` ORDER BY SUM(f.`sales`) DESC LIMIT 1);
SELECT @top_a AS top_segment, @top_b AS top_country;

-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------
-- Level 1 : by segment
SELECT d_segment.`segment` AS segment, SUM(f.`sales`) AS `Sales`
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
GROUP BY d_segment.`segment` ORDER BY 2 DESC;
-- Level 2 : drill into the top segment, split by country
SELECT d_segment.`segment` AS segment, d_country.`country` AS country, SUM(f.`sales`) AS `Sales`
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key`
WHERE d_segment.`segment` = @top_a
GROUP BY d_segment.`segment`, d_country.`country` ORDER BY 3 DESC;
-- Level 3 : drill further into the top country, split by product
SELECT d_segment.`segment` AS segment, d_country.`country` AS country, d_product.`product` AS product, SUM(f.`sales`) AS `Sales`
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key`
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
WHERE d_segment.`segment` = @top_a AND d_country.`country` = @top_b
GROUP BY d_segment.`segment`, d_country.`country`, d_product.`product` ORDER BY 4 DESC LIMIT 20;

-- Time drill-down : year > quarter > month (for the latest year)
SET @last_year = (SELECT MAX(year_num) FROM dim_date);
SELECT d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name, SUM(f.`sales`) AS `Sales`
FROM `fact_sales` f
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = @last_year
GROUP BY d_date.year_num, d_date.quarter_num, d_date.month_num, d_date.month_name ORDER BY d_date.month_num;

-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------
SELECT d_country.`country` AS country, SUM(f.`sales`) AS `Sales`
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key`
WHERE d_segment.`segment` = @top_a            -- segment fixed to its best member
GROUP BY d_country.`country` ORDER BY 2 DESC;

-- Slice on time : only the latest year
SELECT d_segment.`segment` AS segment, SUM(f.`sales`) AS `Sales`
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
WHERE d_date.year_num = (SELECT MAX(year_num) FROM dim_date)
GROUP BY d_segment.`segment` ORDER BY 2 DESC;

-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------
SELECT d_segment.`segment` AS segment, d_country.`country` AS country, SUM(f.`sales`) AS `Sales`
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key`
WHERE d_segment.`segment` IN (SELECT member FROM (SELECT d_segment.`segment` AS member FROM `fact_sales` f LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key` GROUP BY d_segment.`segment` ORDER BY SUM(f.`sales`) DESC LIMIT 2) t_segment)
  AND d_country.`country` IN (SELECT member FROM (SELECT d_country.`country` AS member FROM `fact_sales` f LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key` GROUP BY d_country.`country` ORDER BY SUM(f.`sales`) DESC LIMIT 3) t_country)
GROUP BY d_segment.`segment`, d_country.`country` ORDER BY 3 DESC;

-- ---- 7. PIVOT : rotate month into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------
SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_date.month_num = ', month_num, ' THEN f.`sales` ELSE 0 END) AS `', month_name, '`') ORDER BY month_num SEPARATOR ', ') FROM (SELECT DISTINCT month_num, month_name FROM `dim_date`) x);
SET @pivot_sql = CONCAT('SELECT d_segment.`segment` AS `segment`, ', @pivot_cols, ', SUM(f.`sales`) AS `Total` FROM `fact_sales` f LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key` LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key` GROUP BY d_segment.`segment` ORDER BY `Total` DESC');
PREPARE pivot_stmt FROM @pivot_sql;
EXECUTE pivot_stmt;
DEALLOCATE PREPARE pivot_stmt;

-- ---- 8. CUBE : every combination of (segment, country) incl. sub-totals and grand total ----------
-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)
SELECT CAST(d_segment.`segment` AS CHAR) AS segment_, CAST(d_country.`country` AS CHAR) AS country_, SUM(f.`sales`) AS `Sales`
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key`
GROUP BY d_segment.`segment`, d_country.`country`
UNION ALL
SELECT CAST(d_segment.`segment` AS CHAR), 'ALL', SUM(f.`sales`)
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
GROUP BY d_segment.`segment`
UNION ALL
SELECT 'ALL', CAST(d_country.`country` AS CHAR), SUM(f.`sales`)
FROM `fact_sales` f
LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key`
GROUP BY d_country.`country`
UNION ALL
SELECT 'ALL', 'ALL', SUM(f.`sales`)
FROM `fact_sales` f;

-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %) --------------------
WITH by_member AS (
  SELECT d_segment.`segment` AS member, SUM(f.`sales`) AS total
  FROM `fact_sales` f
  LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
  GROUP BY d_segment.`segment`
)
SELECT member, total,
       RANK() OVER (ORDER BY total DESC) AS rank_,
       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct
FROM by_member ORDER BY rank_;

-- Running total and month-over-month change
WITH monthly AS (
  SELECT d_date.year_num AS yr, d_date.month_num AS mon, SUM(f.`sales`) AS total
  FROM `fact_sales` f
  LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`
  GROUP BY d_date.year_num, d_date.month_num
)
SELECT yr, mon, total,
       SUM(total) OVER (PARTITION BY yr ORDER BY mon) AS year_to_date,
       LAG(total) OVER (ORDER BY yr, mon) AS previous_month,
       ROUND(100 * (total - LAG(total) OVER (ORDER BY yr, mon)) / NULLIF(LAG(total) OVER (ORDER BY yr, mon), 0), 2) AS mom_change_pct
FROM monthly ORDER BY yr, mon;

-- ---- 10. KPI RATIO per segment : Profit Margin % -------------------------------------------------
SELECT d_segment.`segment` AS segment, ROUND(100.0*SUM(f.profit) / NULLIF(SUM(f.sales), 0), 2) AS `Profit Margin %`
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
GROUP BY d_segment.`segment` ORDER BY 2 DESC;

-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------
DROP TABLE IF EXISTS `agg_financials_by_segment_country`;
CREATE TABLE `agg_financials_by_segment_country` AS
SELECT d_segment.`segment` AS segment_, d_country.`country` AS country_, SUM(f.`sales`) AS total_sales, SUM(f.`profit`) AS total_profit, COUNT(*) AS fact_rows
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key`
GROUP BY d_segment.`segment`, d_country.`country`;
SELECT * FROM `agg_financials_by_segment_country` ORDER BY total_sales DESC LIMIT 10;   -- no joins needed any more
