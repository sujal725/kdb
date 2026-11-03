# Schema diagrams - Financials

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_SALES }o--|| DIM_DATE : "date_key"
    FACT_SALES }o--|| DIM_SEGMENT : "segment_key"
    FACT_SALES }o--|| DIM_COUNTRY : "country_key"
    FACT_SALES }o--|| DIM_PRODUCT : "product_key"
    FACT_SALES }o--|| DIM_DISCOUNT_BAND : "discount_band_key"
    FACT_SALES {
        BIGINT fact_sales_key PK
        INT date_key FK
        INT segment_key FK
        INT country_key FK
        INT product_key FK
        INT discount_band_key FK
        DECIMAL units_sold
        DECIMAL manufacturing_price
        DECIMAL sale_price
        DECIMAL gross_sales
        DECIMAL discounts
        DECIMAL sales
        DECIMAL cogs
        DECIMAL profit
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
    DIM_SEGMENT {
        INT segment_key PK
        VARCHAR segment
    }
    DIM_COUNTRY {
        INT country_key PK
        VARCHAR country
    }
    DIM_PRODUCT {
        INT product_key PK
        VARCHAR product
    }
    DIM_DISCOUNT_BAND {
        INT discount_band_key PK
        VARCHAR discount_band
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_SALES }o--|| DIM_SEGMENT : "segment_key"
    FACT_SALES }o--|| DIM_COUNTRY : "country_key"
    DIM_COUNTRY }o--|| DIM_REGION : "region_key"
    FACT_SALES }o--|| DIM_PRODUCT : "product_key"
    FACT_SALES }o--|| DIM_DISCOUNT_BAND : "discount_band_key"
    FACT_SALES }o--|| DIM_DATE : "date_key"
    DIM_DATE }o--|| DIM_MONTH : "month_key"
    DIM_MONTH }o--|| DIM_QUARTER : "quarter_key"
    DIM_QUARTER }o--|| DIM_YEAR : "year_key"
    FACT_SALES {
        BIGINT fact_sales_key PK
        INT date_key FK
        INT segment_key FK
        INT country_key FK
        INT product_key FK
        INT discount_band_key FK
        DECIMAL units_sold
        DECIMAL manufacturing_price
        DECIMAL sale_price
        DECIMAL gross_sales
        DECIMAL discounts
        DECIMAL sales
        DECIMAL cogs
        DECIMAL profit
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
    DIM_REGION {
        INT region_key PK
        VARCHAR region_name
    }
    DIM_SEGMENT {
        INT segment_key PK
        VARCHAR segment
    }
    DIM_COUNTRY {
        INT country_key PK
        VARCHAR country
        INT region_key FK
    }
    DIM_PRODUCT {
        INT product_key PK
        VARCHAR product
    }
    DIM_DISCOUNT_BAND {
        INT discount_band_key PK
        VARCHAR discount_band
    }
```
