// ======================================================================
// POWER QUERY (M) SCRIPT - Retail_Transactions_Dataset
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  retail_transactions  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Retail_Transactions_Dataset\Retail_Transaction_Dataset.csv"), [Delimiter=",", Columns=13, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"Transaction_ID", Int64.Type}, {"Date", type datetime}, {"Customer_Name", type text}, {"Product", type text}, {"Total_Items", Int64.Type}, {"Total_Cost", type number}, {"Payment_Method", type text}, {"City", type text}, {"Store_Type", type text}, {"Discount_Applied", type text}, {"Customer_Category", type text}, {"Season", type text}, {"Promotion", type text}}, "en-US"),
    #"Date Only" = Table.TransformColumns(#"Changed Type", {{"Date", DateTime.Date, type date}}),
    #"Trimmed Text" = Table.TransformColumns(#"Date Only", {{"Customer_Name", Text.Trim, type text}, {"Product", Text.Trim, type text}, {"Payment_Method", Text.Trim, type text}, {"City", Text.Trim, type text}, {"Store_Type", Text.Trim, type text}, {"Customer_Category", Text.Trim, type text}, {"Season", Text.Trim, type text}, {"Promotion", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [Transaction_ID] <> null),
    #"Added Month" = Table.AddColumn(#"Removed Null Keys", "Month", each Date.MonthName([Date]), type text),
    #"Added Avg Item Cost" = Table.AddColumn(#"Added Month", "Avg Item Cost", each [Total_Cost] / [Total_Items], type number),
    #"Added Promotion Clean" = Table.AddColumn(#"Added Avg Item Cost", "Promotion Clean", each if [Promotion] = null then "No promotion" else [Promotion], type text),
    #"Added Basket Size" = Table.AddColumn(#"Added Promotion Clean", "Basket Size", each if [Total_Items] <= 3 then "Small" else if [Total_Items] <= 7 then "Medium" else "Large", type text)
in
    #"Added Basket Size"
