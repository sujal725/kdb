# Inventory_and_Stock_Dataset

**Confidence in column list:** C - NOT verified online (best guess) - check your header first

**Source:** NOT verified online (no single dataset with this exact name was found). Best match: Kaggle "Retail Store Inventory Forecasting Dataset" (73,100 rows, 15 columns). Column names below come from my own knowledge - compare them with your file.

> WARNING: several public files share this name. Open your CSV, compare its header row with the table below. If it differs, follow `00_Common/If_Your_Columns_Differ.md`.

## Columns (15)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `Date` | date | Date of the record |
| 2 | `Store ID` | text | Store id |
| 3 | `Product ID` | text | Product id |
| 4 | `Category` | text | Product category |
| 5 | `Region` | text | Store region |
| 6 | `Inventory Level` | int | Stock on hand |
| 7 | `Units Sold` | int | Units sold |
| 8 | `Units Ordered` | int | Units re-ordered |
| 9 | `Demand Forecast` | decimal | Forecast demand |
| 10 | `Price` | decimal | Selling price |
| 11 | `Discount` | int | Discount % |
| 12 | `Weather Condition` | text | Sunny / Rainy / Cloudy / Snowy |
| 13 | `Holiday/Promotion` | int | 1 = holiday or promotion |
| 14 | `Competitor Pricing` | decimal | Competitor price |
| 15 | `Seasonality` | text | Autumn / Winter / Spring / Summer |

## Notes

* This is the least certain dataset in the pack. The name "Inventory and Stock" fits many files. If your header differs, use the generic template in 00_Common: identify date / store / product / category columns and measures like Stock, Units Sold, Reorder Level, Unit Cost, Unit Price.
* Holiday/Promotion is a 0/1 flag. Discount is a whole-number percentage.
* stock_gap = Inventory Level - Units Sold; forecast_error = Units Sold - Demand Forecast (derived measures).

## Folder map

```
10_Inventory_and_Stock_Dataset/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Inventory_and_Stock_Dataset/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_inventory` - One row per date x store x product.
* Dimensions: `dim_date`, `dim_store`, `dim_product`, `dim_weather`, `dim_season`
* Main measure: Revenue; analysis dimensions: category, region, seasonality
