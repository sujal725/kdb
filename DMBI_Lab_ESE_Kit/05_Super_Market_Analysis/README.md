# Super_Market_Analysis

**Confidence in column list:** A - columns verified online

**Source:** Kaggle "Supermarket sales" by aungpyaeap (1,000 rows, 17 columns, 3 branches in Myanmar, Jan-Mar 2019). Column list confirmed on multiple sources, e.g. https://baselight.app/u/kaggle/dataset/lovishbansal123_sales_of_a_supermarket

## Columns (17)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `Invoice ID` | text | Computer generated invoice number |
| 2 | `Branch` | text | Branch A / B / C |
| 3 | `City` | text | City of the branch (Yangon, Mandalay, Naypyitaw) |
| 4 | `Customer type` | text | Member / Normal |
| 5 | `Gender` | text | Customer gender |
| 6 | `Product line` | text | Product category (6 lines) |
| 7 | `Unit price` | decimal | Price per unit in USD |
| 8 | `Quantity` | int | Units purchased |
| 9 | `Tax 5%` | decimal | 5 % tax amount |
| 10 | `Total` | decimal | Total incl. tax |
| 11 | `Date` | date | Purchase date (Jan-Mar 2019) |
| 12 | `Time` | time | Purchase time |
| 13 | `Payment` | text | Cash / Credit card / Ewallet |
| 14 | `cogs` | decimal | Cost of goods sold |
| 15 | `gross margin percentage` | decimal | Gross margin % (constant) |
| 16 | `gross income` | decimal | Gross income |
| 17 | `Rating` | decimal | Customer rating 1-10 |

## Notes

* Dates are m/d/yyyy (1/5/2019 = 5 January 2019). Time is HH:MM.
* cogs = Unit price x Quantity; Tax 5% = 5 % of cogs; Total = cogs + Tax; gross income = Tax 5%; gross margin percentage is constant (4.7619). Treat gross margin percentage as a non-informative column in Experiment 4.
* Branch A = Yangon, B = Mandalay, C = Naypyitaw (one branch per city).

## Folder map

```
05_Super_Market_Analysis/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Super_Market_Analysis/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_sales` - One row per invoice (one product line per invoice).
* Dimensions: `dim_date`, `dim_branch`, `dim_customer`, `dim_product_line`, `dim_payment`
* Main measure: Total Sales; analysis dimensions: product_line, city, customer_type
