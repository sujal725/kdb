# Financials

**Confidence in column list:** A - columns verified online

**Source:** Microsoft "Financial Sample" workbook (700 rows, 16 columns; same file is used in many Power BI/Excel tutorials). Column list confirmed on several public copies, e.g. https://www.gigasheet.com/sample-data/company-financials-dataset

## Columns (16)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `Segment` | text | Customer segment |
| 2 | `Country` | text | Country of sale (Canada, France, Germany, Mexico, United States of America) |
| 3 | `Product` | text | Product (Carretera, Montana, Paseo, Velo, VTT, Amarilla) |
| 4 | `Discount Band` | text | None / Low / Medium / High |
| 5 | `Units Sold` | decimal | Units sold |
| 6 | `Manufacturing Price` | decimal | Manufacturing price per unit |
| 7 | `Sale Price` | decimal | Sale price per unit |
| 8 | `Gross Sales` | decimal | Units Sold x Sale Price |
| 9 | `Discounts` | decimal | Discount amount |
| 10 | `Sales` | decimal | Gross Sales - Discounts |
| 11 | `COGS` | decimal | Cost of goods sold |
| 12 | `Profit` | decimal | Sales - COGS |
| 13 | `Date` | date | First day of the month of sale |
| 14 | `Month Number` | text | Month number (derived column in source) |
| 15 | `Month Name` | text | Month name (derived column in source) |
| 16 | `Year` | text | Year (derived column in source) |

## Notes

* The Excel version stores money as text like "$1,618.50" and negatives as "($1,000.00)". This kit loads those columns as text and cleans them in ETL.
* Excel headers may contain leading/trailing spaces (" Sales ", " Gross Sales "). If so, rename the staging columns (ALTER TABLE ... CHANGE) or edit the headers in the .sql files.
* Date: dates are always the 1st of a month. The ETL builds the date from Year + Month Number so it works for any regional date format.
* Segment values: Government, Midmarket, Channel Partners, Enterprise, Small Business. Products: Carretera, Montana, Paseo, Velo, VTT, Amarilla.

## Folder map

```
03_Financials/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Financials/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_sales` - One row per segment x country x product x discount band x month (as in the source file).
* Dimensions: `dim_date`, `dim_segment`, `dim_country`, `dim_product`, `dim_discount_band`
* Main measure: Sales; analysis dimensions: segment, country, product
