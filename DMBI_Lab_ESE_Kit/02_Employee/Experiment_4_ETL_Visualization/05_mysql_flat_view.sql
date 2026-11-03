-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Employee]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_employee_star`;
CREATE OR REPLACE VIEW `vw_employee_flat` AS
SELECT
  d_education.`education` AS `education`,
  d_city.`city` AS `city`,
  d_joining_year.`joining_year` AS `joining_year`,
  d_payment_tier.`payment_tier` AS `payment_tier`,
  d_employee_profile.`gender` AS `gender`,
  d_employee_profile.`ever_benched` AS `ever_benched`,
  d_employee_profile.`age_band` AS `age_band`,
  f.`age` AS `age`,
  f.`experience_in_current_domain` AS `experience_in_current_domain`,
  f.`leave_or_not` AS `leave_or_not`
FROM `fact_employee` f
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key`
LEFT JOIN `dim_city` d_city ON f.`city_key` = d_city.`city_key`
LEFT JOIN `dim_joining_year` d_joining_year ON f.`joining_year_key` = d_joining_year.`joining_year_key`
LEFT JOIN `dim_payment_tier` d_payment_tier ON f.`payment_tier_key` = d_payment_tier.`payment_tier_key`
LEFT JOIN `dim_employee_profile` d_employee_profile ON f.`employee_profile_key` = d_employee_profile.`employee_profile_key`;

SELECT * FROM `vw_employee_flat` LIMIT 10;
