-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [HR_Analytics_Dataset]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_hr_analytics_star`;
CREATE OR REPLACE VIEW `vw_hr_analytics_flat` AS
SELECT
  d_employee_demo.`gender` AS `gender`,
  d_employee_demo.`marital_status` AS `marital_status`,
  d_employee_demo.`age_group` AS `age_group`,
  d_education.`education` AS `education`,
  d_education.`education_field` AS `education_field`,
  d_job.`department` AS `department`,
  d_job.`job_role` AS `job_role`,
  d_job.`job_level` AS `job_level`,
  d_work_profile.`business_travel` AS `business_travel`,
  d_work_profile.`over_time` AS `over_time`,
  d_salary_slab.`salary_slab` AS `salary_slab`,
  f.`emp_id` AS `emp_id`,
  f.`age` AS `age`,
  f.`attrition_flag` AS `attrition_flag`,
  f.`daily_rate` AS `daily_rate`,
  f.`hourly_rate` AS `hourly_rate`,
  f.`monthly_rate` AS `monthly_rate`,
  f.`monthly_income` AS `monthly_income`,
  f.`distance_from_home` AS `distance_from_home`,
  f.`num_companies_worked` AS `num_companies_worked`,
  f.`percent_salary_hike` AS `percent_salary_hike`,
  f.`performance_rating` AS `performance_rating`,
  f.`environment_satisfaction` AS `environment_satisfaction`,
  f.`job_involvement` AS `job_involvement`,
  f.`job_satisfaction` AS `job_satisfaction`,
  f.`relationship_satisfaction` AS `relationship_satisfaction`,
  f.`work_life_balance` AS `work_life_balance`,
  f.`stock_option_level` AS `stock_option_level`,
  f.`total_working_years` AS `total_working_years`,
  f.`training_times_last_year` AS `training_times_last_year`,
  f.`years_at_company` AS `years_at_company`,
  f.`years_in_current_role` AS `years_in_current_role`,
  f.`years_since_last_promotion` AS `years_since_last_promotion`,
  f.`years_with_curr_manager` AS `years_with_curr_manager`
FROM `fact_employee_hr` f
LEFT JOIN `dim_employee_demo` d_employee_demo ON f.`employee_demo_key` = d_employee_demo.`employee_demo_key`
LEFT JOIN `dim_education` d_education ON f.`education_key` = d_education.`education_key`
LEFT JOIN `dim_job` d_job ON f.`job_key` = d_job.`job_key`
LEFT JOIN `dim_work_profile` d_work_profile ON f.`work_profile_key` = d_work_profile.`work_profile_key`
LEFT JOIN `dim_salary_slab` d_salary_slab ON f.`salary_slab_key` = d_salary_slab.`salary_slab_key`;

SELECT * FROM `vw_hr_analytics_flat` LIMIT 10;
