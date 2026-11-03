# Recommended visualisations and insights - Employee

| # | Visual | Fields | Business question |
|---|--------|--------|-------------------|
| 1 | Clustered column | Axis = City, Values = Attrition Rate, Legend = Gender | Which city loses the most people, and is it gender-driven? |
| 2 | Stacked bar | Axis = Education, Legend = Left Company, Values = Employees | Does education level affect attrition? |
| 3 | Line | Axis = JoiningYear, Values = Employees | In which years did hiring peak? |
| 4 | Donut | Legend = PaymentTier, Values = Employees | How is the workforce spread across salary tiers? |

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

1. *Which city loses the most people, and is it gender-driven?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
2. *Does education level affect attrition?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
3. *In which years did hiring peak?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."
4. *How is the workforce spread across salary tiers?* -> "**<top member>** leads with **<value>** (<x>% of total); **<lowest member>** is lowest; the gap suggests <action>."

## Data-quality checks before visualising

* run the PROFILE query at the end of `01_staging_load.sql` (blank values per column)
* remove exact duplicate rows, trim spaces in text columns, fix data types (dates, numbers)
* check the totals in Power BI / Tableau against `SUM()` in MySQL - they must match
* dataset note: No employee ID in the source: the fact table uses a surrogate key (fact_id).
* dataset note: LeaveOrNot is the target flag: 1 = employee left. SUM(LeaveOrNot) = number of leavers.
* dataset note: Name "Employee" is generic. If your file is different (e.g. Employee/HR all-in-one), follow the generic template in 00_Common.
