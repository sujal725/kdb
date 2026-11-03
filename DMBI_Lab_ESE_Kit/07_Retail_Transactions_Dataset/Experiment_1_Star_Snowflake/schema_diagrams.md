# Schema diagrams - Retail_Transactions_Dataset

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_TRANSACTIONS }o--|| DIM_DATE : "date_key"
    FACT_TRANSACTIONS }o--|| DIM_CUSTOMER : "customer_key"
    FACT_TRANSACTIONS }o--|| DIM_STORE : "store_key"
    FACT_TRANSACTIONS }o--|| DIM_PAYMENT_METHOD : "payment_method_key"
    FACT_TRANSACTIONS }o--|| DIM_SEASON : "season_key"
    FACT_TRANSACTIONS }o--|| DIM_PROMOTION : "promotion_key"
    FACT_TRANSACTIONS {
        BIGINT fact_transactions_key PK
        INT date_key FK
        INT customer_key FK
        INT store_key FK
        INT payment_method_key FK
        INT season_key FK
        INT promotion_key FK
        BIGINT transaction_id
        VARCHAR product
        INT total_items
        DECIMAL total_cost
        TINYINT discount_applied
        DECIMAL avg_item_cost
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
    DIM_CUSTOMER {
        INT customer_key PK
        VARCHAR customer_name
        VARCHAR customer_category
    }
    DIM_STORE {
        INT store_key PK
        VARCHAR city
        VARCHAR store_type
    }
    DIM_PAYMENT_METHOD {
        INT payment_method_key PK
        VARCHAR payment_method
    }
    DIM_SEASON {
        INT season_key PK
        VARCHAR season
    }
    DIM_PROMOTION {
        INT promotion_key PK
        VARCHAR promotion
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_TRANSACTIONS }o--|| DIM_CUSTOMER : "customer_key"
    DIM_CUSTOMER }o--|| DIM_CUSTOMER_CATEGORY : "customer_category_key"
    FACT_TRANSACTIONS }o--|| DIM_STORE : "store_key"
    DIM_STORE }o--|| DIM_CITY : "city_key"
    FACT_TRANSACTIONS }o--|| DIM_PAYMENT_METHOD : "payment_method_key"
    FACT_TRANSACTIONS }o--|| DIM_SEASON : "season_key"
    FACT_TRANSACTIONS }o--|| DIM_PROMOTION : "promotion_key"
    FACT_TRANSACTIONS }o--|| DIM_DATE : "date_key"
    DIM_DATE }o--|| DIM_MONTH : "month_key"
    DIM_MONTH }o--|| DIM_QUARTER : "quarter_key"
    DIM_QUARTER }o--|| DIM_YEAR : "year_key"
    FACT_TRANSACTIONS {
        BIGINT fact_transactions_key PK
        INT date_key FK
        INT customer_key FK
        INT store_key FK
        INT payment_method_key FK
        INT season_key FK
        INT promotion_key FK
        BIGINT transaction_id
        VARCHAR product
        INT total_items
        DECIMAL total_cost
        TINYINT discount_applied
        DECIMAL avg_item_cost
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
    DIM_CUSTOMER_CATEGORY {
        INT customer_category_key PK
        VARCHAR customer_category
    }
    DIM_CITY {
        INT city_key PK
        VARCHAR city
    }
    DIM_CUSTOMER {
        INT customer_key PK
        VARCHAR customer_name
        INT customer_category_key FK
    }
    DIM_STORE {
        INT store_key PK
        VARCHAR store_type
        INT city_key FK
    }
    DIM_PAYMENT_METHOD {
        INT payment_method_key PK
        VARCHAR payment_method
    }
    DIM_SEASON {
        INT season_key PK
        VARCHAR season
    }
    DIM_PROMOTION {
        INT promotion_key PK
        VARCHAR promotion
    }
```
