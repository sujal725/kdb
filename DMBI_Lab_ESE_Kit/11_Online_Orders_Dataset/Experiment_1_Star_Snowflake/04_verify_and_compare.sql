-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Online_Orders_Dataset]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_online_orders_stg`.`stg_online_orders`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_online_orders_star`.`fact_orders`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_online_orders_snow`.`fact_orders`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`total_revenue`) AS total_total_revenue FROM `dmbi_online_orders_star`.`fact_orders`
UNION ALL SELECT 'snowflake', SUM(`total_revenue`) FROM `dmbi_online_orders_snow`.`fact_orders`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_online_orders_star`;
SELECT d_product.`product_category` AS product_category, SUM(f.`total_revenue`) AS total
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
GROUP BY d_product.`product_category`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_online_orders_snow`;
SELECT s1.`product_category` AS product_category, SUM(f.`total_revenue`) AS total
FROM `fact_orders` f
JOIN `dim_product` p ON f.`product_key` = p.`product_key`
JOIN `dim_product_category` s1 ON p.`product_category_key` = s1.`product_category_key`
GROUP BY s1.`product_category`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_online_orders_star', 'dmbi_online_orders_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_online_orders_star', 'dmbi_online_orders_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
