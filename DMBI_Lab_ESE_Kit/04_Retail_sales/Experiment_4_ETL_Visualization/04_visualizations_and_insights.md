# Recommended visualisations and insights - Retail_sales

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Line | Axis = Month, Values = Total Total Amount | Which months are the sales peaks? |
| 2 | Stacked column | Axis = Product Category, Legend = Gender, Values = Total Total Amount | Which category does each gender prefer? |
| 3 | Bar | Axis = Age Group, Values = Avg Order Value | Which age group spends most per order? |
| 4 | Donut | Legend = Product Category, Values = Quantity | What is the unit share per category? |

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

1. *Which months are the sales peaks?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *Which category does each gender prefer?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *Which age group spends most per order?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *What is the unit share per category?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: Total Amount = Quantity x Price per Unit (verify with a calculated column).
* dataset note: Customer ID values look like CUST001 (text). Gender: Male / Female. Product Category: Beauty, Clothing, Electronics.
* dataset note: Dates are ISO (yyyy-mm-dd). If your copy uses dd-mm-yyyy change the format string at the top of the ETL files.
