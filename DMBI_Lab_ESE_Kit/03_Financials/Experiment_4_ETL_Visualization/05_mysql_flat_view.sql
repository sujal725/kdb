-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Financials]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_financials_star`;
CREATE OR REPLACE VIEW `vw_financials_flat` AS
SELECT
  d_segment.`segment` AS `segment`,
  d_country.`country` AS `country`,
  d_product.`product` AS `product`,
  d_discount_band.`discount_band` AS `discount_band`,
  d_date.`full_date` AS `full_date`,
  d_date.`year_num` AS `year_num`,
  d_date.`quarter_num` AS `quarter_num`,
  d_date.`month_num` AS `month_num`,
  d_date.`month_name` AS `month_name`,
  d_date.`day_name` AS `day_name`,
  f.`units_sold` AS `units_sold`,
  f.`manufacturing_price` AS `manufacturing_price`,
  f.`sale_price` AS `sale_price`,
  f.`gross_sales` AS `gross_sales`,
  f.`discounts` AS `discounts`,
  f.`sales` AS `sales`,
  f.`cogs` AS `cogs`,
  f.`profit` AS `profit`
FROM `fact_sales` f
LEFT JOIN `dim_segment` d_segment ON f.`segment_key` = d_segment.`segment_key`
LEFT JOIN `dim_country` d_country ON f.`country_key` = d_country.`country_key`
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_discount_band` d_discount_band ON f.`discount_band_key` = d_discount_band.`discount_band_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`;

SELECT * FROM `vw_financials_flat` LIMIT 10;
