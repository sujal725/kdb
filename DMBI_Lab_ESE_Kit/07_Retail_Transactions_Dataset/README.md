# Retail_Transactions_Dataset

**Confidence in column list:** B - partly verified / several files share this name

**Source:** Kaggle "Retail Transactions Dataset" (market-basket style, 13 columns). Column names Transaction_ID, Date, Customer_Name confirmed at https://gts.ai/dataset-download/retail-transactions-dataset/ ; the rest from the dataset description. NOTE: a different 100,000-row file called "Retail_Transaction_Dataset" (10 columns: CustomerID, ProductID, Quantity, Price, TransactionDate, PaymentMethod, StoreLocation, ProductCategory, DiscountApplied(%), TotalAmount) also exists - check your header.

> WARNING: several public files share this name. Open your CSV, compare its header row with the table below. If it differs, follow `00_Common/If_Your_Columns_Differ.md`.

## Columns (13)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `Transaction_ID` | bigint | Unique 10-digit transaction id |
| 2 | `Date` | date | Date and time of purchase |
| 3 | `Customer_Name` | text | Customer name |
| 4 | `Product` | text | Basket items (text list) |
| 5 | `Total_Items` | int | Number of items in the basket |
| 6 | `Total_Cost` | decimal | Total cost of the transaction |
| 7 | `Payment_Method` | text | Credit Card / Debit Card / Cash / Mobile Payment |
| 8 | `City` | text | City of the store |
| 9 | `Store_Type` | text | Supermarket / Convenience Store / Department Store ... |
| 10 | `Discount_Applied` | yes/no flag | TRUE/FALSE whether a discount was applied |
| 11 | `Customer_Category` | text | Young Adult / Student / Professional / Senior ... |
| 12 | `Season` | text | Winter / Spring / Summer / Fall |
| 13 | `Promotion` | text | Promotion type (can be empty) |

## Notes

* Product is a text list of items bought in the basket, e.g. [Ketchup, Tomatoes]. It is kept as a degenerate attribute, not a dimension.
* Discount_Applied is TRUE/FALSE text; the ETL converts it to 1/0.
* Promotion can be empty (NULL) - the ETL uses NULL-safe joins (<=>).
* Date contains date and time (yyyy-mm-dd hh:mm:ss). Only the date part is used for dim_date.

## Folder map

```
07_Retail_Transactions_Dataset/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Retail_Transactions_Dataset/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_transactions` - One row per basket / transaction.
* Dimensions: `dim_date`, `dim_customer`, `dim_store`, `dim_payment_method`, `dim_season`, `dim_promotion`
* Main measure: Total Cost; analysis dimensions: city, customer_category, payment_method
