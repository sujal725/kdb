-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Sales_Transaction_Dataset]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_sales_transaction_star`;
CREATE OR REPLACE VIEW `vw_sales_transaction_flat` AS
SELECT
  d_product.`product_no` AS `product_no`,
  d_product.`product_name` AS `product_name`,
  d_customer.`customer_no` AS `customer_no`,
  d_customer.`country` AS `country`,
  d_date.`full_date` AS `full_date`,
  d_date.`year_num` AS `year_num`,
  d_date.`quarter_num` AS `quarter_num`,
  d_date.`month_num` AS `month_num`,
  d_date.`month_name` AS `month_name`,
  d_date.`day_name` AS `day_name`,
  f.`transaction_no` AS `transaction_no`,
  f.`price` AS `price`,
  f.`quantity` AS `quantity`,
  f.`sales_amount` AS `sales_amount`,
  f.`is_cancellation` AS `is_cancellation`
FROM `fact_sales` f
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_customer` d_customer ON f.`customer_key` = d_customer.`customer_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`;

SELECT * FROM `vw_sales_transaction_flat` LIMIT 10;
