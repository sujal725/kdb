# Schema diagrams - Banking_Customer_Dataset

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_BANK_CUSTOMER }o--|| DIM_CUSTOMER : "customer_key"
    FACT_BANK_CUSTOMER }o--|| DIM_GEOGRAPHY : "geography_key"
    FACT_BANK_CUSTOMER }o--|| DIM_CREDIT_BAND : "credit_band_key"
    FACT_BANK_CUSTOMER {
        BIGINT fact_bank_customer_key PK
        INT customer_key FK
        INT geography_key FK
        INT credit_band_key FK
        INT src_row_number
        INT credit_score
        INT age
        INT tenure
        DECIMAL balance
        INT num_of_products
        INT has_cr_card
        INT is_active_member
        DECIMAL estimated_salary
        INT exited
    }
    DIM_CUSTOMER {
        INT customer_key PK
        BIGINT customer_id
        VARCHAR surname
        VARCHAR gender
        VARCHAR age_group
    }
    DIM_GEOGRAPHY {
        INT geography_key PK
        VARCHAR geography
    }
    DIM_CREDIT_BAND {
        INT credit_band_key PK
        VARCHAR credit_band
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_BANK_CUSTOMER }o--|| DIM_CUSTOMER : "customer_key"
    DIM_CUSTOMER }o--|| DIM_GENDER : "gender_key"
    DIM_CUSTOMER }o--|| DIM_AGE_GROUP : "age_group_key"
    FACT_BANK_CUSTOMER }o--|| DIM_GEOGRAPHY : "geography_key"
    FACT_BANK_CUSTOMER }o--|| DIM_CREDIT_BAND : "credit_band_key"
    FACT_BANK_CUSTOMER {
        BIGINT fact_bank_customer_key PK
        INT customer_key FK
        INT geography_key FK
        INT credit_band_key FK
        INT src_row_number
        INT credit_score
        INT age
        INT tenure
        DECIMAL balance
        INT num_of_products
        INT has_cr_card
        INT is_active_member
        DECIMAL estimated_salary
        INT exited
    }
    DIM_GENDER {
        INT gender_key PK
        VARCHAR gender
    }
    DIM_AGE_GROUP {
        INT age_group_key PK
        VARCHAR age_group
    }
    DIM_CUSTOMER {
        INT customer_key PK
        BIGINT customer_id
        VARCHAR surname
        INT gender_key FK
        INT age_group_key FK
    }
    DIM_GEOGRAPHY {
        INT geography_key PK
        VARCHAR geography
    }
    DIM_CREDIT_BAND {
        INT credit_band_key PK
        VARCHAR credit_band
    }
```
