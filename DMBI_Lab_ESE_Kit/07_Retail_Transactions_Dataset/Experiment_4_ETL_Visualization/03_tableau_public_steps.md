# Tableau Public steps - Retail_Transactions_Dataset

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `Retail_Transaction_Dataset.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

5. Right click **City** in the Data pane > **Geographic Role** > choose the matching role (City/Country) so maps work.

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Month | `DATENAME('month',[Date])` |
| Avg Item Cost | `SUM([Total_Cost])/SUM([Total_Items])` |
| Promotion Clean | `IFNULL([Promotion],"No promotion")` |
| Basket Size | `IF [Total_Items]<=3 THEN "Small" ELSEIF [Total_Items]<=7 THEN "Medium" ELSE "Large" END` |

## 3. Worksheets

**Sheet 1 - Clustered column**  
*Question:* Which store type sells most in which season?  
*Build:* Axis = Season, Values = Total Total_Cost, Legend = Store_Type  
*Mark type:* choose `Clustered` from the Marks card; add labels / colour as needed.

**Sheet 2 - Donut**  
*Question:* How do customers pay?  
*Build:* Legend = Payment_Method, Values = Transactions  
*Mark type:* choose `Donut` from the Marks card; add labels / colour as needed.

**Sheet 3 - Bar**  
*Question:* Which promotions lift basket value?  
*Build:* Axis = Promotion Clean, Values = Avg Basket Value  
*Mark type:* choose `Bar` from the Marks card; add labels / colour as needed.

**Sheet 4 - Matrix**  
*Question:* Which customer category matters in which city?  
*Build:* Rows = City, Columns = Customer_Category, Values = Total Total_Cost  
*Mark type:* choose `Matrix` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
