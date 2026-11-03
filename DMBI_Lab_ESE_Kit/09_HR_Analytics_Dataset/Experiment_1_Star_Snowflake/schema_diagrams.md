# Schema diagrams - HR_Analytics_Dataset

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_EMPLOYEE_HR }o--|| DIM_EMPLOYEE_DEMO : "employee_demo_key"
    FACT_EMPLOYEE_HR }o--|| DIM_EDUCATION : "education_key"
    FACT_EMPLOYEE_HR }o--|| DIM_JOB : "job_key"
    FACT_EMPLOYEE_HR }o--|| DIM_WORK_PROFILE : "work_profile_key"
    FACT_EMPLOYEE_HR }o--|| DIM_SALARY_SLAB : "salary_slab_key"
    FACT_EMPLOYEE_HR {
        BIGINT fact_employee_hr_key PK
        INT employee_demo_key FK
        INT education_key FK
        INT job_key FK
        INT work_profile_key FK
        INT salary_slab_key FK
        VARCHAR emp_id
        INT age
        TINYINT attrition_flag
        INT daily_rate
        INT hourly_rate
        INT monthly_rate
        INT monthly_income
        INT distance_from_home
        INT num_companies_worked
        INT percent_salary_hike
        INT performance_rating
        INT environment_satisfaction
        INT job_involvement
        INT job_satisfaction
        INT relationship_satisfaction
        INT work_life_balance
        INT stock_option_level
        INT total_working_years
        INT training_times_last_year
        INT years_at_company
        INT years_in_current_role
        INT years_since_last_promotion
        INT years_with_curr_manager
    }
    DIM_EMPLOYEE_DEMO {
        INT employee_demo_key PK
        VARCHAR gender
        VARCHAR marital_status
        VARCHAR age_group
    }
    DIM_EDUCATION {
        INT education_key PK
        INT education
        VARCHAR education_field
    }
    DIM_JOB {
        INT job_key PK
        VARCHAR department
        VARCHAR job_role
        INT job_level
    }
    DIM_WORK_PROFILE {
        INT work_profile_key PK
        VARCHAR business_travel
        VARCHAR over_time
    }
    DIM_SALARY_SLAB {
        INT salary_slab_key PK
        VARCHAR salary_slab
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_EMPLOYEE_HR }o--|| DIM_EMPLOYEE_DEMO : "employee_demo_key"
    DIM_EMPLOYEE_DEMO }o--|| DIM_AGE_GROUP : "age_group_key"
    FACT_EMPLOYEE_HR }o--|| DIM_EDUCATION : "education_key"
    DIM_EDUCATION }o--|| DIM_EDUCATION_FIELD : "education_field_key"
    FACT_EMPLOYEE_HR }o--|| DIM_JOB : "job_key"
    DIM_JOB }o--|| DIM_DEPARTMENT : "department_key"
    FACT_EMPLOYEE_HR }o--|| DIM_WORK_PROFILE : "work_profile_key"
    FACT_EMPLOYEE_HR }o--|| DIM_SALARY_SLAB : "salary_slab_key"
    FACT_EMPLOYEE_HR {
        BIGINT fact_employee_hr_key PK
        INT employee_demo_key FK
        INT education_key FK
        INT job_key FK
        INT work_profile_key FK
        INT salary_slab_key FK
        VARCHAR emp_id
        INT age
        TINYINT attrition_flag
        INT daily_rate
        INT hourly_rate
        INT monthly_rate
        INT monthly_income
        INT distance_from_home
        INT num_companies_worked
        INT percent_salary_hike
        INT performance_rating
        INT environment_satisfaction
        INT job_involvement
        INT job_satisfaction
        INT relationship_satisfaction
        INT work_life_balance
        INT stock_option_level
        INT total_working_years
        INT training_times_last_year
        INT years_at_company
        INT years_in_current_role
        INT years_since_last_promotion
        INT years_with_curr_manager
    }
    DIM_AGE_GROUP {
        INT age_group_key PK
        VARCHAR age_group
    }
    DIM_EDUCATION_FIELD {
        INT education_field_key PK
        VARCHAR education_field
    }
    DIM_DEPARTMENT {
        INT department_key PK
        VARCHAR department
    }
    DIM_EMPLOYEE_DEMO {
        INT employee_demo_key PK
        VARCHAR gender
        VARCHAR marital_status
        INT age_group_key FK
    }
    DIM_EDUCATION {
        INT education_key PK
        INT education
        INT education_field_key FK
    }
    DIM_JOB {
        INT job_key PK
        VARCHAR job_role
        INT job_level
        INT department_key FK
    }
    DIM_WORK_PROFILE {
        INT work_profile_key PK
        VARCHAR business_travel
        VARCHAR over_time
    }
    DIM_SALARY_SLAB {
        INT salary_slab_key PK
        VARCHAR salary_slab
    }
```
