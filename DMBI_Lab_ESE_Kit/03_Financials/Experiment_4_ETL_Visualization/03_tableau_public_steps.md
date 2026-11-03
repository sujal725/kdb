# Tableau Public steps - Financials

> Tableau Public connects to files only (CSV / Excel), not to MySQL. Use the original CSV.

## 1. Connect and clean (Extract + Transform)

1. Open Tableau Public > **Connect > Text file** > pick `Financials.csv`.
2. On the Data Source page: click the type icon above each column and set types (Date, Number (decimal/whole), String).
3. Use **Data Interpreter** if the file has odd headers. Hide unused columns (right click > Hide). Rename columns if needed.
4. Switch to a sheet (bottom-left).

5. Right click **Country** in the Data pane > **Geographic Role** > choose the matching role (City/Country) so maps work.

## 2. Calculated fields (Analysis > Create Calculated Field)

| Name | Formula |
|---|---|
| Profit Margin | `SUM([Profit])/SUM([Sales])` |
| Discount % | `SUM([Discounts])/SUM([Gross Sales])` |
| Month Start | `DATETRUNC("month",[Date])` |

## 3. Worksheets

**Sheet 1 - Filled map**  
*Question:* Which countries are the biggest markets?  
*Build:* Location = Country, Size/Colour = Total Sales  
*Mark type:* choose `Filled` from the Marks card; add labels / colour as needed.

**Sheet 2 - Clustered column**  
*Question:* Which segment is most profitable?  
*Build:* Axis = Segment, Values = Total Sales and Total Profit  
*Mark type:* choose `Clustered` from the Marks card; add labels / colour as needed.

**Sheet 3 - Waterfall**  
*Question:* Which products create or destroy profit?  
*Build:* Category = Product, Values = Total Profit  
*Mark type:* choose `Waterfall` from the Marks card; add labels / colour as needed.

**Sheet 4 - Line**  
*Question:* What is the monthly sales trend?  
*Build:* Axis = Date (Year > Month), Values = Total Sales, Legend = Segment  
*Mark type:* choose `Line` from the Marks card; add labels / colour as needed.

**Sheet 5 - Scatter**  
*Question:* Do higher discounts erode margins?  
*Build:* X = Discount Rate, Y = Profit Margin %, Details = Product  
*Mark type:* choose `Scatter` from the Marks card; add labels / colour as needed.

## 4. Dashboard

1. Dashboard > New Dashboard > size *Automatic*.
2. Drag the sheets in (KPIs/summary on top, trends in the middle, breakdowns below).
3. Add a filter: sheet menu > **Use as Filter**, or Add Filter for the main categorical field; show it as a drop-down.
4. Add a title and short text box with 2-3 insights.
5. File > Save to Tableau Public (needs a free account) or File > Export as Image/PDF for the lab record.
