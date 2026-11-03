# Schema diagrams - Sales_Transaction_Dataset

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_SALES }o--|| DIM_DATE : "date_key"
    FACT_SALES }o--|| DIM_PRODUCT : "product_key"
    FACT_SALES }o--|| DIM_CUSTOMER : "customer_key"
    FACT_SALES {
        BIGINT fact_sales_key PK
        INT date_key FK
        INT product_key FK
        INT customer_key FK
        VARCHAR transaction_no
        DECIMAL price
        INT quantity
        DECIMAL sales_amount
        TINYINT is_cancellation
    }
    DIM_DATE {
        INT date_key PK
        DATE full_date
        TINYINT day_of_month
        VARCHAR day_name
        TINYINT is_weekend
        TINYINT month_num
        VARCHAR month_name
        TINYINT quarter_num
        SMALLINT year_num
    }
    DIM_PRODUCT {
        INT product_key PK
        VARCHAR product_no
        VARCHAR product_name
    }
    DIM_CUSTOMER {
        INT customer_key PK
        VARCHAR customer_no
        VARCHAR country
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_SALES }o--|| DIM_PRODUCT : "product_key"
    FACT_SALES }o--|| DIM_CUSTOMER : "customer_key"
    DIM_CUSTOMER }o--|| DIM_COUNTRY : "country_key"
    FACT_SALES }o--|| DIM_DATE : "date_key"
    DIM_DATE }o--|| DIM_MONTH : "month_key"
    DIM_MONTH }o--|| DIM_QUARTER : "quarter_key"
    DIM_QUARTER }o--|| DIM_YEAR : "year_key"
    FACT_SALES {
        BIGINT fact_sales_key PK
        INT date_key FK
        INT product_key FK
        INT customer_key FK
        VARCHAR transaction_no
        DECIMAL price
        INT quantity
        DECIMAL sales_amount
        TINYINT is_cancellation
    }
    DIM_DATE {
        INT date_key PK
        DATE full_date
        TINYINT day_of_month
        VARCHAR day_name
        TINYINT is_weekend
        INT month_key FK
    }
    DIM_MONTH {
        INT month_key PK
        TINYINT month_num
        VARCHAR month_name
        INT quarter_key FK
    }
    DIM_QUARTER {
        INT quarter_key PK
        TINYINT quarter_num
        INT year_key FK
    }
    DIM_YEAR {
        INT year_key PK
        SMALLINT year_num
    }
    DIM_COUNTRY {
        INT country_key PK
        VARCHAR country
    }
    DIM_PRODUCT {
        INT product_key PK
        VARCHAR product_no
        VARCHAR product_name
    }
    DIM_CUSTOMER {
        INT customer_key PK
        VARCHAR customer_no
        INT country_key FK
    }
```
