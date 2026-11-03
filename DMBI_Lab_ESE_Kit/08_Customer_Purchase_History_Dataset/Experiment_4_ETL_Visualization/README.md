# Experiment 4 - Extract, Transform, Visualise (Power BI / Tableau) : Customer_Purchase_History_Dataset

**Aim:** extract, transform and visualise business data with Power BI / Tableau and derive insights.

## Files

| File | Use |
|---|---|
| `01_power_query_transform.m` | paste into Power BI Advanced Editor: loads the CSV, fixes types, cleans, adds derived columns |
| `02_dax_measures.dax` | measures for cards/charts (and time intelligence when a date exists) |
| `03_tableau_public_steps.md` | the same work in Tableau Public (connect, calculated fields, sheets, dashboard) |
| `04_visualizations_and_insights.md` | which charts to build, which question each answers, insight sentences |
| `05_mysql_flat_view.sql` | optional: flat view on the star schema if you want to extract from MySQL instead of the CSV |

## Power BI workflow (about 20 minutes)

1. **Extract:** Home > Get data > Text/CSV > select `Customer Purchasing Behaviors.csv` > **Transform Data**.
2. **Transform:** Home > Advanced Editor > replace all with `01_power_query_transform.m` (edit the path) > Done. Rename the query to `customer_purchasing_behaviors`.
   Check *Column quality / distribution / profile* (View tab) for errors and empty values.
3. **Load:** Home > Close & Apply.
4. **Model:** add measures from `02_dax_measures.dax` (Modeling > New measure).
5. **Visualise:** build the visuals listed in `04_visualizations_and_insights.md`; add slicers for region, Age Group, Income Band.
6. **Insights:** write 3-5 observations on the report page (text box) and save the .pbix.
7. Screenshots: Power Query steps, data model/relationships, final report page.

**Extract from MySQL instead (optional):** Get data > MySQL database > server `localhost`, database `dmbi_customer_purchase_star` > pick `vw_customer_purchase_flat` (create it with `05_mysql_flat_view.sql`). Needs the MySQL Connector/NET driver.

## Transformations applied

| Derived column | Power Query (M) |
|---|---|
| Age Group | `if [age] < 25 then "18-24" else if [age] < 35 then "25-34" else if [age] < 45 then "35-44" else if [age] < 55 then "45-54" else "55+"` |
| Income Band | `if [annual_income] < 40000 then "Below 40k" else if [annual_income] < 60000 then "40k-59k" else if [annual_income] < 80000 then "60k-79k" else "80k+"` |
| Spend to Income | `[purchase_amount] / [annual_income]` |

| Cleaning step | Why |
|---|---|
| Promote headers, change data types | CSV arrives as text |
| Trim text columns | hidden spaces break grouping |
| Remove duplicate rows | avoid double counting |
| Remove rows with a null key (user_id) | incomplete records |
