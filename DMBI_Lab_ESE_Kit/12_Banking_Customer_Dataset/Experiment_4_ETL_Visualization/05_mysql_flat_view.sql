-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Banking_Customer_Dataset]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_banking_customer_star`;
CREATE OR REPLACE VIEW `vw_banking_customer_flat` AS
SELECT
  d_customer.`customer_id` AS `customer_id`,
  d_customer.`surname` AS `surname`,
  d_customer.`gender` AS `gender`,
  d_customer.`age_group` AS `age_group`,
  d_geography.`geography` AS `geography`,
  d_credit_band.`credit_band` AS `credit_band`,
  f.`src_row_number` AS `src_row_number`,
  f.`credit_score` AS `credit_score`,
  f.`age` AS `age`,
  f.`tenure` AS `tenure`,
  f.`balance` AS `balance`,
  f.`num_of_products` AS `num_of_products`,
  f.`has_cr_card` AS `has_cr_card`,
  f.`is_active_member` AS `is_active_member`,
  f.`estimated_salary` AS `estimated_salary`,
  f.`exited` AS `exited`
FROM `fact_bank_customer` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_geography` d_geography ON f.`geography_key` = d_geography.`geography_key`
LEFT JOIN `dim_credit_band` d_credit_band ON f.`credit_band_key` = d_credit_band.`credit_band_key`;

SELECT * FROM `vw_banking_customer_flat` LIMIT 10;
