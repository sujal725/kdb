# Tableau Public steps - Online_Orders_Dataset

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `Online Sales Data.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Year | `YEAR([Date])` |
| Month | `DATENAME('month',[Date])` |
| Weekday | `DATENAME('weekday',[Date])` |
| Price Check | `[Units Sold]*[Unit Price]-[Total Revenue]` |

## 3. Worksheets

**Sheet 1 - Line**  
*Question:* What is the revenue trend over time?  
*Build:* Axis = Date (Month), Values = Total Total Revenue  
*Mark type:* choose `Line` from the Marks card; add labels / colour as needed.

**Sheet 2 - Stacked column**  
*Question:* Which category sells where?  
*Build:* Axis = Product Category, Legend = Region, Values = Total Total Revenue  
*Mark type:* choose `Stacked` from the Marks card; add labels / colour as needed.

**Sheet 3 - Donut**  
*Question:* Which payment method is most popular?  
*Build:* Legend = Payment Method, Values = Orders  
*Mark type:* choose `Donut` from the Marks card; add labels / colour as needed.

**Sheet 4 - Bar (Top N = 5)**  
*Question:* What are the best-selling products?  
*Build:* Axis = Product Name, Values = Total Total Revenue  
*Mark type:* choose `Bar` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
