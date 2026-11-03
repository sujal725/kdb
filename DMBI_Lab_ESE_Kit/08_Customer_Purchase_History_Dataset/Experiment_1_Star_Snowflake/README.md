# Experiment 1 - Star and Snowflake Schema : Customer_Purchase_History_Dataset

**Aim:** design and implement a star schema and a snowflake schema for efficient storage and retrieval of the Customer_Purchase_History_Dataset data for BI.

## Files (run in this order)

| # | File | What it does |
|---|------|--------------|
| 1 | `01_staging_load.sql` | creates schema `dmbi_customer_purchase_stg`, staging table, loads the CSV (**edit the path**) |
| 2 | `02_star_schema.sql` | creates schema `dmbi_customer_purchase_star`: DDL + ETL for the star schema |
| 3 | `03_snowflake_schema.sql` | creates schema `dmbi_customer_purchase_snow`: DDL + ETL for the snowflake schema |
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

* **Grain of the fact table:** One row per customer.
* **Fact table `fact_customer_purchase`** holds the numeric measures: `age`, `annual_income`, `purchase_amount`, `loyalty_score`, `purchase_frequency`.
* **Degenerate dimension(s)** (identifier kept inside the fact, no table): `user_id`
* There is no date column in this dataset, so there is no date dimension.
* **Surrogate keys:** every dimension has an AUTO_INCREMENT `*_key`; the fact references them with foreign keys.
* **NULL-safe joins (`<=>`)** keep rows that have blank attributes.

## Star schema tables

| Table | Type | Columns |
|-------|------|---------|
| `fact_customer_purchase` | FACT | `region_key`, `demographic_key`, `user_id`, `age`, `annual_income`, `purchase_amount`, `loyalty_score`, `purchase_frequency` |
| `dim_region` | DIM | `region` |
| `dim_demographic` | DIM | `age_group`, `income_band` |

## Snowflake schema - what changes

Same fact table, but dimension attributes are moved into **sub-dimension** tables (3NF) and the parent keeps a foreign key:

| Parent dimension | Sub-dimension(s) |
|---|---|
| `dim_demographic` | `dim_age_group` (age_group), `dim_income_band` (income_band) |

| | Star | Snowflake |
|---|---|---|
| Dimensions | denormalised (one table each) | normalised into sub-dimensions |
| Joins per query | fewer, faster | more joins, slower |
| Storage | some redundancy | less redundancy |
| Maintenance | simpler | updates of a value happen in one place |
| Tables | 3 | 5 |

## Screenshots to take for the lab file
1. ER diagram (draw.io) of the star schema
2. ER diagram of the snowflake schema
3. Output of `SHOW TABLES` in each schema
4. Row counts (step 4 query 1) and one analysis query from each schema
