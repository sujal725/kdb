# Tableau Public steps - HR_Analytics_Dataset

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `HR_Analytics.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Attrition Flag | `IF [Attrition]="Yes" THEN 1 ELSE 0 END` |
| Income Slab | `IF [MonthlyIncome]<3000 THEN "Low" ELSEIF [MonthlyIncome]<6000 THEN "Medium" ELSEIF [MonthlyIncome]<10000 THEN "High" ELSE "Very High" END` |
| Tenure Band | `IF [YearsAtCompany]<2 THEN "0-1 yrs" ELSEIF [YearsAtCompany]<5 THEN "2-4 yrs" ELSEIF [YearsAtCompany]<10 THEN "5-9 yrs" ELSE "10+ yrs" END` |

## 3. Worksheets

**Sheet 1 - Bar**  
*Question:* Which department loses the most people?  
*Build:* Axis = Department, Values = Attrition Rate  
*Mark type:* choose `Bar` from the Marks card; add labels / colour as needed.

**Sheet 2 - Stacked column**  
*Question:* When in their tenure do people leave?  
*Build:* Axis = Tenure Band, Legend = Attrition, Values = Employees  
*Mark type:* choose `Stacked` from the Marks card; add labels / colour as needed.

**Sheet 3 - Matrix / heat map**  
*Question:* Does overtime drive attrition in specific roles?  
*Build:* Rows = JobRole, Columns = OverTime, Values = Attrition Rate  
*Mark type:* choose `Matrix` from the Marks card; add labels / colour as needed.

**Sheet 4 - Box / scatter**  
*Question:* Do low-paid younger employees leave more?  
*Build:* X = Age, Y = MonthlyIncome, Legend = Attrition  
*Mark type:* choose `Box` from the Marks card; add labels / colour as needed.

**Sheet 5 - Decomposition tree (Power BI)**  
*Question:* What combination explains attrition best?  
*Build:* Analyze = Leavers, Explain by = Department, JobRole, OverTime, MaritalStatus  
*Mark type:* choose `Decomposition` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
