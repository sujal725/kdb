-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Sales_Transaction_Dataset]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_sales_transaction_stg`.`stg_sales_transaction`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_sales_transaction_star`.`fact_sales`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_sales_transaction_snow`.`fact_sales`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`sales_amount`) AS total_sales_amount FROM `dmbi_sales_transaction_star`.`fact_sales`
UNION ALL SELECT 'snowflake', SUM(`sales_amount`) FROM `dmbi_sales_transaction_snow`.`fact_sales`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_sales_transaction_star`;
SELECT d_customer.`country` AS country, SUM(f.`sales_amount`) AS total
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
GROUP BY d_customer.`country`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_sales_transaction_snow`;
SELECT s1.`country` AS country, SUM(f.`sales_amount`) AS total
FROM `fact_sales` f
JOIN `dim_customer` p ON f.`customer_key` = p.`customer_key`
JOIN `dim_country` s1 ON p.`country_key` = s1.`country_key`
GROUP BY s1.`country`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_sales_transaction_star', 'dmbi_sales_transaction_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_sales_transaction_star', 'dmbi_sales_transaction_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
