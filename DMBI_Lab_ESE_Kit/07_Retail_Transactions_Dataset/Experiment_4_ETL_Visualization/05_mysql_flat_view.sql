-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Retail_Transactions_Dataset]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_retail_transactions_star`;
CREATE OR REPLACE VIEW `vw_retail_transactions_flat` AS
SELECT
  d_customer.`customer_name` AS `customer_name`,
  d_customer.`customer_category` AS `customer_category`,
  d_store.`city` AS `city`,
  d_store.`store_type` AS `store_type`,
  d_payment_method.`payment_method` AS `payment_method`,
  d_season.`season` AS `season`,
  d_promotion.`promotion` AS `promotion`,
  d_date.`full_date` AS `full_date`,
  d_date.`year_num` AS `year_num`,
  d_date.`quarter_num` AS `quarter_num`,
  d_date.`month_num` AS `month_num`,
  d_date.`month_name` AS `month_name`,
  d_date.`day_name` AS `day_name`,
  f.`transaction_id` AS `transaction_id`,
  f.`product` AS `product`,
  f.`total_items` AS `total_items`,
  f.`total_cost` AS `total_cost`,
  f.`discount_applied` AS `discount_applied`,
  f.`avg_item_cost` AS `avg_item_cost`
FROM `fact_transactions` f
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
LEFT JOIN `dim_payment_method` d_payment_method ON f.`payment_method_key` = d_payment_method.`payment_method_key`
LEFT JOIN `dim_season` d_season ON f.`season_key` = d_season.`season_key`
LEFT JOIN `dim_promotion` d_promotion ON f.`promotion_key` = d_promotion.`promotion_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`;

SELECT * FROM `vw_retail_transactions_flat` LIMIT 10;
