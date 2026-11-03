# Experiment 1 - Star and Snowflake Schema : HR_Analytics_Dataset

**Aim:** design and implement a star schema and a snowflake schema for efficient storage and retrieval of the HR_Analytics_Dataset data for BI.

## Files (run in this order)

| # | File | What it does |
|---|------|--------------|
| 1 | `01_staging_load.sql` | creates schema `dmbi_hr_analytics_stg`, staging table, loads the CSV (**edit the path**) |
| 2 | `02_star_schema.sql` | creates schema `dmbi_hr_analytics_star`: DDL + ETL for the star schema |
| 3 | `03_snowflake_schema.sql` | creates schema `dmbi_hr_analytics_snow`: DDL + ETL for the snowflake schema |
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

* **Grain of the fact table:** One row per employee.
* **Fact table `fact_employee_hr`** holds the numeric measures: `age`, `attrition_flag`, `daily_rate`, `hourly_rate`, `monthly_rate`, `monthly_income`, `distance_from_home`, `num_companies_worked`, `percent_salary_hike`, `performance_rating`, `environment_satisfaction`, `job_involvement`, `job_satisfaction`, `relationship_satisfaction`, `work_life_balance`, `stock_option_level`, `total_working_years`, `training_times_last_year`, `years_at_company`, `years_in_current_role`, `years_since_last_promotion`, `years_with_curr_manager`.
* **Degenerate dimension(s)** (identifier kept inside the fact, no table): `emp_id`
* There is no date column in this dataset, so there is no date dimension.
* **Surrogate keys:** every dimension has an AUTO_INCREMENT `*_key`; the fact references them with foreign keys.
* **NULL-safe joins (`<=>`)** keep rows that have blank attributes.

## Star schema tables

| Table | Type | Columns |
|-------|------|---------|
| `fact_employee_hr` | FACT | `employee_demo_key`, `education_key`, `job_key`, `work_profile_key`, `salary_slab_key`, `emp_id`, `age`, `attrition_flag`, `daily_rate`, `hourly_rate`, `monthly_rate`, `monthly_income`, `distance_from_home`, `num_companies_worked`, `percent_salary_hike`, `performance_rating`, `environment_satisfaction`, `job_involvement`, `job_satisfaction`, `relationship_satisfaction`, `work_life_balance`, `stock_option_level`, `total_working_years`, `training_times_last_year`, `years_at_company`, `years_in_current_role`, `years_since_last_promotion`, `years_with_curr_manager` |
| `dim_employee_demo` | DIM | `gender`, `marital_status`, `age_group` |
| `dim_education` | DIM | `education`, `education_field` |
| `dim_job` | DIM | `department`, `job_role`, `job_level` |
| `dim_work_profile` | DIM | `business_travel`, `over_time` |
| `dim_salary_slab` | DIM | `salary_slab` |

## Snowflake schema - what changes

Same fact table, but dimension attributes are moved into **sub-dimension** tables (3NF) and the parent keeps a foreign key:

| Parent dimension | Sub-dimension(s) |
|---|---|
| `dim_employee_demo` | `dim_age_group` (age_group) |
| `dim_education` | `dim_education_field` (education_field) |
| `dim_job` | `dim_department` (department) |

| | Star | Snowflake |
|---|---|---|
| Dimensions | denormalised (one table each) | normalised into sub-dimensions |
| Joins per query | fewer, faster | more joins, slower |
| Storage | some redundancy | less redundancy |
| Maintenance | simpler | updates of a value happen in one place |
| Tables | 6 | 9 |

## Screenshots to take for the lab file
1. ER diagram (draw.io) of the star schema
2. ER diagram of the snowflake schema
3. Output of `SHOW TABLES` in each schema
4. Row counts (step 4 query 1) and one analysis query from each schema
