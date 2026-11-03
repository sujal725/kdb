# Employee

**Confidence in column list:** B - partly verified / several files share this name

**Source:** Kaggle "Employee Dataset" by tawfikelmetwally (4,653 rows, 9 columns). https://baselight.app/u/kaggle/dataset/tawfikelmetwally_employee_dataset

> WARNING: several public files share this name. Open your CSV, compare its header row with the table below. If it differs, follow `00_Common/If_Your_Columns_Differ.md`.

## Columns (9)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `Education` | text | Highest education (Bachelors / Masters / PHD) |
| 2 | `JoiningYear` | int | Year the employee joined |
| 3 | `City` | text | Work city (Bangalore, Pune, New Delhi) |
| 4 | `PaymentTier` | int | Salary tier (1 = highest, 3 = lowest) |
| 5 | `Age` | int | Age in years |
| 6 | `Gender` | text | Male / Female |
| 7 | `EverBenched` | text | Ever kept out of projects for a month or more (Yes/No) |
| 8 | `ExperienceInCurrentDomain` | int | Years of experience in current domain |
| 9 | `LeaveOrNot` | int | 1 = left the company, 0 = stayed |

## Notes

* No employee ID in the source: the fact table uses a surrogate key (fact_id).
* LeaveOrNot is the target flag: 1 = employee left. SUM(LeaveOrNot) = number of leavers.
* Name "Employee" is generic. If your file is different (e.g. Employee/HR all-in-one), follow the generic template in 00_Common.

## Folder map

```
02_Employee/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Employee/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_employee` - One row per employee record.
* Dimensions: `dim_education`, `dim_city`, `dim_joining_year`, `dim_payment_tier`, `dim_employee_profile`
* Main measure: Employees Left; analysis dimensions: city, education, payment_tier
