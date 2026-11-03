-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Customer_Purchase_History_Dataset]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_customer_purchase_stg`.`stg_customer_purchase`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_customer_purchase_star`.`fact_customer_purchase`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_customer_purchase_snow`.`fact_customer_purchase`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`purchase_amount`) AS total_purchase_amount FROM `dmbi_customer_purchase_star`.`fact_customer_purchase`
UNION ALL SELECT 'snowflake', SUM(`purchase_amount`) FROM `dmbi_customer_purchase_snow`.`fact_customer_purchase`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_customer_purchase_star`;
SELECT d_region.`region` AS region, SUM(f.`purchase_amount`) AS total
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
GROUP BY d_region.`region`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_customer_purchase_snow`;
SELECT s1.`age_group` AS age_group, SUM(f.`purchase_amount`) AS total
FROM `fact_customer_purchase` f
JOIN `dim_demographic` p ON f.`demographic_key` = p.`demographic_key`
JOIN `dim_age_group` s1 ON p.`age_group_key` = s1.`age_group_key`
GROUP BY s1.`age_group`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_customer_purchase_star', 'dmbi_customer_purchase_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_customer_purchase_star', 'dmbi_customer_purchase_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
