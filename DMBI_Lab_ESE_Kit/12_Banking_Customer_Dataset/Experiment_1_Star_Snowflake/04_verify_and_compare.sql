-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Banking_Customer_Dataset]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_banking_customer_stg`.`stg_banking_customer`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_banking_customer_star`.`fact_bank_customer`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_banking_customer_snow`.`fact_bank_customer`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`balance`) AS total_balance FROM `dmbi_banking_customer_star`.`fact_bank_customer`
UNION ALL SELECT 'snowflake', SUM(`balance`) FROM `dmbi_banking_customer_snow`.`fact_bank_customer`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_banking_customer_star`;
SELECT d_geography.`geography` AS geography, SUM(f.`balance`) AS total
FROM `fact_bank_customer` f
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
GROUP BY d_geography.`geography`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_banking_customer_snow`;
SELECT s1.`gender` AS gender, SUM(f.`balance`) AS total
FROM `fact_bank_customer` f
JOIN `dim_customer` p ON f.`customer_key` = p.`customer_key`
JOIN `dim_gender` s1 ON p.`gender_key` = s1.`gender_key`
GROUP BY s1.`gender`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_banking_customer_star', 'dmbi_banking_customer_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_banking_customer_star', 'dmbi_banking_customer_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
