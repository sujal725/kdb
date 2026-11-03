-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Financials]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_financials_stg`.`stg_financials`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_financials_star`.`fact_sales`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_financials_snow`.`fact_sales`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`sales`) AS total_sales FROM `dmbi_financials_star`.`fact_sales`
UNION ALL SELECT 'snowflake', SUM(`sales`) FROM `dmbi_financials_snow`.`fact_sales`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_financials_star`;
SELECT d_segment.`segment` AS segment, SUM(f.`sales`) AS total
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
GROUP BY d_segment.`segment`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_financials_snow`;
SELECT s1.`region_name` AS region_name, SUM(f.`sales`) AS total
FROM `fact_sales` f
JOIN `dim_country` p ON f.`country_key` = p.`country_key`
JOIN `dim_region` s1 ON p.`region_key` = s1.`region_key`
GROUP BY s1.`region_name`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_financials_star', 'dmbi_financials_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_financials_star', 'dmbi_financials_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
