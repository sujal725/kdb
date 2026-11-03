-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Super_Market_Analysis]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_super_market_star`;
CREATE OR REPLACE VIEW `vw_super_market_flat` AS
SELECT
  d_branch.`branch` AS `branch`,
  d_branch.`city` AS `city`,
  d_customer.`customer_type` AS `customer_type`,
  d_customer.`gender` AS `gender`,
  d_product_line.`product_line` AS `product_line`,
  d_payment.`payment` AS `payment`,
  d_date.`full_date` AS `full_date`,
  d_date.`year_num` AS `year_num`,
  d_date.`quarter_num` AS `quarter_num`,
  d_date.`month_num` AS `month_num`,
  d_date.`month_name` AS `month_name`,
  d_date.`day_name` AS `day_name`,
  f.`invoice_id` AS `invoice_id`,
  f.`sale_time` AS `sale_time`,
  f.`unit_price` AS `unit_price`,
  f.`quantity` AS `quantity`,
  f.`tax_5` AS `tax_5`,
  f.`total` AS `total`,
  f.`cogs` AS `cogs`,
  f.`gross_margin_percentage` AS `gross_margin_percentage`,
  f.`gross_income` AS `gross_income`,
  f.`rating` AS `rating`
FROM `fact_sales` f
LEFT JOIN `dim_branch` d_branch ON f.`branch_key` = d_branch.`branch_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_product_line` d_product_line ON f.`product_line_key` = d_product_line.`product_line_key`
LEFT JOIN `dim_payment` d_payment ON f.`payment_key` = d_payment.`payment_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`;

SELECT * FROM `vw_super_market_flat` LIMIT 10;
