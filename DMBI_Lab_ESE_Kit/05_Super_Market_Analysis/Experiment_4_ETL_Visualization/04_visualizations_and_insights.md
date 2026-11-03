# Recommended visualisations and insights - Super_Market_Analysis

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Line | Axis = Date, Values = Total Total, Legend = City | Which branch/city grows fastest over the quarter? |
| 2 | Bar | Axis = Product line, Values = Total gross income | Which product line earns the most? |
| 3 | Column | Axis = Hour, Values = Invoices | What are the peak shopping hours? |
| 4 | Donut | Legend = Payment, Values = Invoices | Which payment method dominates? |
| 5 | Matrix | Rows = Product line, Columns = Customer type, Values = Avg Rating | Do members rate product lines differently? |

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

1. *Which branch/city grows fastest over the quarter?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *Which product line earns the most?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *What are the peak shopping hours?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *Which payment method dominates?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
5. *Do members rate product lines differently?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: Dates are m/d/yyyy (1/5/2019 = 5 January 2019). Time is HH:MM.
* dataset note: cogs = Unit price x Quantity; Tax 5% = 5 % of cogs; Total = cogs + Tax; gross income = Tax 5%; gross margin percentage is constant (4.7619). Treat gross margin percentage as a non-informative column in Experiment 4.
* dataset note: Branch A = Yangon, B = Mandalay, C = Naypyitaw (one branch per city).
