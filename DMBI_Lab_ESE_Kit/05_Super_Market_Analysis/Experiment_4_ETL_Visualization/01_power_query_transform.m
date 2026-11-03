// ======================================================================
// POWER QUERY (M) SCRIPT - Super_Market_Analysis
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  supermarket_sales  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Super_Market_Analysis\supermarket_sales.csv"), [Delimiter=",", Columns=17, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"Invoice ID", type text}, {"Branch", type text}, {"City", type text}, {"Customer type", type text}, {"Gender", type text}, {"Product line", type text}, {"Unit price", type number}, {"Quantity", Int64.Type}, {"Tax 5%", type number}, {"Total", type number}, {"Date", type date}, {"Time", type time}, {"Payment", type text}, {"cogs", type number}, {"gross margin percentage", type number}, {"gross income", type number}, {"Rating", type number}}, "en-US"),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type", {{"Invoice ID", Text.Trim, type text}, {"Branch", Text.Trim, type text}, {"City", Text.Trim, type text}, {"Customer type", Text.Trim, type text}, {"Gender", Text.Trim, type text}, {"Product line", Text.Trim, type text}, {"Payment", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [Invoice ID] <> null),
    #"Added Month" = Table.AddColumn(#"Removed Null Keys", "Month", each Date.MonthName([Date]), type text),
    #"Added Weekday" = Table.AddColumn(#"Added Month", "Weekday", each Date.DayOfWeekName([Date]), type text),
    #"Added Hour" = Table.AddColumn(#"Added Weekday", "Hour", each Time.Hour([Time]), Int64.Type),
    #"Added Rating Band" = Table.AddColumn(#"Added Hour", "Rating Band", each if [Rating] < 5 then "Low" else if [Rating] < 8 then "Medium" else "High", type text)
in
    #"Added Rating Band"
