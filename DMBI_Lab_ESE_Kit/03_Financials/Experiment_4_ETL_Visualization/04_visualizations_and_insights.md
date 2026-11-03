# Recommended visualisations and insights - Financials

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Filled map | Location = Country, Size/Colour = Total Sales | Which countries are the biggest markets? |
| 2 | Clustered column | Axis = Segment, Values = Total Sales and Total Profit | Which segment is most profitable? |
| 3 | Waterfall | Category = Product, Values = Total Profit | Which products create or destroy profit? |
| 4 | Line | Axis = Date (Year > Month), Values = Total Sales, Legend = Segment | What is the monthly sales trend? |
| 5 | Scatter | X = Discount Rate, Y = Profit Margin %, Details = Product | Do higher discounts erode margins? |

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

1. *Which countries are the biggest markets?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *Which segment is most profitable?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *Which products create or destroy profit?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *What is the monthly sales trend?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
5. *Do higher discounts erode margins?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: The Excel version stores money as text like "$1,618.50" and negatives as "($1,000.00)". This kit loads those columns as text and cleans them in ETL.
* dataset note: Excel headers may contain leading/trailing spaces (" Sales ", " Gross Sales "). If so, rename the staging columns (ALTER TABLE ... CHANGE) or edit the headers in the .sql files.
* dataset note: Date: dates are always the 1st of a month. The ETL builds the date from Year + Month Number so it works for any regional date format.
* dataset note: Segment values: Government, Midmarket, Channel Partners, Enterprise, Small Business. Products: Carretera, Montana, Paseo, Velo, VTT, Amarilla.
