# Schema diagrams - Online_Orders_Dataset

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_ORDERS }o--|| DIM_DATE : "date_key"
    FACT_ORDERS }o--|| DIM_PRODUCT : "product_key"
    FACT_ORDERS }o--|| DIM_REGION : "region_key"
    FACT_ORDERS }o--|| DIM_PAYMENT_METHOD : "payment_method_key"
    FACT_ORDERS {
        BIGINT fact_orders_key PK
        INT date_key FK
        INT product_key FK
        INT region_key FK
        INT payment_method_key FK
        BIGINT transaction_id
        INT units_sold
        DECIMAL unit_price
        DECIMAL total_revenue
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
        VARCHAR product_name
        VARCHAR product_category
    }
    DIM_REGION {
        INT region_key PK
        VARCHAR region
    }
    DIM_PAYMENT_METHOD {
        INT payment_method_key PK
        VARCHAR payment_method
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_ORDERS }o--|| DIM_PRODUCT : "product_key"
    DIM_PRODUCT }o--|| DIM_PRODUCT_CATEGORY : "product_category_key"
    FACT_ORDERS }o--|| DIM_REGION : "region_key"
    FACT_ORDERS }o--|| DIM_PAYMENT_METHOD : "payment_method_key"
    FACT_ORDERS }o--|| DIM_DATE : "date_key"
    DIM_DATE }o--|| DIM_MONTH : "month_key"
    DIM_MONTH }o--|| DIM_QUARTER : "quarter_key"
    DIM_QUARTER }o--|| DIM_YEAR : "year_key"
    FACT_ORDERS {
        BIGINT fact_orders_key PK
        INT date_key FK
        INT product_key FK
        INT region_key FK
        INT payment_method_key FK
        BIGINT transaction_id
        INT units_sold
        DECIMAL unit_price
        DECIMAL total_revenue
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
    DIM_PRODUCT_CATEGORY {
        INT product_category_key PK
        VARCHAR product_category
    }
    DIM_PRODUCT {
        INT product_key PK
        VARCHAR product_name
        INT product_category_key FK
    }
    DIM_REGION {
        INT region_key PK
        VARCHAR region
    }
    DIM_PAYMENT_METHOD {
        INT payment_method_key PK
        VARCHAR payment_method
    }
```
