# Sales_Transaction_Dataset

**Confidence in column list:** B - partly verified / several files share this name

**Source:** Kaggle "E-commerce Business Transaction" / "Sales Transaction Dataset" by gabrielramos87 (~500K rows, 8 columns, UK online shop, one year). https://baselight.app/u/kaggle/dataset/gabrielramos87_an_online_shop_business

> WARNING: several public files share this name. Open your CSV, compare its header row with the table below. If it differs, follow `00_Common/If_Your_Columns_Differ.md`.

## Columns (8)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `TransactionNo` | text | Six-digit transaction number (C prefix = cancellation) |
| 2 | `Date` | date | Transaction date |
| 3 | `ProductNo` | text | Product code |
| 4 | `ProductName` | text | Product name |
| 5 | `Price` | decimal | Unit price (GBP) |
| 6 | `Quantity` | int | Units (negative = cancellation) |
| 7 | `CustomerNo` | text | Customer number (5 digits) |
| 8 | `Country` | text | Customer country |

## Notes

* A TransactionNo starting with "C" is a cancellation (Quantity is negative).
* CustomerNo is missing/-1 for some rows. ProductName can be blank. Treat these as a cleaning step in Experiment 4.
* Dates are m/d/yyyy in the Kaggle file (e.g. 12/9/2019). Change the format string if yours differs.
* About 500K rows: the fact load can take a minute or two. Use the first 20,000 rows if the exam machine is slow.

## Folder map

```
06_Sales_Transaction_Dataset/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Sales_Transaction_Dataset/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_sales` - One row per product line within a transaction.
* Dimensions: `dim_date`, `dim_product`, `dim_customer`
* Main measure: Sales Amount; analysis dimensions: country, month_name, product_name
