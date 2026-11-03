// ======================================================================
// POWER QUERY (M) SCRIPT - Customer_Purchase_History_Dataset
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  customer_purchasing_behaviors  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Customer_Purchase_History_Dataset\Customer Purchasing Behaviors.csv"), [Delimiter=",", Columns=7, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"user_id", Int64.Type}, {"age", Int64.Type}, {"annual_income", type number}, {"purchase_amount", type number}, {"loyalty_score", type number}, {"region", type text}, {"purchase_frequency", Int64.Type}}, "en-US"),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type", {{"region", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [user_id] <> null),
    #"Added Age Group" = Table.AddColumn(#"Removed Null Keys", "Age Group", each if [age] < 25 then "18-24" else if [age] < 35 then "25-34" else if [age] < 45 then "35-44" else if [age] < 55 then "45-54" else "55+", type text),
    #"Added Income Band" = Table.AddColumn(#"Added Age Group", "Income Band", each if [annual_income] < 40000 then "Below 40k" else if [annual_income] < 60000 then "40k-59k" else if [annual_income] < 80000 then "60k-79k" else "80k+", type text),
    #"Added Spend to Income" = Table.AddColumn(#"Added Income Band", "Spend to Income", each [purchase_amount] / [annual_income], type number)
in
    #"Added Spend to Income"
