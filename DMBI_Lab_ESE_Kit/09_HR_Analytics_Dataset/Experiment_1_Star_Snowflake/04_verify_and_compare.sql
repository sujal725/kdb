-- ========================================================================
-- EXPERIMENT 1 - STEP 4 : VERIFY + SAMPLE QUERIES  [HR_Analytics_Dataset]
-- Proves that staging, star and snowflake hold the same data.
-- Then shows how queries differ (joins).
-- ========================================================================

-- 1. ROW COUNTS must match: staging = star fact = snowflake fact
SELECT 'staging' AS layer, COUNT(*) AS rows_ FROM `dmbi_hr_analytics_stg`.`stg_hr_analytics`
UNION ALL SELECT 'star fact', COUNT(*) FROM `dmbi_hr_analytics_star`.`fact_employee_hr`
UNION ALL SELECT 'snowflake fact', COUNT(*) FROM `dmbi_hr_analytics_snow`.`fact_employee_hr`;

-- 2. TOTAL OF THE MAIN MEASURE must match in both schemas
SELECT 'star' AS schema_, SUM(`monthly_income`) AS total_monthly_income FROM `dmbi_hr_analytics_star`.`fact_employee_hr`
UNION ALL SELECT 'snowflake', SUM(`monthly_income`) FROM `dmbi_hr_analytics_snow`.`fact_employee_hr`;

-- 3. STAR query : fact + ONE join to the dimension
USE `dmbi_hr_analytics_star`;
SELECT d_job.`department` AS department, SUM(f.`monthly_income`) AS total
FROM `fact_employee_hr` f
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
GROUP BY d_job.`department`
ORDER BY total DESC
LIMIT 10;

-- 4. SNOWFLAKE query : the same idea needs an EXTRA join through the sub-dimension
USE `dmbi_hr_analytics_snow`;
SELECT s1.`age_group` AS age_group, SUM(f.`monthly_income`) AS total
FROM `fact_employee_hr` f
JOIN `dim_employee_demo` p ON f.`employee_demo_key` = p.`employee_demo_key`
JOIN `dim_age_group` s1 ON p.`age_group_key` = s1.`age_group_key`
GROUP BY s1.`age_group`
ORDER BY total DESC
LIMIT 10;

-- 5. LIST OF TABLES AND FOREIGN KEYS (useful for the screenshot of the schema)
SELECT table_schema, table_name, table_rows FROM information_schema.tables
WHERE table_schema IN ('dmbi_hr_analytics_star', 'dmbi_hr_analytics_snow') ORDER BY table_schema, table_name;

SELECT table_schema, table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema IN ('dmbi_hr_analytics_star', 'dmbi_hr_analytics_snow') AND referenced_table_name IS NOT NULL
ORDER BY table_schema, table_name;
