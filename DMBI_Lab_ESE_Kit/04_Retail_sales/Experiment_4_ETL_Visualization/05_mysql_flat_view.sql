-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Retail_sales]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_retail_sales_star`;
CREATE OR REPLACE VIEW `vw_retail_sales_flat` AS
SELECT
  d_customer.`customer_id` AS `customer_id`,
  d_customer.`gender` AS `gender`,
  d_customer.`age` AS `age`,
  d_customer.`age_group` AS `age_group`,
  d_product_category.`product_category` AS `product_category`,
  d_date.`full_date` AS `full_date`,
  d_date.`year_num` AS `year_num`,
  d_date.`quarter_num` AS `quarter_num`,
  d_date.`month_num` AS `month_num`,
  d_date.`month_name` AS `month_name`,
  d_date.`day_name` AS `day_name`,
  f.`transaction_id` AS `transaction_id`,
  f.`quantity` AS `quantity`,
  f.`price_per_unit` AS `price_per_unit`,
  f.`total_amount` AS `total_amount`
FROM `fact_sales` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`;

SELECT * FROM `vw_retail_sales_flat` LIMIT 10;
