-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Customer_Purchase_History_Dataset]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_customer_purchase_star`;
CREATE OR REPLACE VIEW `vw_customer_purchase_flat` AS
SELECT
  d_region.`region` AS `region`,
  d_demographic.`age_group` AS `age_group`,
  d_demographic.`income_band` AS `income_band`,
  f.`user_id` AS `user_id`,
  f.`age` AS `age`,
  f.`annual_income` AS `annual_income`,
  f.`purchase_amount` AS `purchase_amount`,
  f.`loyalty_score` AS `loyalty_score`,
  f.`purchase_frequency` AS `purchase_frequency`
FROM `fact_customer_purchase` f
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
LEFT JOIN `dim_demographic` d_demographic ON f.`demographic_key` = d_demographic.`demographic_key`;

SELECT * FROM `vw_customer_purchase_flat` LIMIT 10;
