# Tableau Public steps - Retail_sales

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `retail_sales_dataset.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Year | `YEAR([Date])` |
| Month | `DATENAME('month',[Date])` |
| Age Group | `IF [Age]<25 THEN "18-24" ELSEIF [Age]<35 THEN "25-34" ELSEIF [Age]<45 THEN "35-44" ELSEIF [Age]<55 THEN "45-54" ELSE "55+" END` |
| Check Total | `[Quantity]*[Price per Unit]-[Total Amount]` |

## 3. Worksheets

**Sheet 1 - Line**  
*Question:* Which months are the sales peaks?  
*Build:* Axis = Month, Values = Total Total Amount  
*Mark type:* choose `Line` from the Marks card; add labels / colour as needed.

**Sheet 2 - Stacked column**  
*Question:* Which category does each gender prefer?  
*Build:* Axis = Product Category, Legend = Gender, Values = Total Total Amount  
*Mark type:* choose `Stacked` from the Marks card; add labels / colour as needed.

**Sheet 3 - Bar**  
*Question:* Which age group spends most per order?  
*Build:* Axis = Age Group, Values = Avg Order Value  
*Mark type:* choose `Bar` from the Marks card; add labels / colour as needed.

**Sheet 4 - Donut**  
*Question:* What is the unit share per category?  
*Build:* Legend = Product Category, Values = Quantity  
*Mark type:* choose `Donut` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
