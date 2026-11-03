# Schema diagrams - Super_Market_Analysis

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_SALES }o--|| DIM_DATE : "date_key"
    FACT_SALES }o--|| DIM_BRANCH : "branch_key"
    FACT_SALES }o--|| DIM_CUSTOMER : "customer_key"
    FACT_SALES }o--|| DIM_PRODUCT_LINE : "product_line_key"
    FACT_SALES }o--|| DIM_PAYMENT : "payment_key"
    FACT_SALES {
        BIGINT fact_sales_key PK
        INT date_key FK
        INT branch_key FK
        INT customer_key FK
        INT product_line_key FK
        INT payment_key FK
        VARCHAR invoice_id
        TIME sale_time
        DECIMAL unit_price
        INT quantity
        DECIMAL tax_5
        DECIMAL total
        DECIMAL cogs
        DECIMAL gross_margin_percentage
        DECIMAL gross_income
        DECIMAL rating
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
    DIM_BRANCH {
        INT branch_key PK
        VARCHAR branch
        VARCHAR city
    }
    DIM_CUSTOMER {
        INT customer_key PK
        VARCHAR customer_type
        VARCHAR gender
    }
    DIM_PRODUCT_LINE {
        INT product_line_key PK
        VARCHAR product_line
    }
    DIM_PAYMENT {
        INT payment_key PK
        VARCHAR payment
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_SALES }o--|| DIM_BRANCH : "branch_key"
    DIM_BRANCH }o--|| DIM_CITY : "city_key"
    FACT_SALES }o--|| DIM_CUSTOMER : "customer_key"
    DIM_CUSTOMER }o--|| DIM_GENDER : "gender_key"
    FACT_SALES }o--|| DIM_PRODUCT_LINE : "product_line_key"
    FACT_SALES }o--|| DIM_PAYMENT : "payment_key"
    FACT_SALES }o--|| DIM_DATE : "date_key"
    DIM_DATE }o--|| DIM_MONTH : "month_key"
    DIM_MONTH }o--|| DIM_QUARTER : "quarter_key"
    DIM_QUARTER }o--|| DIM_YEAR : "year_key"
    FACT_SALES {
        BIGINT fact_sales_key PK
        INT date_key FK
        INT branch_key FK
        INT customer_key FK
        INT product_line_key FK
        INT payment_key FK
        VARCHAR invoice_id
        TIME sale_time
        DECIMAL unit_price
        INT quantity
        DECIMAL tax_5
        DECIMAL total
        DECIMAL cogs
        DECIMAL gross_margin_percentage
        DECIMAL gross_income
        DECIMAL rating
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
    DIM_CITY {
        INT city_key PK
        VARCHAR city
    }
    DIM_GENDER {
        INT gender_key PK
        VARCHAR gender
    }
    DIM_BRANCH {
        INT branch_key PK
        VARCHAR branch
        INT city_key FK
    }
    DIM_CUSTOMER {
        INT customer_key PK
        VARCHAR customer_type
        INT gender_key FK
    }
    DIM_PRODUCT_LINE {
        INT product_line_key PK
        VARCHAR product_line
    }
    DIM_PAYMENT {
        INT payment_key PK
        VARCHAR payment
    }
```
