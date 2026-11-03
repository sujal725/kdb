# Tableau Public steps - Banking_Customer_Dataset

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `Churn_Modelling.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

5. Right click **Geography** in the Data pane > **Geographic Role** > choose the matching role (City/Country) so maps work.

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Age Group | `IF [Age]<25 THEN "18-24" ELSEIF [Age]<35 THEN "25-34" ELSEIF [Age]<45 THEN "35-44" ELSEIF [Age]<55 THEN "45-54" ELSE "55+" END` |
| Credit Band | `IF [CreditScore]<580 THEN "Poor" ELSEIF [CreditScore]<670 THEN "Fair" ELSEIF [CreditScore]<740 THEN "Good" ELSEIF [CreditScore]<800 THEN "Very Good" ELSE "Excellent" END` |
| Churn Status | `IF [Exited]=1 THEN "Churned" ELSE "Retained" END` |
| Zero Balance | `IF [Balance]=0 THEN "Zero balance" ELSE "Has balance" END` |

## 3. Worksheets

**Sheet 1 - Filled map**  
*Question:* Which country has the highest churn?  
*Build:* Location = Geography, Values = Churn Rate  
*Mark type:* choose `Filled` from the Marks card; add labels / colour as needed.

**Sheet 2 - Column**  
*Question:* Which age group churns most?  
*Build:* Axis = Age Group, Values = Churn Rate  
*Mark type:* choose `Column` from the Marks card; add labels / colour as needed.

**Sheet 3 - Stacked column**  
*Question:* Do customers with more products stay?  
*Build:* Axis = NumOfProducts, Legend = Churn Status, Values = Customers  
*Mark type:* choose `Stacked` from the Marks card; add labels / colour as needed.

**Sheet 4 - Scatter**  
*Question:* Are high-balance customers leaving?  
*Build:* X = CreditScore, Y = Balance, Legend = Churn Status  
*Mark type:* choose `Scatter` from the Marks card; add labels / colour as needed.

**Sheet 5 - Donut**  
*Question:* How many members are inactive?  
*Build:* Legend = IsActiveMember, Values = Customers  
*Mark type:* choose `Donut` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
