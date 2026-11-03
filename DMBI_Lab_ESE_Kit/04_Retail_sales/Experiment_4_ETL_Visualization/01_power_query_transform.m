// ======================================================================
// POWER QUERY (M) SCRIPT - Retail_sales
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  retail_sales_dataset  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Retail_sales\retail_sales_dataset.csv"), [Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"Transaction ID", Int64.Type}, {"Date", type date}, {"Customer ID", type text}, {"Gender", type text}, {"Age", Int64.Type}, {"Product Category", type text}, {"Quantity", Int64.Type}, {"Price per Unit", type number}, {"Total Amount", type number}}, "en-US"),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type", {{"Customer ID", Text.Trim, type text}, {"Gender", Text.Trim, type text}, {"Product Category", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [Transaction ID] <> null),
    #"Added Year" = Table.AddColumn(#"Removed Null Keys", "Year", each Date.Year([Date]), Int64.Type),
    #"Added Month" = Table.AddColumn(#"Added Year", "Month", each Date.MonthName([Date]), type text),
    #"Added Age Group" = Table.AddColumn(#"Added Month", "Age Group", each if [Age] < 25 then "18-24" else if [Age] < 35 then "25-34" else if [Age] < 45 then "35-44" else if [Age] < 55 then "45-54" else "55+", type text),
    #"Added Check Total" = Table.AddColumn(#"Added Age Group", "Check Total", each [Quantity] * [Price per Unit] - [Total Amount], type number)
in
    #"Added Check Total"
