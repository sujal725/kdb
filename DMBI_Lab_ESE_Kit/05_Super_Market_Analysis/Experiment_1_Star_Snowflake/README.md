# Experiment 1 - Star and Snowflake Schema : Super_Market_Analysis

**Aim:** design and implement a star schema and a snowflake schema for efficient storage and retrieval of the Super_Market_Analysis data for BI.

## Files (run in this order)

| # | File | What it does |
|---|------|--------------|
| 1 | `01_staging_load.sql` | creates schema `dmbi_super_market_stg`, staging table, loads the CSV (**edit the path**) |
| 2 | `02_star_schema.sql` | creates schema `dmbi_super_market_star`: DDL + ETL for the star schema |
| 3 | `03_snowflake_schema.sql` | creates schema `dmbi_super_market_snow`: DDL + ETL for the snowflake schema |
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

* **Grain of the fact table:** One row per invoice (one product line per invoice).
* **Fact table `fact_sales`** holds the numeric measures: `unit_price`, `quantity`, `tax_5`, `total`, `cogs`, `gross_margin_percentage`, `gross_income`, `rating`.
* **Degenerate dimension(s)** (identifier kept inside the fact, no table): `invoice_id`
* **Date dimension** `dim_date` (day, month, quarter, year, weekday, weekend flag); the fact stores `date_key` = yyyymmdd.
* **Surrogate keys:** every dimension has an AUTO_INCREMENT `*_key`; the fact references them with foreign keys.
* **NULL-safe joins (`<=>`)** keep rows that have blank attributes.

## Star schema tables

| Table | Type | Columns |
|-------|------|---------|
| `fact_sales` | FACT | `date_key`, `branch_key`, `customer_key`, `product_line_key`, `payment_key`, `invoice_id`, `sale_time`, `unit_price`, `quantity`, `tax_5`, `total`, `cogs`, `gross_margin_percentage`, `gross_income`, `rating` |
| `dim_date` | DIM | `full_date`, `day_of_month`, `day_name`, `is_weekend`, `month_num`, `month_name`, `quarter_num`, `year_num` |
| `dim_branch` | DIM | `branch`, `city` |
| `dim_customer` | DIM | `customer_type`, `gender` |
| `dim_product_line` | DIM | `product_line` |
| `dim_payment` | DIM | `payment` |

## Snowflake schema - what changes

Same fact table, but dimension attributes are moved into **sub-dimension** tables (3NF) and the parent keeps a foreign key:

| Parent dimension | Sub-dimension(s) |
|---|---|
| `dim_branch` | `dim_city` (city) |
| `dim_customer` | `dim_gender` (gender) |
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
