# Recommended visualisations and insights - Sales_Transaction_Dataset

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Line | Axis = Month, Values = Total Sales Amount | How does revenue trend over the year (seasonality)? |
| 2 | Filled map | Location = Country, Values = Total Sales Amount | Which countries buy most? |
| 3 | Bar (Top N = 10) | Axis = ProductName, Values = Total Quantity | Which products sell the most units? |
| 4 | Card | Cancellation Rate | What share of lines are cancellations? |

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

1. *How does revenue trend over the year (seasonality)?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *Which countries buy most?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *Which products sell the most units?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *What share of lines are cancellations?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: A TransactionNo starting with "C" is a cancellation (Quantity is negative).
* dataset note: CustomerNo is missing/-1 for some rows. ProductName can be blank. Treat these as a cleaning step in Experiment 4.
* dataset note: Dates are m/d/yyyy in the Kaggle file (e.g. 12/9/2019). Change the format string if yours differs.
* dataset note: About 500K rows: the fact load can take a minute or two. Use the first 20,000 rows if the exam machine is slow.
