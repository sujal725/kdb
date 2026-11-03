# HR_Analytics_Dataset

**Confidence in column list:** A - columns verified online

**Source:** Kaggle "HR Analytics Dataset" by saadharoon27 (1,480 rows, 38 columns; IBM HR attrition data plus EmpID, AgeGroup and SalarySlab). https://baselight.app/u/kaggle/dataset/saadharoon27_hr_analytics_dataset  (the plain IBM file has 35 columns - without EmpID, AgeGroup, SalarySlab)

## Columns (38)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `EmpID` | text | Employee id |
| 2 | `Age` | int | Age |
| 3 | `AgeGroup` | text | Age group label |
| 4 | `Attrition` | yes/no flag | Yes / No - did the employee leave |
| 5 | `BusinessTravel` | text | Non-Travel / Travel_Rarely / Travel_Frequently |
| 6 | `DailyRate` | int | Daily rate |
| 7 | `Department` | text | Sales / Research & Development / Human Resources |
| 8 | `DistanceFromHome` | int | Distance from home (miles) |
| 9 | `Education` | int | Education level 1-5 |
| 10 | `EducationField` | text | Field of education |
| 11 | `EmployeeCount` | int | Always 1 |
| 12 | `EmployeeNumber` | int | Employee number |
| 13 | `EnvironmentSatisfaction` | int | Rating 1-4 |
| 14 | `Gender` | text | Male / Female |
| 15 | `HourlyRate` | int | Hourly rate |
| 16 | `JobInvolvement` | int | Rating 1-4 |
| 17 | `JobLevel` | int | Job level 1-5 |
| 18 | `JobRole` | text | Job role |
| 19 | `JobSatisfaction` | int | Rating 1-4 |
| 20 | `MaritalStatus` | text | Single / Married / Divorced |
| 21 | `MonthlyIncome` | int | Monthly income |
| 22 | `SalarySlab` | text | Salary slab label |
| 23 | `MonthlyRate` | int | Monthly rate |
| 24 | `NumCompaniesWorked` | int | Companies worked for before |
| 25 | `Over18` | text | Always Y |
| 26 | `OverTime` | text | Yes / No |
| 27 | `PercentSalaryHike` | int | Last salary hike % |
| 28 | `PerformanceRating` | int | Rating 1-4 |
| 29 | `RelationshipSatisfaction` | int | Rating 1-4 |
| 30 | `StandardHours` | int | Always 80 |
| 31 | `StockOptionLevel` | int | Stock option level 0-3 |
| 32 | `TotalWorkingYears` | int | Total years worked |
| 33 | `TrainingTimesLastYear` | int | Trainings last year |
| 34 | `WorkLifeBalance` | int | Rating 1-4 |
| 35 | `YearsAtCompany` | int | Years at company |
| 36 | `YearsInCurrentRole` | int | Years in current role |
| 37 | `YearsSinceLastPromotion` | int | Years since last promotion |
| 38 | `YearsWithCurrManager` | int | Years with current manager |

## Notes

* EmployeeCount, EmployeeNumber, Over18 and StandardHours are constants/ids with no analytical value - they are loaded into staging but not into the fact table.
* Attrition (Yes/No) becomes attrition_flag (1/0) so SUM() = number of leavers and AVG() = attrition rate.
* If your file is the 35-column IBM version, delete EmpID/AgeGroup/SalarySlab from the dimension/ETL lines (marked in the SQL) or use the generic template.
* Satisfaction ratings are numeric 1-4 here. Some copies store them as text (Low/Medium/High) - then change those staging columns to VARCHAR.

## Folder map

```
09_HR_Analytics_Dataset/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/HR_Analytics_Dataset/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_employee_hr` - One row per employee.
* Dimensions: `dim_employee_demo`, `dim_education`, `dim_job`, `dim_work_profile`, `dim_salary_slab`
* Main measure: Monthly Income; analysis dimensions: department, job_role, gender
