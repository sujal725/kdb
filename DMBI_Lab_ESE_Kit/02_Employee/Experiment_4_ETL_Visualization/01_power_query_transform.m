// ======================================================================
// POWER QUERY (M) SCRIPT - Employee
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  Employee  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\Employee\Employee.csv"), [Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"Education", type text}, {"JoiningYear", Int64.Type}, {"City", type text}, {"PaymentTier", Int64.Type}, {"Age", Int64.Type}, {"Gender", type text}, {"EverBenched", type text}, {"ExperienceInCurrentDomain", Int64.Type}, {"LeaveOrNot", Int64.Type}}, "en-US"),
    #"Trimmed Text" = Table.TransformColumns(#"Changed Type", {{"Education", Text.Trim, type text}, {"City", Text.Trim, type text}, {"Gender", Text.Trim, type text}, {"EverBenched", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [Education] <> null and [City] <> null),
    #"Added Age Band" = Table.AddColumn(#"Removed Null Keys", "Age Band", each if [Age] < 25 then "Under 25" else if [Age] < 30 then "25-29" else if [Age] < 35 then "30-34" else "35+", type text),
    #"Added Tenure Years" = Table.AddColumn(#"Added Age Band", "Tenure Years", each Date.Year(DateTime.LocalNow()) - [JoiningYear], Int64.Type),
    #"Added Left Company" = Table.AddColumn(#"Added Tenure Years", "Left Company", each if [LeaveOrNot] = 1 then "Left" else "Stayed", type text)
in
    #"Added Left Company"
