# Banking_Customer_Dataset

**Confidence in column list:** A - columns verified online

**Source:** Kaggle "Churn Modelling / Bank Customer Churn" (10,000 rows, 14 columns, European bank). https://baselight.app/u/kaggle/dataset/murilozangari_customer_churn_from_a_bank

> WARNING: several public files share this name. Open your CSV, compare its header row with the table below. If it differs, follow `00_Common/If_Your_Columns_Differ.md`.

## Columns (14)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `RowNumber` | int | Row counter 1-10000 |
| 2 | `CustomerId` | bigint | Unique customer id |
| 3 | `Surname` | text | Customer surname |
| 4 | `CreditScore` | int | Credit score (350-850) |
| 5 | `Geography` | text | Country (France / Germany / Spain) |
| 6 | `Gender` | text | Male / Female |
| 7 | `Age` | int | Age |
| 8 | `Tenure` | int | Years with the bank (0-10) |
| 9 | `Balance` | decimal | Account balance (EUR) |
| 10 | `NumOfProducts` | int | Number of bank products (1-4) |
| 11 | `HasCrCard` | int | 1 = has credit card |
| 12 | `IsActiveMember` | int | 1 = active member |
| 13 | `EstimatedSalary` | decimal | Estimated annual salary (EUR) |
| 14 | `Exited` | int | 1 = customer left the bank (churn) |

## Notes

* RowNumber is just a row counter; it is kept as a degenerate column named src_row_number (ROW_NUMBER is a reserved word in MySQL 8).
* Exited = 1 means the customer churned. HasCrCard and IsActiveMember are 0/1 flags.
* CustomerId and Surname are identifiers - useful in dim_customer, not for analysis. Geography: France, Germany, Spain.

## Folder map

```
12_Banking_Customer_Dataset/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Banking_Customer_Dataset/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_bank_customer` - One row per bank customer.
* Dimensions: `dim_customer`, `dim_geography`, `dim_credit_band`
* Main measure: Total Balance; analysis dimensions: geography, gender, credit_band
