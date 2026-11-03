# Experiment 1 - Star and Snowflake Schema : Inventory_and_Stock_Dataset

**Aim:** design and implement a star schema and a snowflake schema for efficient storage and retrieval of the Inventory_and_Stock_Dataset data for BI.

## Files (run in this order)

| # | File | What it does |
|---|------|--------------|
| 1 | `01_staging_load.sql` | creates schema `dmbi_inventory_stock_stg`, staging table, loads the CSV (**edit the path**) |
| 2 | `02_star_schema.sql` | creates schema `dmbi_inventory_stock_star`: DDL + ETL for the star schema |
| 3 | `03_snowflake_schema.sql` | creates schema `dmbi_inventory_stock_snow`: DDL + ETL for the snowflake schema |
| 4 | `04_verify_and_compare.sql` | row-count / total checks and star-vs-snowflake sample queries |
| - | `star_schema.drawio`, `snowflake_schema.drawio` | open in draw.io (File > Open) for the diagram screenshots |
| - | `schema_diagrams.md` | the same diagrams as Mermaid ER code (renders on GitHub/VS Code) |

## How to run

**Command line (Windows cmd or Linux terminal):**
```
mysql -u root -p --local-infile=1
mysql> SOURCE 01_staging_load.sql;
mysql> SOURCE 02_star_schema.sql;
mysql> SOURCE 03_snowflake_schema.sql;
mysql> SOURCE 04_verify_and_compare.sql;
```
(start `mysql` from inside this folder, or give the full path with forward slashes).

**MySQL Workbench:** File > Open SQL Script > pick the file > click the lightning icon. Repeat for each file in order.

## Design decisions (say these in the viva)

* **Grain of the fact table:** One row per date x store x product.
* **Fact table `fact_inventory`** holds the numeric measures: `inventory_level`, `units_sold`, `units_ordered`, `demand_forecast`, `price`, `discount`, `holiday_promotion`, `competitor_pricing`.
* **Derived measures:** `revenue`, `stock_gap`, `forecast_error` (calculated during the ETL).
* **Date dimension** `dim_date` (day, month, quarter, year, weekday, weekend flag); the fact stores `date_key` = yyyymmdd.
* **Surrogate keys:** every dimension has an AUTO_INCREMENT `*_key`; the fact references them with foreign keys.
* **NULL-safe joins (`<=>`)** keep rows that have blank attributes.

## Star schema tables

| Table | Type | Columns |
|-------|------|---------|
| `fact_inventory` | FACT | `date_key`, `store_key`, `product_key`, `weather_key`, `season_key`, `inventory_level`, `units_sold`, `units_ordered`, `demand_forecast`, `price`, `discount`, `holiday_promotion`, `competitor_pricing`, `revenue`, `stock_gap`, `forecast_error` |
| `dim_date` | DIM | `full_date`, `day_of_month`, `day_name`, `is_weekend`, `month_num`, `month_name`, `quarter_num`, `year_num` |
| `dim_store` | DIM | `store_id`, `region` |
| `dim_product` | DIM | `product_id`, `category` |
| `dim_weather` | DIM | `weather_condition` |
| `dim_season` | DIM | `seasonality` |

## Snowflake schema - what changes

Same fact table, but dimension attributes are moved into **sub-dimension** tables (3NF) and the parent keeps a foreign key:

| Parent dimension | Sub-dimension(s) |
|---|---|
| `dim_store` | `dim_region` (region) |
| `dim_product` | `dim_category` (category) |
| `dim_date` | `dim_month` > `dim_quarter` > `dim_year` (calendar hierarchy) |

| | Star | Snowflake |
|---|---|---|
| Dimensions | denormalised (one table each) | normalised into sub-dimensions |
| Joins per query | fewer, faster | more joins, slower |
| Storage | some redundancy | less redundancy |
| Maintenance | simpler | updates of a value happen in one place |
| Tables | 6 | 11 |

## Screenshots to take for the lab file
1. ER diagram (draw.io) of the star schema
2. ER diagram of the snowflake schema
3. Output of `SHOW TABLES` in each schema
4. Row counts (step 4 query 1) and one analysis query from each schema
