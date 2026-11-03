-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Retail_Transactions_Dataset]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_retail_transactions_stg`.`stg_retail_transactions`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_retail_transactions_star`.`fact_transactions`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_retail_transactions_snow`.`fact_transactions`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`total_cost`) AS total_total_cost FROM `dmbi_retail_transactions_star`.`fact_transactions`
UNION ALL SELECT 'snowflake', SUM(`total_cost`) FROM `dmbi_retail_transactions_snow`.`fact_transactions`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_retail_transactions_star`;
SELECT d_store.`city` AS city, SUM(f.`total_cost`) AS total
FROM `fact_transactions` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
GROUP BY d_store.`city`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_retail_transactions_snow`;
SELECT s1.`customer_category` AS customer_category, SUM(f.`total_cost`) AS total
FROM `fact_transactions` f
JOIN `dim_customer` p ON f.`customer_key` = p.`customer_key`
JOIN `dim_customer_category` s1 ON p.`customer_category_key` = s1.`customer_category_key`
GROUP BY s1.`customer_category`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_retail_transactions_star', 'dmbi_retail_transactions_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_retail_transactions_star', 'dmbi_retail_transactions_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
