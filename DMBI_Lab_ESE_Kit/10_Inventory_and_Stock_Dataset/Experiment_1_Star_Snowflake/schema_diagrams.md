# Schema diagrams - Inventory_and_Stock_Dataset

Paste each block into https://mermaid.live or view it in VS Code/GitHub. For the lab record use the `.drawio` files.

## Star schema

```mermaid
erDiagram
    FACT_INVENTORY }o--|| DIM_DATE : "date_key"
    FACT_INVENTORY }o--|| DIM_STORE : "store_key"
    FACT_INVENTORY }o--|| DIM_PRODUCT : "product_key"
    FACT_INVENTORY }o--|| DIM_WEATHER : "weather_key"
    FACT_INVENTORY }o--|| DIM_SEASON : "season_key"
    FACT_INVENTORY {
        BIGINT fact_inventory_key PK
        INT date_key FK
        INT store_key FK
        INT product_key FK
        INT weather_key FK
        INT season_key FK
        INT inventory_level
        INT units_sold
        INT units_ordered
        DECIMAL demand_forecast
        DECIMAL price
        INT discount
        INT holiday_promotion
        DECIMAL competitor_pricing
        DECIMAL revenue
        INT stock_gap
        DOUBLE forecast_error
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
    DIM_STORE {
        INT store_key PK
        VARCHAR store_id
        VARCHAR region
    }
    DIM_PRODUCT {
        INT product_key PK
        VARCHAR product_id
        VARCHAR category
    }
    DIM_WEATHER {
        INT weather_key PK
        VARCHAR weather_condition
    }
    DIM_SEASON {
        INT season_key PK
        VARCHAR seasonality
    }
```

## Snowflake schema

```mermaid
erDiagram
    FACT_INVENTORY }o--|| DIM_STORE : "store_key"
    DIM_STORE }o--|| DIM_REGION : "region_key"
    FACT_INVENTORY }o--|| DIM_PRODUCT : "product_key"
    DIM_PRODUCT }o--|| DIM_CATEGORY : "category_key"
    FACT_INVENTORY }o--|| DIM_WEATHER : "weather_key"
    FACT_INVENTORY }o--|| DIM_SEASON : "season_key"
    FACT_INVENTORY }o--|| DIM_DATE : "date_key"
    DIM_DATE }o--|| DIM_MONTH : "month_key"
    DIM_MONTH }o--|| DIM_QUARTER : "quarter_key"
    DIM_QUARTER }o--|| DIM_YEAR : "year_key"
    FACT_INVENTORY {
        BIGINT fact_inventory_key PK
        INT date_key FK
        INT store_key FK
        INT product_key FK
        INT weather_key FK
        INT season_key FK
        INT inventory_level
        INT units_sold
        INT units_ordered
        DECIMAL demand_forecast
        DECIMAL price
        INT discount
        INT holiday_promotion
        DECIMAL competitor_pricing
        DECIMAL revenue
        INT stock_gap
        DOUBLE forecast_error
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
        VARCHAR region
    }
    DIM_CATEGORY {
        INT category_key PK
        VARCHAR category
    }
    DIM_STORE {
        INT store_key PK
        VARCHAR store_id
        INT region_key FK
    }
    DIM_PRODUCT {
        INT product_key PK
        VARCHAR product_id
        INT category_key FK
    }
    DIM_WEATHER {
        INT weather_key PK
        VARCHAR weather_condition
    }
    DIM_SEASON {
        INT season_key PK
        VARCHAR seasonality
    }
```
