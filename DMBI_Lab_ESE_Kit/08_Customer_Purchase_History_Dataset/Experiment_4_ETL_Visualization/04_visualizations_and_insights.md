# Recommended visualisations and insights - Customer_Purchase_History_Dataset

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Scatter | X = annual_income, Y = purchase_amount, Legend = region | Does higher income mean higher spend? |
| 2 | Column | Axis = Age Group, Values = Spend per Customer | Which age group spends most? |
| 3 | Map / bar | Axis = region, Values = Total purchase_amount | Which region contributes most? |
| 4 | Scatter | X = loyalty_score, Y = purchase_frequency | Are loyal customers more frequent buyers? |

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

1. *Does higher income mean higher spend?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *Which age group spends most?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *Which region contributes most?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *Are loyal customers more frequent buyers?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: One row per customer, no transaction date: so there is no dim_date. The time dimension is replaced by customer bands.
* dataset note: age_group and income_band are derived dimensions built with CASE expressions in the ETL.
* dataset note: Region values: North, South, East, West.
