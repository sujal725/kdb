-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Super_Market_Analysis]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_super_market_stg`.`stg_super_market`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_super_market_star`.`fact_sales`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_super_market_snow`.`fact_sales`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`total`) AS total_total FROM `dmbi_super_market_star`.`fact_sales`
UNION ALL SELECT 'snowflake', SUM(`total`) FROM `dmbi_super_market_snow`.`fact_sales`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_super_market_star`;
SELECT d_product_line.`product_line` AS product_line, SUM(f.`total`) AS total
FROM `fact_sales` f
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
GROUP BY d_product_line.`product_line`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_super_market_snow`;
SELECT s1.`city` AS city, SUM(f.`total`) AS total
FROM `fact_sales` f
JOIN `dim_branch` p ON f.`branch_key` = p.`branch_key`
JOIN `dim_city` s1 ON p.`city_key` = s1.`city_key`
GROUP BY s1.`city`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_super_market_star', 'dmbi_super_market_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_super_market_star', 'dmbi_super_market_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
