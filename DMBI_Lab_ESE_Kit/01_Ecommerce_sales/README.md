# Ecommerce_sales

**Confidence in column list:** B - partly verified / several files share this name

**Source:** Kaggle "E-commerce Sales Prediction Dataset" by nevildhinoja (1,000 synthetic rows, 7 columns). https://baselight.app/u/kaggle/dataset/nevildhinoja_e_commerce_sales_prediction_dataset

> WARNING: several public files share this name. Open your CSV, compare its header row with the table below. If it differs, follow `00_Common/If_Your_Columns_Differ.md`.

## Columns (7)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `Date` | date | Transaction date |
| 2 | `Product_Category` | text | Product category |
| 3 | `Price` | decimal | Unit selling price |
| 4 | `Discount` | decimal | Discount percentage |
| 5 | `Customer_Segment` | text | Customer segment |
| 6 | `Marketing_Spend` | decimal | Marketing spend for the record |
| 7 | `Units_Sold` | int | Units sold |

## Notes

* Synthetic data, 1,000 rows, no order/customer ID - the fact table gets a surrogate key.
* Discount is a percentage value (e.g. 11.3 means 11.3 %). Check with SELECT MIN(Discount), MAX(Discount).
* Name "Ecommerce_sales" also matches other Kaggle files - compare your file header with the table above.

## Folder map

```
01_Ecommerce_sales/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Ecommerce_sales/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_sales` - One row per daily sales record (product category x customer segment x day).
* Dimensions: `dim_date`, `dim_product_category`, `dim_customer_segment`, `dim_discount_band`
* Main measure: Net Revenue; analysis dimensions: product_category, customer_segment, discount_band
