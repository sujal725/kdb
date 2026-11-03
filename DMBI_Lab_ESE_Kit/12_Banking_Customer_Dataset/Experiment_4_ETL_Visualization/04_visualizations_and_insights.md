# Recommended visualisations and insights - Banking_Customer_Dataset

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Filled map | Location = Geography, Values = Churn Rate | Which country has the highest churn? |
| 2 | Column | Axis = Age Group, Values = Churn Rate | Which age group churns most? |
| 3 | Stacked column | Axis = NumOfProducts, Legend = Churn Status, Values = Customers | Do customers with more products stay? |
| 4 | Scatter | X = CreditScore, Y = Balance, Legend = Churn Status | Are high-balance customers leaving? |
| 5 | Donut | Legend = IsActiveMember, Values = Customers | How many members are inactive? |

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

1. *Which country has the highest churn?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *Which age group churns most?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *Do customers with more products stay?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *Are high-balance customers leaving?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
5. *How many members are inactive?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: RowNumber is just a row counter; it is kept as a degenerate column named src_row_number (ROW_NUMBER is a reserved word in MySQL 8).
* dataset note: Exited = 1 means the customer churned. HasCrCard and IsActiveMember are 0/1 flags.
* dataset note: CustomerId and Surname are identifiers - useful in dim_customer, not for analysis. Geography: France, Germany, Spain.
