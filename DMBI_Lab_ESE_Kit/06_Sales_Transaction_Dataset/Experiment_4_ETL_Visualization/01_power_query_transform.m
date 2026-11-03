// ======================================================================
// POWER QUERY (M) SCRIPT - Sales_Transaction_Dataset
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  sales_transaction  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Sales_Transaction_Dataset\Sales Transaction v.4a.csv"), [Delimiter=",", Columns=8, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"TransactionNo", type text}, {"Date", type date}, {"ProductNo", type text}, {"ProductName", type text}, {"Price", type number}, {"Quantity", Int64.Type}, {"CustomerNo", type text}, {"Country", type text}}, "en-US"),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type", {{"TransactionNo", Text.Trim, type text}, {"ProductNo", Text.Trim, type text}, {"ProductName", Text.Trim, type text}, {"CustomerNo", Text.Trim, type text}, {"Country", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [TransactionNo] <> null),
    #"Added Year" = Table.AddColumn(#"Removed Null Keys", "Year", each Date.Year([Date]), Int64.Type),
    #"Added Month" = Table.AddColumn(#"Added Year", "Month", each Date.MonthName([Date]), type text),
    #"Added Sales Amount" = Table.AddColumn(#"Added Month", "Sales Amount", each [Price] * [Quantity], type number),
    #"Added Is Cancellation" = Table.AddColumn(#"Added Sales Amount", "Is Cancellation", each if Text.StartsWith([TransactionNo], "C") then 1 else 0, Int64.Type)
in
    #"Added Is Cancellation"
