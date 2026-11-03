# Schema diagrams - Employee

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_EMPLOYEE }o--|| DIM_EDUCATION : "education_key"
    FACT_EMPLOYEE }o--|| DIM_CITY : "city_key"
    FACT_EMPLOYEE }o--|| DIM_JOINING_YEAR : "joining_year_key"
    FACT_EMPLOYEE }o--|| DIM_PAYMENT_TIER : "payment_tier_key"
    FACT_EMPLOYEE }o--|| DIM_EMPLOYEE_PROFILE : "employee_profile_key"
    FACT_EMPLOYEE {
        BIGINT fact_employee_key PK
        INT education_key FK
        INT city_key FK
        INT joining_year_key FK
        INT payment_tier_key FK
        INT employee_profile_key FK
        INT age
        INT experience_in_current_domain
        INT leave_or_not
    }
    DIM_EDUCATION {
        INT education_key PK
        VARCHAR education
    }
    DIM_CITY {
        INT city_key PK
        VARCHAR city
    }
    DIM_JOINING_YEAR {
        INT joining_year_key PK
        INT joining_year
    }
    DIM_PAYMENT_TIER {
        INT payment_tier_key PK
        INT payment_tier
    }
    DIM_EMPLOYEE_PROFILE {
        INT employee_profile_key PK
        VARCHAR gender
        VARCHAR ever_benched
        VARCHAR age_band
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_EMPLOYEE }o--|| DIM_EDUCATION : "education_key"
    FACT_EMPLOYEE }o--|| DIM_CITY : "city_key"
    FACT_EMPLOYEE }o--|| DIM_JOINING_YEAR : "joining_year_key"
    FACT_EMPLOYEE }o--|| DIM_PAYMENT_TIER : "payment_tier_key"
    FACT_EMPLOYEE }o--|| DIM_EMPLOYEE_PROFILE : "employee_profile_key"
    DIM_EMPLOYEE_PROFILE }o--|| DIM_GENDER : "gender_key"
    DIM_EMPLOYEE_PROFILE }o--|| DIM_AGE_BAND : "age_band_key"
    FACT_EMPLOYEE {
        BIGINT fact_employee_key PK
        INT education_key FK
        INT city_key FK
        INT joining_year_key FK
        INT payment_tier_key FK
        INT employee_profile_key FK
        INT age
        INT experience_in_current_domain
        INT leave_or_not
    }
    DIM_GENDER {
        INT gender_key PK
        VARCHAR gender
    }
    DIM_AGE_BAND {
        INT age_band_key PK
        VARCHAR age_band
    }
    DIM_EDUCATION {
        INT education_key PK
        VARCHAR education
    }
    DIM_CITY {
        INT city_key PK
        VARCHAR city
    }
    DIM_JOINING_YEAR {
        INT joining_year_key PK
        INT joining_year
    }
    DIM_PAYMENT_TIER {
        INT payment_tier_key PK
        INT payment_tier
    }
    DIM_EMPLOYEE_PROFILE {
        INT employee_profile_key PK
        VARCHAR ever_benched
        INT gender_key FK
        INT age_band_key FK
    }
```
