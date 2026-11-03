-- ========================================================================
-- EXPERIMENT 4 - OPTIONAL : FLAT VIEW OVER THE STAR SCHEMA FOR POWER BI / TABLEAU  [Inventory_and_Stock_Dataset]
-- Power BI: Get data > MySQL database > pick this view.  (needs MySQL Connector/NET)
-- Run Experiment 1 star script first. Tableau Public cannot connect to MySQL - use the CSV there.
-- ========================================================================
USE `dmbi_inventory_stock_star`;
CREATE OR REPLACE VIEW `vw_inventory_stock_flat` AS
SELECT
  d_store.`store_id` AS `store_id`,
  d_store.`region` AS `region`,
  d_product.`product_id` AS `product_id`,
  d_product.`category` AS `category`,
  d_weather.`weather_condition` AS `weather_condition`,
  d_season.`seasonality` AS `seasonality`,
  d_date.`full_date` AS `full_date`,
  d_date.`year_num` AS `year_num`,
  d_date.`quarter_num` AS `quarter_num`,
  d_date.`month_num` AS `month_num`,
  d_date.`month_name` AS `month_name`,
  d_date.`day_name` AS `day_name`,
  f.`inventory_level` AS `inventory_level`,
  f.`units_sold` AS `units_sold`,
  f.`units_ordered` AS `units_ordered`,
  f.`demand_forecast` AS `demand_forecast`,
  f.`price` AS `price`,
  f.`discount` AS `discount`,
  f.`holiday_promotion` AS `holiday_promotion`,
  f.`competitor_pricing` AS `competitor_pricing`,
  f.`revenue` AS `revenue`,
  f.`stock_gap` AS `stock_gap`,
  f.`forecast_error` AS `forecast_error`
FROM `fact_inventory` f
LEFT JOIN `dim_store` d_store ON f.`store_key` = d_store.`store_key`
LEFT JOIN `dim_product` d_product ON f.`product_key` = d_product.`product_key`
LEFT JOIN `dim_weather` d_weather ON f.`weather_key` = d_weather.`weather_key`
LEFT JOIN `dim_season` d_season ON f.`season_key` = d_season.`season_key`
LEFT JOIN `dim_date` d_date ON f.`date_key` = d_date.`date_key`;

SELECT * FROM `vw_inventory_stock_flat` LIMIT 10;
