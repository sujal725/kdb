// ======================================================================
// POWER QUERY (M) SCRIPT - Banking_Customer_Dataset
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  churn_modelling  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Banking_Customer_Dataset\Churn_Modelling.csv"), [Delimiter=",", Columns=14, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"RowNumber", Int64.Type}, {"CustomerId", Int64.Type}, {"Surname", type text}, {"CreditScore", Int64.Type}, {"Geography", type text}, {"Gender", type text}, {"Age", Int64.Type}, {"Tenure", Int64.Type}, {"Balance", type number}, {"NumOfProducts", Int64.Type}, {"HasCrCard", Int64.Type}, {"IsActiveMember", Int64.Type}, {"EstimatedSalary", type number}, {"Exited", Int64.Type}}, "en-US"),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type", {{"Surname", Text.Trim, type text}, {"Geography", Text.Trim, type text}, {"Gender", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [CustomerId] <> null),
    #"Added Age Group" = Table.AddColumn(#"Removed Null Keys", "Age Group", each if [Age] < 25 then "18-24" else if [Age] < 35 then "25-34" else if [Age] < 45 then "35-44" else if [Age] < 55 then "45-54" else "55+", type text),
    #"Added Credit Band" = Table.AddColumn(#"Added Age Group", "Credit Band", each if [CreditScore] < 580 then "Poor" else if [CreditScore] < 670 then "Fair" else if [CreditScore] < 740 then "Good" else if [CreditScore] < 800 then "Very Good" else "Excellent", type text),
    #"Added Churn Status" = Table.AddColumn(#"Added Credit Band", "Churn Status", each if [Exited] = 1 then "Churned" else "Retained", type text),
    #"Added Zero Balance" = Table.AddColumn(#"Added Churn Status", "Zero Balance", each if [Balance] = 0 then "Zero balance" else "Has balance", type text)
in
    #"Added Zero Balance"
