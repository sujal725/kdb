-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Inventory_and_Stock_Dataset]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_inventory_stock_stg`.`stg_inventory_stock`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_inventory_stock_star`.`fact_inventory`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_inventory_stock_snow`.`fact_inventory`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`revenue`) AS total_revenue FROM `dmbi_inventory_stock_star`.`fact_inventory`
UNION ALL SELECT 'snowflake', SUM(`revenue`) FROM `dmbi_inventory_stock_snow`.`fact_inventory`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_inventory_stock_star`;
SELECT d_product.`category` AS category, SUM(f.`revenue`) AS total
FROM `fact_inventory` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
GROUP BY d_product.`category`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_inventory_stock_snow`;
SELECT s1.`region` AS region, SUM(f.`revenue`) AS total
FROM `fact_inventory` f
JOIN `dim_store` p ON f.`store_key` = p.`store_key`
JOIN `dim_region` s1 ON p.`region_key` = s1.`region_key`
GROUP BY s1.`region`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_inventory_stock_star', 'dmbi_inventory_stock_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_inventory_stock_star', 'dmbi_inventory_stock_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
