# Tableau Public steps - Ecommerce_sales

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `ecommerce_sales.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Year | `YEAR([Date])` |
| Month | `DATENAME('month',[Date])` |
| Net Revenue | `[Price]*[Units_Sold]*(1-[Discount]/100)` |
| Discount Band | `IF [Discount]=0 THEN "No discount" ELSEIF [Discount]<10 THEN "Low" ELSEIF [Discount]<20 THEN "Medium" ELSE "High" END` |

## 3. Worksheets

**Sheet 1 - Scatter**  
*Question:* Does a bigger discount really sell more units?  
*Build:* X = Avg Discount, Y = Units_Sold, Details = Product_Category  
*Mark type:* choose `Scatter` from the Marks card; add labels / colour as needed.

**Sheet 2 - Line**  
*Question:* Which segment drives the seasonal peaks?  
*Build:* Axis = Month, Values = Net Revenue, Legend = Customer_Segment  
*Mark type:* choose `Line` from the Marks card; add labels / colour as needed.

**Sheet 3 - Clustered bar**  
*Question:* Which category gives the best return on marketing spend?  
*Build:* Axis = Product_Category, Values = Marketing ROI  
*Mark type:* choose `Clustered` from the Marks card; add labels / colour as needed.

**Sheet 4 - Matrix / heat map**  
*Question:* Which discount band works for which category?  
*Build:* Rows = Product_Category, Columns = Discount Band, Values = Units_Sold  
*Mark type:* choose `Matrix` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
