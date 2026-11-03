# Experiment 4 - Extract, Transform, Visualise (Power BI / Tableau) : Banking_Customer_Dataset

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

1. **Extract:** Home > Get data > Text/CSV > select `Churn_Modelling.csv` > **Transform Data**.
2. **Transform:** Home > Advanced Editor > replace all with `01_power_query_transform.m` (edit the path) > Done. Rename the query to `churn_modelling`.
   Check *Column quality / distribution / profile* (View tab) for errors and empty values.
3. **Load:** Home > Close & Apply.
4. **Model:** add measures from `02_dax_measures.dax` (Modeling > New measure).
5. **Visualise:** build the visuals listed in `04_visualizations_and_insights.md`; add slicers for Geography, Gender, Age Group.
6. **Insights:** write 3-5 observations on the report page (text box) and save the .pbix.
7. Screenshots: Power Query steps, data model/relationships, final report page.

**Extract from MySQL instead (optional):** Get data > MySQL database > server `localhost`, database `dmbi_banking_customer_star` > pick `vw_banking_customer_flat` (create it with `05_mysql_flat_view.sql`). Needs the MySQL Connector/NET driver.

## Transformations applied

| Derived column | Power Query (M) |
|---|---|
| Age Group | `if [Age] < 25 then "18-24" else if [Age] < 35 then "25-34" else if [Age] < 45 then "35-44" else if [Age] < 55 then "45-54" else "55+"` |
| Credit Band | `if [CreditScore] < 580 then "Poor" else if [CreditScore] < 670 then "Fair" else if [CreditScore] < 740 then "Good" else if [CreditScore] < 800 then "Very Good" else "Excellent"` |
| Churn Status | `if [Exited] = 1 then "Churned" else "Retained"` |
| Zero Balance | `if [Balance] = 0 then "Zero balance" else "Has balance"` |

| Cleaning step | Why |
|---|---|
| Promote headers, change data types | CSV arrives as text |
| Trim text columns | hidden spaces break grouping |
| Remove duplicate rows | avoid double counting |
| Remove rows with a null key (CustomerId) | incomplete records |
