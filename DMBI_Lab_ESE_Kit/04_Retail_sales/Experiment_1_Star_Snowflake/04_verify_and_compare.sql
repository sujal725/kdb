-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Retail_sales]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_retail_sales_stg`.`stg_retail_sales`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_retail_sales_star`.`fact_sales`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_retail_sales_snow`.`fact_sales`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`total_amount`) AS total_total_amount FROM `dmbi_retail_sales_star`.`fact_sales`
UNION ALL SELECT 'snowflake', SUM(`total_amount`) FROM `dmbi_retail_sales_snow`.`fact_sales`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_retail_sales_star`;
SELECT d_product_category.`product_category` AS product_category, SUM(f.`total_amount`) AS total
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
GROUP BY d_product_category.`product_category`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_retail_sales_snow`;
SELECT s1.`gender` AS gender, SUM(f.`total_amount`) AS total
FROM `fact_sales` f
JOIN `dim_customer` p ON f.`customer_key` = p.`customer_key`
JOIN `dim_gender` s1 ON p.`gender_key` = s1.`gender_key`
GROUP BY s1.`gender`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_retail_sales_star', 'dmbi_retail_sales_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_retail_sales_star', 'dmbi_retail_sales_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
