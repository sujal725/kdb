// ======================================================================
// POWER QUERY (M) SCRIPT - HR_Analytics_Dataset
// Power BI Desktop > Home > Transform data > Home > Advanced Editor > delete everything > paste this > Done.
// 1) Edit the path in the first step.  2) Rename the query to  hr_analytics  (right-click it in the Queries pane) so the DAX file works.
// ======================================================================
let
    Source = Csv.Document(File.Contents("C:\Users\YOUR_USER\Music\HR_Analytics_Dataset\HR_Analytics.csv"), [Delimiter=",", Columns=38, Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers", {{"EmpID", type text}, {"Age", Int64.Type}, {"AgeGroup", type text}, {"Attrition", type text}, {"BusinessTravel", type text}, {"DailyRate", Int64.Type}, {"Department", type text}, {"DistanceFromHome", Int64.Type}, {"Education", Int64.Type}, {"EducationField", type text}, {"EmployeeCount", Int64.Type}, {"EmployeeNumber", Int64.Type}, {"EnvironmentSatisfaction", Int64.Type}, {"Gender", type text}, {"HourlyRate", Int64.Type}, {"JobInvolvement", Int64.Type}, {"JobLevel", Int64.Type}, {"JobRole", type text}, {"JobSatisfaction", Int64.Type}, {"MaritalStatus", type text}, {"MonthlyIncome", Int64.Type}, {"SalarySlab", type text}, {"MonthlyRate", Int64.Type}, {"NumCompaniesWorked", Int64.Type}, {"Over18", type text}, {"OverTime", type text}, {"PercentSalaryHike", Int64.Type}, {"PerformanceRating", Int64.Type}, {"RelationshipSatisfaction", Int64.Type}, {"StandardHours", Int64.Type}, {"StockOptionLevel", Int64.Type}, {"TotalWorkingYears", Int64.Type}, {"TrainingTimesLastYear", Int64.Type}, {"WorkLifeBalance", Int64.Type}, {"YearsAtCompany", Int64.Type}, {"YearsInCurrentRole", Int64.Type}, {"YearsSinceLastPromotion", Int64.Type}, {"YearsWithCurrManager", Int64.Type}}, "en-US"),
    #"Removed Constant Columns" = Table.RemoveColumns(#"Changed Type", {"EmployeeCount", "EmployeeNumber", "Over18", "StandardHours"}),
    #"Trimmed Text" = Table.TransformColumns(#"Removed Constant Columns", {{"EmpID", Text.Trim, type text}, {"AgeGroup", Text.Trim, type text}, {"BusinessTravel", Text.Trim, type text}, {"Department", Text.Trim, type text}, {"EducationField", Text.Trim, type text}, {"Gender", Text.Trim, type text}, {"JobRole", Text.Trim, type text}, {"MaritalStatus", Text.Trim, type text}, {"SalarySlab", Text.Trim, type text}, {"OverTime", Text.Trim, type text}}),
    #"Removed Duplicates" = Table.Distinct(#"Trimmed Text"),
    #"Removed Null Keys" = Table.SelectRows(#"Removed Duplicates", each [EmpID] <> null),
    #"Added Attrition Flag" = Table.AddColumn(#"Removed Null Keys", "Attrition Flag", each if [Attrition] = "Yes" then 1 else 0, Int64.Type),
    #"Added Income Slab" = Table.AddColumn(#"Added Attrition Flag", "Income Slab", each if [MonthlyIncome] < 3000 then "Low" else if [MonthlyIncome] < 6000 then "Medium" else if [MonthlyIncome] < 10000 then "High" else "Very High", type text),
    #"Added Tenure Band" = Table.AddColumn(#"Added Income Slab", "Tenure Band", each if [YearsAtCompany] < 2 then "0-1 yrs" else if [YearsAtCompany] < 5 then "2-4 yrs" else if [YearsAtCompany] < 10 then "5-9 yrs" else "10+ yrs", type text)
in
    #"Added Tenure Band"
