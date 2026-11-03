# Tableau Public steps - Employee

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `Employee.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

5. Right click **City** in the Data pane > **Geographic Role** > choose the matching role (City/Country) so maps work.

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Age Band | `IF [Age]<25 THEN "Under 25" ELSEIF [Age]<30 THEN "25-29" ELSEIF [Age]<35 THEN "30-34" ELSE "35+" END` |
| Tenure Years | `YEAR(TODAY()) - [JoiningYear]` |
| Left Company | `IF [LeaveOrNot]=1 THEN "Left" ELSE "Stayed" END` |

## 3. Worksheets

**Sheet 1 - Clustered column**  
*Question:* Which city loses the most people, and is it gender-driven?  
*Build:* Axis = City, Values = Attrition Rate, Legend = Gender  
*Mark type:* choose `Clustered` from the Marks card; add labels / colour as needed.

**Sheet 2 - Stacked bar**  
*Question:* Does education level affect attrition?  
*Build:* Axis = Education, Legend = Left Company, Values = Employees  
*Mark type:* choose `Stacked` from the Marks card; add labels / colour as needed.

**Sheet 3 - Line**  
*Question:* In which years did hiring peak?  
*Build:* Axis = JoiningYear, Values = Employees  
*Mark type:* choose `Line` from the Marks card; add labels / colour as needed.

**Sheet 4 - Donut**  
*Question:* How is the workforce spread across salary tiers?  
*Build:* Legend = PaymentTier, Values = Employees  
*Mark type:* choose `Donut` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
