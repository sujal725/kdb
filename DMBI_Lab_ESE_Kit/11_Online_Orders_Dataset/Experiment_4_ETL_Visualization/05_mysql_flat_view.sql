-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Online_Orders_Dataset]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_online_orders_star`;
CREATE OR REPLACE VIEW `vw_online_orders_flat` AS
SELECT
  d_product.`product_name` AS `product_name`,
  d_product.`product_category` AS `product_category`,
  d_region.`region` AS `region`,
  d_payment_method.`payment_method` AS `payment_method`,
  d_date.`full_date` AS `full_date`,
  d_date.`year_num` AS `year_num`,
  d_date.`quarter_num` AS `quarter_num`,
  d_date.`month_num` AS `month_num`,
  d_date.`month_name` AS `month_name`,
  d_date.`day_name` AS `day_name`,
  f.`transaction_id` AS `transaction_id`,
  f.`units_sold` AS `units_sold`,
  f.`unit_price` AS `unit_price`,
  f.`total_revenue` AS `total_revenue`
FROM `fact_orders` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_region` d_region ON f.`region_key` = d_region.`region_key`
LEFT JOIN `dim_payment_method` d_payment_method ON f.`payment_method_key` = d_payment_method.`payment_method_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`;

SELECT * FROM `vw_online_orders_flat` LIMIT 10;
