# Viva questions and short answers (Data Mining & Business Intelligence lab)

**Q1. What is a data warehouse?** A subject-oriented, integrated, time-variant, non-volatile store of historical data used for analysis and decisions.
**Q2. What is a star schema?** One central fact table joined directly to denormalised dimension tables - looks like a star.
**Q3. What is a snowflake schema?** A star schema whose dimensions are normalised into sub-dimensions (3NF) - looks like a snowflake.
**Q4. Star vs snowflake?** Star: fewer joins, faster queries, simpler, some redundancy. Snowflake: less redundancy/storage, easier maintenance, more joins and complexity.
**Q5. What is a fact table / dimension table?** Fact = measurable events (sales amount, quantity) + foreign keys. Dimension = descriptive context (who, what, where, when).
**Q6. What is the grain?** The level of detail of one fact row (e.g. one invoice line). Decide the grain first.
**Q7. What is a surrogate key and why?** A system-generated integer key for a dimension row; independent of source keys, small and fast for joins.
**Q8. What is a degenerate dimension?** An identifier (invoice/transaction number) stored in the fact with no dimension table.
**Q9. What is a conformed dimension?** A dimension shared by several fact tables with the same meaning (e.g. dim_date).
**Q10. Additive / semi-additive / non-additive measures?** Additive: sum across all dimensions (sales). Semi-additive: only across some (balance not across time). Non-additive: ratios, percentages.
**Q11. What is ETL?** Extract from sources, Transform (clean, convert, derive), Load into the warehouse.
**Q12. What is OLTP?** Online Transaction Processing: many short INSERT/UPDATE/DELETE transactions, normalised data, ACID.
**Q13. What is OLAP?** Online Analytical Processing: multidimensional analysis of historical data (roll-up, drill-down, slice, dice, pivot).
**Q14. OLTP vs OLAP?** OLTP = run the business, current data, row level, normalised. OLAP = analyse the business, historical, aggregated, star schema.
**Q15. Define roll-up and drill-down.** Roll-up: aggregate up a hierarchy (month -> quarter -> year). Drill-down: reverse, from summary to detail.
**Q16. Slice vs dice?** Slice: fix one dimension to one value. Dice: select a sub-cube by restricting two or more dimensions.
**Q17. What is pivot?** Rotate the data axes: turn row values into column headers.
**Q18. Types of OLAP?** ROLAP (relational), MOLAP (multidimensional cube), HOLAP (hybrid).
**Q19. What is ACID?** Atomicity, Consistency, Isolation, Durability.
**Q20. COMMIT / ROLLBACK / SAVEPOINT?** COMMIT makes changes permanent; ROLLBACK undoes the transaction; SAVEPOINT allows a partial rollback.
**Q21. Why an index?** Fast lookup without scanning the whole table (B-tree); essential for OLTP point queries.
**Q22. What is a data mart?** A small subject-specific warehouse (e.g. sales mart).
**Q23. What is a slowly changing dimension?** A dimension whose attributes change over time: Type 1 overwrite, Type 2 add a new row with validity dates, Type 3 add a column.
**Q24. What is a measure and a KPI?** Measure = numeric value (SUM of sales). KPI = measure compared with a target (profit margin, churn rate).
**Q25. What is DAX?** Data Analysis Expressions: the formula language of Power BI for measures and calculated columns.
**Q26. Calculated column vs measure?** Column: computed per row at load time and stored. Measure: computed at query time from the filter context.
**Q27. What is Power Query?** The ETL tool inside Power BI (M language) to connect, clean and shape data.
**Q28. Power BI vs Tableau?** Power BI: DAX, Microsoft ecosystem, modelling strength, cheap. Tableau: very strong visual exploration, drag-and-drop, Tableau Public for publishing.
**Q29. Which chart for what?** Trend = line; comparison = bar/column; share = donut/stacked bar (few categories); relation = scatter; geography = map; detail = table/matrix.
**Q30. What makes a good dashboard?** One purpose, KPI cards first, simple charts, consistent colours, filters/slicers, clear titles, few insights stated.
