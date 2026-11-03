# Online_Orders_Dataset

**Confidence in column list:** A - columns verified online

**Source:** Kaggle "Online Sales Dataset - Popular Marketplace Data" by shreyanshverma27 (240 rows, 9 columns). https://baselight.app/u/kaggle/dataset/shreyanshverma27_online_sales_dataset_popular_marketplace_data  (Alternative with the same theme: yusufdelikkaya "Online Sales Dataset" with InvoiceNo/StockCode/Description/Quantity/InvoiceDate/UnitPrice/CustomerID/Country/Discount/PaymentMethod/ShippingCost/Category/SalesChannel/ReturnStatus/ShipmentProvider/WarehouseLocation/OrderPriority.)

> WARNING: several public files share this name. Open your CSV, compare its header row with the table below. If it differs, follow `00_Common/If_Your_Columns_Differ.md`.

## Columns (9)

| # | Column | Type | Meaning |
|---|--------|------|---------|
| 1 | `Transaction ID` | bigint | Unique order id |
| 2 | `Date` | date | Order date |
| 3 | `Product Category` | text | Category (Electronics, Clothing, Books, Beauty, Sports, Home Appliances) |
| 4 | `Product Name` | text | Product name |
| 5 | `Units Sold` | int | Units in the order |
| 6 | `Unit Price` | decimal | Price per unit |
| 7 | `Total Revenue` | decimal | Quantity x Unit Price |
| 8 | `Region` | text | North America / Europe / Asia |
| 9 | `Payment Method` | text | Credit Card / PayPal / Debit Card |

## Notes

* Total Price = Quantity x Unit Price. Small dataset (240 rows): ideal for a quick demo.
* Region values: North America, Europe, Asia. Payment Method: Credit Card, PayPal, Debit Card.

## Folder map

```
11_Online_Orders_Dataset/
  Experiment_1_Star_Snowflake/   staging + star + snowflake SQL, diagrams
  Experiment_2_OLAP_OLTP/        OLTP + OLAP SQL
  Experiment_4_ETL_Visualization/ Power Query, DAX, Tableau, visuals
```

## Exam-day quick path

1. Put the CSV in `Music/Online_Orders_Dataset/` (as the exam instructions say) and note the exact path.
2. Experiment 1: edit the path in `01_staging_load.sql`, run files 01 -> 04 in order.
3. Experiment 2: run `01_oltp_operations.sql`, then `02_olap_operations.sql`.
4. Experiment 4: Power BI (paste the M script, add DAX, build visuals) or Tableau Public.

## Model at a glance

* Fact: `fact_orders` - One row per online order line.
* Dimensions: `dim_date`, `dim_product`, `dim_region`, `dim_payment_method`
* Main measure: Total Revenue; analysis dimensions: product_category, region, payment_method
