# Customer_Purchase_History_Dataset

**Confidence in column list:** A - columns verified online

**Source:** Kaggle "Customer Purchasing Behaviors" by hanaksoy (238 rows, 7 columns). https://baselight.app/u/kaggle/dataset/hanaksoy_customer_purchasing_behaviors  (the name "Customer Purchase History" is ambiguous - check your header against the table)

> WARNING: several public files share this name. Open your CSV, compare its header row with the table below. If it differs, follow `00_Common/If_Your_Columns_Differ.md`.

## Columns (7)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `user_id` | int | Unique customer id |
| 2 | `age` | int | Customer age |
| 3 | `annual_income` | decimal | Annual income (USD) |
| 4 | `purchase_amount` | decimal | Total purchase amount (USD) |
| 5 | `loyalty_score` | decimal | Loyalty score |
| 6 | `region` | text | Region (North / South / East / West) |
| 7 | `purchase_frequency` | int | Purchases per year |

## Notes

* One row per customer, no transaction date: so there is no dim_date. The time dimension is replaced by customer bands.
* age_group and income_band are derived dimensions built with CASE expressions in the ETL.
* Region values: North, South, East, West.

## Folder map

```
08_Customer_Purchase_History_Dataset/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Customer_Purchase_History_Dataset/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_customer_purchase` - One row per customer.
* Dimensions: `dim_region`, `dim_demographic`
* Main measure: Purchase Amount; analysis dimensions: region, age_group, income_band
