// ======================================================================
// POWER QUERY (M) SCRIPT - Financials
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  Financials  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Financials\Financials.csv"), [Delimiter=",", Columns=16, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Cleaned Currency" = Table.TransformColumns(#"Promoted Headers", {{"Units Sold", each try Number.FromText(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.From(_), "$", ""), ",", ""), "(", "-"), ")", "")) otherwise null, type number}, {"Manufacturing Price", each try Number.FromText(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.From(_), "$", ""), ",", ""), "(", "-"), ")", "")) otherwise null, type number}, {"Sale Price", each try Number.FromText(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.From(_), "$", ""), ",", ""), "(", "-"), ")", "")) otherwise null, type number}, {"Gross Sales", each try Number.FromText(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.From(_), "$", ""), ",", ""), "(", "-"), ")", "")) otherwise null, type number}, {"Discounts", each try Number.FromText(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.From(_), "$", ""), ",", ""), "(", "-"), ")", "")) otherwise null, type number}, {"Sales", each try Number.FromText(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.From(_), "$", ""), ",", ""), "(", "-"), ")", "")) otherwise null, type number}, {"COGS", each try Number.FromText(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.From(_), "$", ""), ",", ""), "(", "-"), ")", "")) otherwise null, type number}, {"Profit", each try Number.FromText(Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.From(_), "$", ""), ",", ""), "(", "-"), ")", "")) otherwise null, type number}}),
    #"Fixed Year and Month" = Table.TransformColumns(#"Cleaned Currency", {{"Year", each Number.From(Text.Replace(Text.From(_), ",", "")), Int64.Type}, {"Month Number", each Number.From(_), Int64.Type}}),
    #"Rebuilt Date" = Table.AddColumn(#"Fixed Year and Month", "Date New", each #date([Year], [Month Number], 1), type date),
    #"Removed Old Date" = Table.RemoveColumns(#"Rebuilt Date", {"Date"}),
    #"Renamed Date" = Table.RenameColumns(#"Removed Old Date", {{"Date New", "Date"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Date", {{"Segment", type text}, {"Country", type text}, {"Product", type text}, {"Discount Band", type text}, {"Month Name", type text}}, "en-US"),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type", {{"Segment", Text.Trim, type text}, {"Country", Text.Trim, type text}, {"Product", Text.Trim, type text}, {"Discount Band", Text.Trim, type text}, {"Month Name", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [Segment] <> null and [Country] <> null),
    #"Added Profit Margin" = Table.AddColumn(#"Removed Null Keys", "Profit Margin", each [Profit] / [Sales], type number),
    #"Added Discount %" = Table.AddColumn(#"Added Profit Margin", "Discount %", each [Discounts] / [Gross Sales], type number),
    #"Added Month Start" = Table.AddColumn(#"Added Discount %", "Month Start", each Date.StartOfMonth([Date]), type date)
in
    #"Added Month Start"
