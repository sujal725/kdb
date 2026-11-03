-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Ecommerce_sales]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_ecommerce_sales_stg`.`stg_ecommerce_sales`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_ecommerce_sales_star`.`fact_sales`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_ecommerce_sales_snow`.`fact_sales`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`net_revenue`) AS total_net_revenue FROM `dmbi_ecommerce_sales_star`.`fact_sales`
UNION ALL SELECT 'snowflake', SUM(`net_revenue`) FROM `dmbi_ecommerce_sales_snow`.`fact_sales`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_ecommerce_sales_star`;
SELECT d_product_category.`product_category` AS product_category, SUM(f.`net_revenue`) AS total
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
GROUP BY d_product_category.`product_category`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : time hierarchy needs 3 extra joins (date > month > quarter > year)
USE `dmbi_ecommerce_sales_snow`;
SELECT y.year_num, q.quarter_num, SUM(f.`net_revenue`) AS total
FROM `fact_sales` f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_month mo ON d.month_key = mo.month_key
JOIN dim_quarter q ON mo.quarter_key = q.quarter_key
JOIN dim_year y ON q.year_key = y.year_key
GROUP BY y.year_num, q.quarter_num
ORDER BY y.year_num, q.quarter_num;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_ecommerce_sales_star', 'dmbi_ecommerce_sales_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_ecommerce_sales_star', 'dmbi_ecommerce_sales_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
