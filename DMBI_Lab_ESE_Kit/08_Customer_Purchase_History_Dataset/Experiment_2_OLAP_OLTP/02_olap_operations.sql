-- ========================================================================
-- EXPERIMENT 2 - PART B : OLAP OPERATIONS ON THE STAR SCHEMA  [Customer_Purchase_History_Dataset]
-- OLAP = few, heavy, read-only analytical queries on a denormalised star schema (fact + dimensions).
-- Measure: Purchase Amount (`purchase_amount`)   Dimensions: region, age_group, income_band
-- Requires MySQL 8.0+ (GROUPING(), CTEs, window functions). Run Experiment 1 star script first.
-- ========================================================================

USE `dmbi_customer_purchase_star`;
SET SESSION group_concat_max_len = 1000000;

-- ---- 1. BASE AGGREGATE : the fact table summarised through one dimension ------
SELECT d_region.`region` AS region, SUM(f.`purchase_amount`) AS `Purchase Amount`, SUM(f.`purchase_frequency`) AS `Purchase Frequency`, COUNT(*) AS fact_rows
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
GROUP BY d_region.`region`
ORDER BY 2 DESC;

-- ---- 2. ROLL-UP (dimension hierarchy): region > age_group > ALL --------------------------------
SELECT IF(GROUPING(d_region.`region`), 'ALL', d_region.`region`) AS region_,
       IF(GROUPING(d_demographic.`age_group`), 'ALL', d_demographic.`age_group`) AS age_group_,
       SUM(f.`purchase_amount`) AS `Purchase Amount`
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key`
GROUP BY d_region.`region`, d_demographic.`age_group` WITH ROLLUP;

-- ---- helper variables : the best member of each dimension (so no hard-coded values) ----
SET @top_a = (SELECT d_region.`region` FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key` GROUP BY d_region.`region` ORDER BY SUM(f.`purchase_amount`) DESC LIMIT 1);
SET @top_b = (SELECT d_demographic.`age_group` FROM `fact_customer_purchase` f
LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key` GROUP BY d_demographic.`age_group` ORDER BY SUM(f.`purchase_amount`) DESC LIMIT 1);
SELECT @top_a AS top_region, @top_b AS top_age_group;

-- ---- 4. DRILL-DOWN : go from summary to detail ---------------------------------------
-- Level 1 : by region
SELECT d_region.`region` AS region, SUM(f.`purchase_amount`) AS `Purchase Amount`
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
GROUP BY d_region.`region` ORDER BY 2 DESC;
-- Level 2 : drill into the top region, split by age_group
SELECT d_region.`region` AS region, d_demographic.`age_group` AS age_group, SUM(f.`purchase_amount`) AS `Purchase Amount`
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key`
WHERE d_region.`region` = @top_a
GROUP BY d_region.`region`, d_demographic.`age_group` ORDER BY 3 DESC;
-- Level 3 : drill further into the top age_group, split by income_band
SELECT d_region.`region` AS region, d_demographic.`age_group` AS age_group, d_demographic.`income_band` AS income_band, SUM(f.`purchase_amount`) AS `Purchase Amount`
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key`
WHERE d_region.`region` = @top_a AND d_demographic.`age_group` = @top_b
GROUP BY d_region.`region`, d_demographic.`age_group`, d_demographic.`income_band` ORDER BY 4 DESC LIMIT 20;

-- ---- 5. SLICE : fix ONE dimension to a single value (a "slice" of the cube) ---------
SELECT d_demographic.`age_group` AS age_group, SUM(f.`purchase_amount`) AS `Purchase Amount`
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key`
WHERE d_region.`region` = @top_a            -- region fixed to its best member
GROUP BY d_demographic.`age_group` ORDER BY 2 DESC;

-- ---- 6. DICE : restrict SEVERAL dimensions at once (a sub-cube) ------------------------
SELECT d_region.`region` AS region, d_demographic.`age_group` AS age_group, SUM(f.`purchase_amount`) AS `Purchase Amount`
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key`
WHERE d_region.`region` IN (SELECT member FROM (SELECT d_region.`region` AS member FROM `fact_customer_purchase` f LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key` GROUP BY d_region.`region` ORDER BY SUM(f.`purchase_amount`) DESC LIMIT 2) t_region)
  AND d_demographic.`age_group` IN (SELECT member FROM (SELECT d_demographic.`age_group` AS member FROM `fact_customer_purchase` f LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key` GROUP BY d_demographic.`age_group` ORDER BY SUM(f.`purchase_amount`) DESC LIMIT 3) t_age_group)
GROUP BY d_region.`region`, d_demographic.`age_group` ORDER BY 3 DESC;

-- ---- 7. PIVOT : rotate age_group into columns (MySQL has no PIVOT keyword -> dynamic SQL) ------
SET @pivot_cols = (SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN d_demographic.`age_group` = ', QUOTE(member), ' THEN f.`purchase_amount` ELSE 0 END) AS `', member, '`') ORDER BY member SEPARATOR ', ') FROM (SELECT DISTINCT `age_group` AS member FROM `dim_demographic` WHERE `age_group` IS NOT NULL) x);
SET @pivot_sql = CONCAT('SELECT d_region.`region` AS `region`, ', @pivot_cols, ', SUM(f.`purchase_amount`) AS `Total` FROM `fact_customer_purchase` f LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key` LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key` GROUP BY d_region.`region` ORDER BY `Total` DESC');
PREPARE pivot_stmt FROM @pivot_sql;
EXECUTE pivot_stmt;
DEALLOCATE PREPARE pivot_stmt;

-- ---- 8. CUBE : every combination of (region, age_group) incl. sub-totals and grand total ----------
-- (MySQL has no CUBE keyword: UNION ALL of the four grouping sets)
SELECT CAST(d_region.`region` AS CHAR) AS region_, CAST(d_demographic.`age_group` AS CHAR) AS age_group_, SUM(f.`purchase_amount`) AS `Purchase Amount`
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key`
GROUP BY d_region.`region`, d_demographic.`age_group`
UNION ALL
SELECT CAST(d_region.`region` AS CHAR), 'ALL', SUM(f.`purchase_amount`)
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
GROUP BY d_region.`region`
UNION ALL
SELECT 'ALL', CAST(d_demographic.`age_group` AS CHAR), SUM(f.`purchase_amount`)
FROM `fact_customer_purchase` f
LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key`
GROUP BY d_demographic.`age_group`
UNION ALL
SELECT 'ALL', 'ALL', SUM(f.`purchase_amount`)
FROM `fact_customer_purchase` f;

-- ---- 9. WINDOW FUNCTIONS : rank, share of total, Pareto (cumulative %) --------------------
WITH by_member AS (
  SELECT d_region.`region` AS member, SUM(f.`purchase_amount`) AS total
  FROM `fact_customer_purchase` f
  LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
  GROUP BY d_region.`region`
)
SELECT member, total,
       RANK() OVER (ORDER BY total DESC) AS rank_,
       ROUND(100 * total / SUM(total) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 2) AS cumulative_pct
FROM by_member ORDER BY rank_;

-- ---- 11. AGGREGATE (SUMMARY) TABLE : pre-computed cube level for fast dashboards ------
DROP TABLE IF EXISTS `agg_customer_purchase_by_region_age_group`;
CREATE TABLE `agg_customer_purchase_by_region_age_group` AS
SELECT d_region.`region` AS region_, d_demographic.`age_group` AS age_group_, SUM(f.`purchase_amount`) AS total_purchase_amount, SUM(f.`purchase_frequency`) AS total_purchase_frequency, COUNT(*) AS fact_rows
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key`
GROUP BY d_region.`region`, d_demographic.`age_group`;
SELECT * FROM `agg_customer_purchase_by_region_age_group` ORDER BY total_purchase_amount DESC LIMIT 10;   -- no joins needed any more
