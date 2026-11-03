# Recommended visualisations and insights - Online_Orders_Dataset

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Line | Axis = Date (Month), Values = Total Total Revenue | What is the revenue trend over time? |
| 2 | Stacked column | Axis = Product Category, Legend = Region, Values = Total Total Revenue | Which category sells where? |
| 3 | Donut | Legend = Payment Method, Values = Orders | Which payment method is most popular? |
| 4 | Bar (Top N = 5) | Axis = Product Name, Values = Total Total Revenue | What are the best-selling products? |

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

1. *What is the revenue trend over time?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *Which category sells where?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *Which payment method is most popular?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *What are the best-selling products?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: Total Price = Quantity x Unit Price. Small dataset (240 rows): ideal for a quick demo.
* dataset note: Region values: North America, Europe, Asia. Payment Method: Credit Card, PayPal, Debit Card.
