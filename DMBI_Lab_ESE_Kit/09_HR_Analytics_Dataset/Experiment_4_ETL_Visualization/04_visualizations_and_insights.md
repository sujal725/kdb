# Recommended visualisations and insights - HR_Analytics_Dataset

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Bar | Axis = Department, Values = Attrition Rate | Which department loses the most people? |
| 2 | Stacked column | Axis = Tenure Band, Legend = Attrition, Values = Employees | When in their tenure do people leave? |
| 3 | Matrix / heat map | Rows = JobRole, Columns = OverTime, Values = Attrition Rate | Does overtime drive attrition in specific roles? |
| 4 | Box / scatter | X = Age, Y = MonthlyIncome, Legend = Attrition | Do low-paid younger employees leave more? |
| 5 | Decomposition tree (Power BI) | Analyze = Leavers, Explain by = Department, JobRole, OverTime, MaritalStatus | What combination explains attrition best? |

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

1. *Which department loses the most people?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *When in their tenure do people leave?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *Does overtime drive attrition in specific roles?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *Do low-paid younger employees leave more?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
5. *What combination explains attrition best?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: EmployeeCount, EmployeeNumber, Over18 and StandardHours are constants/ids with no analytical value - they are loaded into staging but not into the fact table.
* dataset note: Attrition (Yes/No) becomes attrition_flag (1/0) so SUM() = number of leavers and AVG() = attrition rate.
* dataset note: If your file is the 35-column IBM version, delete EmpID/AgeGroup/SalarySlab from the dimension/ETL lines (marked in the SQL) or use the generic template.
* dataset note: Satisfaction ratings are numeric 1-4 here. Some copies store them as text (Low/Medium/High) - then change those staging columns to VARCHAR.
