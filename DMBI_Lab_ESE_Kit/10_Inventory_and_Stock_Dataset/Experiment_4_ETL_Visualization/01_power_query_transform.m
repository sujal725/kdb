// ======================================================================
// POWER QUERY (M) SCRIPT - Inventory_and_Stock_Dataset
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  retail_store_inventory  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Inventory_and_Stock_Dataset\retail_store_inventory.csv"), [Delimiter=",", Columns=15, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"Date", type date}, {"Store ID", type text}, {"Product ID", type text}, {"Category", type text}, {"Region", type text}, {"Inventory Level", Int64.Type}, {"Units Sold", Int64.Type}, {"Units Ordered", Int64.Type}, {"Demand Forecast", type number}, {"Price", type number}, {"Discount", Int64.Type}, {"Weather Condition", type text}, {"Holiday/Promotion", Int64.Type}, {"Competitor Pricing", type number}, {"Seasonality", type text}}, "en-US"),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type", {{"Store ID", Text.Trim, type text}, {"Product ID", Text.Trim, type text}, {"Category", Text.Trim, type text}, {"Region", Text.Trim, type text}, {"Weather Condition", Text.Trim, type text}, {"Seasonality", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [Store ID] <> null and [Product ID] <> null),
    #"Added Year" = Table.AddColumn(#"Removed Null Keys", "Year", each Date.Year([Date]), Int64.Type),
    #"Added Month" = Table.AddColumn(#"Added Year", "Month", each Date.MonthName([Date]), type text),
    #"Added Revenue" = Table.AddColumn(#"Added Month", "Revenue", each [Price] * [Units Sold], type number),
    #"Added Stock Gap" = Table.AddColumn(#"Added Revenue", "Stock Gap", each [Inventory Level] - [Units Sold], Int64.Type),
    #"Added Stock Status" = Table.AddColumn(#"Added Stock Gap", "Stock Status", each if [Inventory Level] < [Units Sold] then "Stock-out risk" else if [Inventory Level] > 3 * [Units Sold] then "Overstock" else "Healthy", type text)
in
    #"Added Stock Status"
