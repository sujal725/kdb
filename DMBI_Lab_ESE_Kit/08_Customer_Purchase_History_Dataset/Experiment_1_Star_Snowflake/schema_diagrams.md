# Schema diagrams - Customer_Purchase_History_Dataset

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_CUSTOMER_PURCHASE }o--|| DIM_REGION : "region_key"
    FACT_CUSTOMER_PURCHASE }o--|| DIM_DEMOGRAPHIC : "demographic_key"
    FACT_CUSTOMER_PURCHASE {
        BIGINT fact_customer_purchase_key PK
        INT region_key FK
        INT demographic_key FK
        INT user_id
        INT age
        DECIMAL annual_income
        DECIMAL purchase_amount
        DECIMAL loyalty_score
        INT purchase_frequency
    }
    DIM_REGION {
        INT region_key PK
        VARCHAR region
    }
    DIM_DEMOGRAPHIC {
        INT demographic_key PK
        VARCHAR age_group
        VARCHAR income_band
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_CUSTOMER_PURCHASE }o--|| DIM_REGION : "region_key"
    FACT_CUSTOMER_PURCHASE }o--|| DIM_DEMOGRAPHIC : "demographic_key"
    DIM_DEMOGRAPHIC }o--|| DIM_AGE_GROUP : "age_group_key"
    DIM_DEMOGRAPHIC }o--|| DIM_INCOME_BAND : "income_band_key"
    FACT_CUSTOMER_PURCHASE {
        BIGINT fact_customer_purchase_key PK
        INT region_key FK
        INT demographic_key FK
        INT user_id
        INT age
        DECIMAL annual_income
        DECIMAL purchase_amount
        DECIMAL loyalty_score
        INT purchase_frequency
    }
    DIM_AGE_GROUP {
        INT age_group_key PK
        VARCHAR age_group
    }
    DIM_INCOME_BAND {
        INT income_band_key PK
        VARCHAR income_band
    }
    DIM_REGION {
        INT region_key PK
        VARCHAR region
    }
    DIM_DEMOGRAPHIC {
        INT demographic_key PK
        INT age_group_key FK
        INT income_band_key FK
    }
```
