# Schema diagrams - Ecommerce_sales

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_SALES }o--|| DIM_DATE : "date_key"
    FACT_SALES }o--|| DIM_PRODUCT_CATEGORY : "product_category_key"
    FACT_SALES }o--|| DIM_CUSTOMER_SEGMENT : "customer_segment_key"
    FACT_SALES }o--|| DIM_DISCOUNT_BAND : "discount_band_key"
    FACT_SALES {
        BIGINT fact_sales_key PK
        INT date_key FK
        INT product_category_key FK
        INT customer_segment_key FK
        INT discount_band_key FK
        DECIMAL price
        DECIMAL discount
        DECIMAL marketing_spend
        INT units_sold
        DECIMAL gross_revenue
        DECIMAL net_revenue
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
    DIM_PRODUCT_CATEGORY {
        INT product_category_key PK
        VARCHAR product_category
    }
    DIM_CUSTOMER_SEGMENT {
        INT customer_segment_key PK
        VARCHAR customer_segment
    }
    DIM_DISCOUNT_BAND {
        INT discount_band_key PK
        VARCHAR discount_band
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_SALES }o--|| DIM_PRODUCT_CATEGORY : "product_category_key"
    FACT_SALES }o--|| DIM_CUSTOMER_SEGMENT : "customer_segment_key"
    FACT_SALES }o--|| DIM_DISCOUNT_BAND : "discount_band_key"
    FACT_SALES }o--|| DIM_DATE : "date_key"
    DIM_DATE }o--|| DIM_MONTH : "month_key"
    DIM_MONTH }o--|| DIM_QUARTER : "quarter_key"
    DIM_QUARTER }o--|| DIM_YEAR : "year_key"
    FACT_SALES {
        BIGINT fact_sales_key PK
        INT date_key FK
        INT product_category_key FK
        INT customer_segment_key FK
        INT discount_band_key FK
        DECIMAL price
        DECIMAL discount
        DECIMAL marketing_spend
        INT units_sold
        DECIMAL gross_revenue
        DECIMAL net_revenue
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
    DIM_CUSTOMER_SEGMENT {
        INT customer_segment_key PK
        VARCHAR customer_segment
    }
    DIM_DISCOUNT_BAND {
        INT discount_band_key PK
        VARCHAR discount_band
    }
```
