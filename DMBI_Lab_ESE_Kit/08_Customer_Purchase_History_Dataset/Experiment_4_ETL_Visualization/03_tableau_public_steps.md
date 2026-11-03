# Tableau Public steps - Customer_Purchase_History_Dataset

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `Customer Purchasing Behaviors.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Age Group | `IF [age]<25 THEN "18-24" ELSEIF [age]<35 THEN "25-34" ELSEIF [age]<45 THEN "35-44" ELSEIF [age]<55 THEN "45-54" ELSE "55+" END` |
| Income Band | `IF [annual_income]<40000 THEN "Below 40k" ELSEIF [annual_income]<60000 THEN "40k-59k" ELSEIF [annual_income]<80000 THEN "60k-79k" ELSE "80k+" END` |
| Spend to Income | `[purchase_amount]/[annual_income]` |

## 3. Worksheets

**Sheet 1 - Scatter**  
*Question:* Does higher income mean higher spend?  
*Build:* X = annual_income, Y = purchase_amount, Legend = region  
*Mark type:* choose `Scatter` from the Marks card; add labels / colour as needed.

**Sheet 2 - Column**  
*Question:* Which age group spends most?  
*Build:* Axis = Age Group, Values = Spend per Customer  
*Mark type:* choose `Column` from the Marks card; add labels / colour as needed.

**Sheet 3 - Map / bar**  
*Question:* Which region contributes most?  
*Build:* Axis = region, Values = Total purchase_amount  
*Mark type:* choose `Map` from the Marks card; add labels / colour as needed.

**Sheet 4 - Scatter**  
*Question:* Are loyal customers more frequent buyers?  
*Build:* X = loyalty_score, Y = purchase_frequency  
*Mark type:* choose `Scatter` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
