# Recommended visualisations and insights - Retail_Transactions_Dataset

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Clustered column | Axis = Season, Values = Total Total_Cost, Legend = Store_Type | Which store type sells most in which season? |
| 2 | Donut | Legend = Payment_Method, Values = Transactions | How do customers pay? |
| 3 | Bar | Axis = Promotion Clean, Values = Avg Basket Value | Which promotions lift basket value? |
| 4 | Matrix | Rows = City, Columns = Customer_Category, Values = Total Total_Cost | Which customer category matters in which city? |

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

1. *Which store type sells most in which season?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *How do customers pay?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *Which promotions lift basket value?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *Which customer category matters in which city?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: Product is a text list of items bought in the basket, e.g. [Ketchup, Tomatoes]. It is kept as a degenerate attribute, not a dimension.
* dataset note: Discount_Applied is TRUE/FALSE text; the ETL converts it to 1/0.
* dataset note: Promotion can be empty (NULL) - the ETL uses NULL-safe joins (<=>).
* dataset note: Date contains date and time (yyyy-mm-dd hh:mm:ss). Only the date part is used for dim_date.
