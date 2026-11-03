# Tableau Public steps - Sales_Transaction_Dataset

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `Sales Transaction v.4a.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

5. Right click **Country** in the Data pane > **Geographic Role** > choose the matching role (City/Country) so maps work.

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Year | `YEAR([Date])` |
| Month | `DATENAME('month',[Date])` |
| Sales Amount | `[Price]*[Quantity]` |
| Is Cancellation | `IF LEFT([TransactionNo],1)="C" THEN 1 ELSE 0 END` |

## 3. Worksheets

**Sheet 1 - Line**  
*Question:* How does revenue trend over the year (seasonality)?  
*Build:* Axis = Month, Values = Total Sales Amount  
*Mark type:* choose `Line` from the Marks card; add labels / colour as needed.

**Sheet 2 - Filled map**  
*Question:* Which countries buy most?  
*Build:* Location = Country, Values = Total Sales Amount  
*Mark type:* choose `Filled` from the Marks card; add labels / colour as needed.

**Sheet 3 - Bar (Top N = 10)**  
*Question:* Which products sell the most units?  
*Build:* Axis = ProductName, Values = Total Quantity  
*Mark type:* choose `Bar` from the Marks card; add labels / colour as needed.

**Sheet 4 - Card**  
*Question:* What share of lines are cancellations?  
*Build:* Cancellation Rate  
*Mark type:* choose `Card` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
