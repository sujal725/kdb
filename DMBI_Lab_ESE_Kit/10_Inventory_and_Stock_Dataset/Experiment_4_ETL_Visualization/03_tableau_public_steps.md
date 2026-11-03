# Tableau Public steps - Inventory_and_Stock_Dataset

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `retail_store_inventory.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Year | `YEAR([Date])` |
| Month | `DATENAME('month',[Date])` |
| Revenue | `[Price]*[Units Sold]` |
| Stock Gap | `[Inventory Level]-[Units Sold]` |
| Stock Status | `IF [Inventory Level]<[Units Sold] THEN "Stock-out risk" ELSEIF [Inventory Level]>3*[Units Sold] THEN "Overstock" ELSE "Healthy" END` |

## 3. Worksheets

**Sheet 1 - Line**  
*Question:* How well does the forecast track actual demand?  
*Build:* Axis = Month, Values = Total Units Sold and Total Demand Forecast  
*Mark type:* choose `Line` from the Marks card; add labels / colour as needed.

**Sheet 2 - Clustered bar**  
*Question:* Which categories are over/under-stocked?  
*Build:* Axis = Category, Values = Total Inventory Level and Total Units Sold  
*Mark type:* choose `Clustered` from the Marks card; add labels / colour as needed.

**Sheet 3 - Stacked column**  
*Question:* Where are stock-out risks concentrated?  
*Build:* Axis = Region, Legend = Stock Status, Values = Row count  
*Mark type:* choose `Stacked` from the Marks card; add labels / colour as needed.

**Sheet 4 - Column**  
*Question:* How do season and weather change demand?  
*Build:* Axis = Seasonality, Values = Total Units Sold, Legend = Weather Condition  
*Mark type:* choose `Column` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
