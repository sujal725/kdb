# Experiment 1 - Star and Snowflake Schema : Retail_Transactions_Dataset

**Aim:** design and implement a star schema and a snowflake schema for efficient storage and retrieval of the Retail_Transactions_Dataset data for BI.

## Files (run in this order)

| # | File | What it does |
|---|------|--------------|
| 1 | `01_staging_load.sql` | creates schema `dmbi_retail_transactions_stg`, staging table, loads the CSV (**edit the path**) |
| 2 | `02_star_schema.sql` | creates schema `dmbi_retail_transactions_star`: DDL + ETL for the star schema |
| 3 | `03_snowflake_schema.sql` | creates schema `dmbi_retail_transactions_snow`: DDL + ETL for the snowflake schema |
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

* **Grain of the fact table:** One row per basket / transaction.
* **Fact table `fact_transactions`** holds the numeric measures: `total_items`, `total_cost`, `discount_applied`.
* **Derived measures:** `avg_item_cost` (calculated during the ETL).
* **Degenerate dimension(s)** (identifier kept inside the fact, no table): `transaction_id`, `product`
* **Date dimension** `dim_date` (day, month, quarter, year, weekday, weekend flag); the fact stores `date_key` = yyyymmdd.
* **Surrogate keys:** every dimension has an AUTO_INCREMENT `*_key`; the fact references them with foreign keys.
* **NULL-safe joins (`<=>`)** keep rows that have blank attributes.

## Star schema tables

| Table | Type | Columns |
|-------|------|---------|
| `fact_transactions` | FACT | `date_key`, `customer_key`, `store_key`, `payment_method_key`, `season_key`, `promotion_key`, `transaction_id`, `product`, `total_items`, `total_cost`, `discount_applied`, `avg_item_cost` |
| `dim_date` | DIM | `full_date`, `day_of_month`, `day_name`, `is_weekend`, `month_num`, `month_name`, `quarter_num`, `year_num` |
| `dim_customer` | DIM | `customer_name`, `customer_category` |
| `dim_store` | DIM | `city`, `store_type` |
| `dim_payment_method` | DIM | `payment_method` |
| `dim_season` | DIM | `season` |
| `dim_promotion` | DIM | `promotion` |

## Snowflake schema - what changes

Same fact table, but dimension attributes are moved into **sub-dimension** tables (3NF) and the parent keeps a foreign key:

| Parent dimension | Sub-dimension(s) |
|---|---|
| `dim_customer` | `dim_customer_category` (customer_category) |
| `dim_store` | `dim_city` (city) |
| `dim_date` | `dim_month` > `dim_quarter` > `dim_year` (calendar hierarchy) |

| | Star | Snowflake |
|---|---|---|
| Dimensions | denormalised (one table each) | normalised into sub-dimensions |
| Joins per query | fewer, faster | more joins, slower |
| Storage | some redundancy | less redundancy |
| Maintenance | simpler | updates of a value happen in one place |
| Tables | 7 | 12 |

## Screenshots to take for the lab file
1. ER diagram (draw.io) of the star schema
2. ER diagram of the snowflake schema
3. Output of `SHOW TABLES` in each schema
4. Row counts (step 4 query 1) and one analysis query from each schema
