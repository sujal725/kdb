# Recommended visualisations and insights - Ecommerce_sales

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Scatter | X = Avg Discount, Y = Units_Sold, Details = Product_Category | Does a bigger discount really sell more units? |
| 2 | Line | Axis = Month, Values = Net Revenue, Legend = Customer_Segment | Which segment drives the seasonal peaks? |
| 3 | Clustered bar | Axis = Product_Category, Values = Marketing ROI | Which category gives the best return on marketing spend? |
| 4 | Matrix / heat map | Rows = Product_Category, Columns = Discount Band, Values = Units_Sold | Which discount band works for which category? |

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

1. *Does a bigger discount really sell more units?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *Which segment drives the seasonal peaks?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *Which category gives the best return on marketing spend?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *Which discount band works for which category?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: Synthetic data, 1,000 rows, no order/customer ID - the fact table gets a surrogate key.
* dataset note: Discount is a percentage value (e.g. 11.3 means 11.3 %). Check with SELECT MIN(Discount), MAX(Discount).
* dataset note: Name "Ecommerce_sales" also matches other Kaggle files - compare your file header with the table above.
