# Recommended visualisations and insights - Inventory_and_Stock_Dataset

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Line | Axis = Month, Values = Total Units Sold and Total Demand Forecast | How well does the forecast track actual demand? |
| 2 | Clustered bar | Axis = Category, Values = Total Inventory Level and Total Units Sold | Which categories are over/under-stocked? |
| 3 | Stacked column | Axis = Region, Legend = Stock Status, Values = Row count | Where are stock-out risks concentrated? |
| 4 | Column | Axis = Seasonality, Values = Total Units Sold, Legend = Weather Condition | How do season and weather change demand? |

## Dashboard layout (also covers the dashboard idea of Experiment 3)

```
+------------------------------------------------------------+
|  KPI cards (totals / averages / rates)     |  slicers        |
+------------------------------------------------------------+
|  trend / time visual         |  top-N breakdown            |
+------------------------------------------------------------+
|  category comparison         |  map or matrix / detail     |
+------------------------------------------------------------+
```

## Insight sentences (fill with your numbers)

1. *How well does the forecast track actual demand?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *Which categories are over/under-stocked?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *Where are stock-out risks concentrated?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *How do season and weather change demand?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: This is the least certain dataset in the pack. The name "Inventory and Stock" fits many files. If your header differs, use the generic template in 00_Common: identify date / store / product / category columns and measures like Stock, Units Sold, Reorder Level, Unit Cost, Unit Price.
* dataset note: Holiday/Promotion is a 0/1 flag. Discount is a whole-number percentage.
* dataset note: stock_gap = Inventory Level - Units Sold; forecast_error = Units Sold - Demand Forecast (derived measures).
