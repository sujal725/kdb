// ======================================================================
// POWER QUERY (M) SCRIPT - Online_Orders_Dataset
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  online_sales_data  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Online_Orders_Dataset\Online Sales Data.csv"), [Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"Transaction ID", Int64.Type}, {"Date", type date}, {"Product Category", type text}, {"Product Name", type text}, {"Units Sold", Int64.Type}, {"Unit Price", type number}, {"Total Revenue", type number}, {"Region", type text}, {"Payment Method", type text}}, "en-US"),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type", {{"Product Category", Text.Trim, type text}, {"Product Name", Text.Trim, type text}, {"Region", Text.Trim, type text}, {"Payment Method", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [Transaction ID] <> null),
    #"Added Year" = Table.AddColumn(#"Removed Null Keys", "Year", each Date.Year([Date]), Int64.Type),
    #"Added Month" = Table.AddColumn(#"Added Year", "Month", each Date.MonthName([Date]), type text),
    #"Added Weekday" = Table.AddColumn(#"Added Month", "Weekday", each Date.DayOfWeekName([Date]), type text),
    #"Added Price Check" = Table.AddColumn(#"Added Weekday", "Price Check", each [Units Sold] * [Unit Price] - [Total Revenue], type number)
in
    #"Added Price Check"
