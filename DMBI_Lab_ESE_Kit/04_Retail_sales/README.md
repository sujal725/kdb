# Retail_sales

**Confidence in column list:** A - columns verified online

**Source:** Kaggle "Retail Sales Dataset" by mohammadtalib786 (1,000 rows, 9 columns). https://baselight.app/u/kaggle/dataset/mohammadtalib786_retail_sales_dataset

## Columns (9)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `Transaction ID` | bigint | Unique transaction id |
| 2 | `Date` | date | Transaction date |
| 3 | `Customer ID` | text | Customer id (CUST001 ...) |
| 4 | `Gender` | text | Male / Female |
| 5 | `Age` | int | Customer age |
| 6 | `Product Category` | text | Beauty / Clothing / Electronics |
| 7 | `Quantity` | int | Units bought |
| 8 | `Price per Unit` | decimal | Unit price |
| 9 | `Total Amount` | decimal | Quantity x Price per Unit |

## Notes

* Total Amount = Quantity x Price per Unit (verify with a calculated column).
* Customer ID values look like CUST001 (text). Gender: Male / Female. Product Category: Beauty, Clothing, Electronics.
* Dates are ISO (yyyy-mm-dd). If your copy uses dd-mm-yyyy change the format string at the top of the ETL files.

## Folder map

```
04_Retail_sales/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Retail_sales/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_sales` - One row per sales transaction.
* Dimensions: `dim_date`, `dim_customer`, `dim_product_category`
* Main measure: Total Amount; analysis dimensions: product_category, gender, age_group
