// ======================================================================
// POWER QUERY (M) SCRIPT - Ecommerce_sales
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  ecommerce_sales  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Ecommerce_sales\ecommerce_sales.csv"), [Delimiter=",", Columns=7, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"Date", type date}, {"Product_Category", type text}, {"Price", type number}, {"Discount", type number}, {"Customer_Segment", type text}, {"Marketing_Spend", type number}, {"Units_Sold", Int64.Type}}, "en-US"),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type", {{"Product_Category", Text.Trim, type text}, {"Customer_Segment", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [Product_Category] <> null),
    #"Added Year" = Table.AddColumn(#"Removed Null Keys", "Year", each Date.Year([Date]), Int64.Type),
    #"Added Month" = Table.AddColumn(#"Added Year", "Month", each Date.MonthName([Date]), type text),
    #"Added Net Revenue" = Table.AddColumn(#"Added Month", "Net Revenue", each [Price] * [Units_Sold] * (1 - [Discount] / 100), type number),
    #"Added Discount Band" = Table.AddColumn(#"Added Net Revenue", "Discount Band", each if [Discount] = 0 then "No discount" else if [Discount] < 10 then "Low" else if [Discount] < 20 then "Medium" else "High", type text)
in
    #"Added Discount Band"
