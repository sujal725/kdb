# Tableau Public steps - Super_Market_Analysis

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `supermarket_sales.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Month | `DATENAME('month',[Date])` |
| Weekday | `DATENAME('weekday',[Date])` |
| Hour | `DATEPART("hour",[Time])` |
| Rating Band | `IF [Rating]<5 THEN "Low" ELSEIF [Rating]<8 THEN "Medium" ELSE "High" END` |

## 3. Worksheets

**Sheet 1 - Line**  
*Question:* Which branch/city grows fastest over the quarter?  
*Build:* Axis = Date, Values = Total Total, Legend = City  
*Mark type:* choose `Line` from the Marks card; add labels / colour as needed.

**Sheet 2 - Bar**  
*Question:* Which product line earns the most?  
*Build:* Axis = Product line, Values = Total gross income  
*Mark type:* choose `Bar` from the Marks card; add labels / colour as needed.

**Sheet 3 - Column**  
*Question:* What are the peak shopping hours?  
*Build:* Axis = Hour, Values = Invoices  
*Mark type:* choose `Column` from the Marks card; add labels / colour as needed.

**Sheet 4 - Donut**  
*Question:* Which payment method dominates?  
*Build:* Legend = Payment, Values = Invoices  
*Mark type:* choose `Donut` from the Marks card; add labels / colour as needed.

**Sheet 5 - Matrix**  
*Question:* Do members rate product lines differently?  
*Build:* Rows = Product line, Columns = Customer type, Values = Avg Rating  
*Mark type:* choose `Matrix` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
