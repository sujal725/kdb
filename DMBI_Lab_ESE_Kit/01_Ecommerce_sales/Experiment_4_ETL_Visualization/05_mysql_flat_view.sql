-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Ecommerce_sales]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_ecommerce_sales_star`;
CREATE OR REPLACE VIEW `vw_ecommerce_sales_flat` AS
SELECT
  d_product_category.`product_category` AS `product_category`,
  d_customer_segment.`customer_segment` AS `customer_segment`,
  d_discount_band.`discount_band` AS `discount_band`,
  d_date.`full_date` AS `full_date`,
  d_date.`year_num` AS `year_num`,
  d_date.`quarter_num` AS `quarter_num`,
  d_date.`month_num` AS `month_num`,
  d_date.`month_name` AS `month_name`,
  d_date.`day_name` AS `day_name`,
  f.`price` AS `price`,
  f.`discount` AS `discount`,
  f.`marketing_spend` AS `marketing_spend`,
  f.`units_sold` AS `units_sold`,
  f.`gross_revenue` AS `gross_revenue`,
  f.`net_revenue` AS `net_revenue`
FROM `fact_sales` f
LEFT JOIN `dim_product_category` d_product_category ON f.`product_category_key` = d_product_category.`product_category_key`
LEFT JOIN `dim_customer_segment` d_customer_segment ON f.`customer_segment_key` = d_customer_segment.`customer_segment_key`
LEFT JOIN `dim_discount_band` d_discount_band ON f.`discount_band_key` = d_discount_band.`discount_band_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`;

SELECT * FROM `vw_ecommerce_sales_flat` LIMIT 10;
