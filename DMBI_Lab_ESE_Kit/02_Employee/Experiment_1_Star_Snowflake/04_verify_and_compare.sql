-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [Employee]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_employee_stg`.`stg_employee`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_employee_star`.`fact_employee`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_employee_snow`.`fact_employee`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`leave_or_not`) AS total_leave_or_not FROM `dmbi_employee_star`.`fact_employee`
UNION ALL SELECT 'snowflake', SUM(`leave_or_not`) FROM `dmbi_employee_snow`.`fact_employee`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_employee_star`;
SELECT d_city.`city` AS city, SUM(f.`leave_or_not`) AS total
FROM `fact_employee` f
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
GROUP BY d_city.`city`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_employee_snow`;
SELECT s1.`gender` AS gender, SUM(f.`leave_or_not`) AS total
FROM `fact_employee` f
JOIN `dim_employee_profile` p ON f.`employee_profile_key` = p.`employee_profile_key`
JOIN `dim_gender` s1 ON p.`gender_key` = s1.`gender_key`
GROUP BY s1.`gender`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_employee_star', 'dmbi_employee_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_employee_star', 'dmbi_employee_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
