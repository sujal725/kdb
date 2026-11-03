-- ============================================================
-- DMBI EXPERIMENT 2
-- AIM: To implement OLAP (Online Analytical Processing) and
--      OLTP (Online Transaction Processing) operations using
--      SQL queries and Data Warehouse concepts.
-- SOFTWARE: Windows, MySQL Workbench
--
-- NOTE:
-- 1. This script follows the sales dataset and operations
--    given in the experiment document.
-- 2. OLTP and OLAP tables are kept in the BI_Sales database.
-- 3. Run this script once. To rerun, drop the database first.
-- ============================================================


-- ============================================================
-- PART 1: CREATE DATABASE
-- ============================================================

CREATE DATABASE BI_Sales;
USE BI_Sales;


-- ============================================================
-- PART 2: OLTP IMPLEMENTATION
-- OLTP stores day-to-day transaction data in normalized tables.
-- ============================================================


-- Create Customer table.
CREATE TABLE Customer (
    Customer_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50)
);


-- Create Product table.
CREATE TABLE Product (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(50),
    Category VARCHAR(50),
    Price DECIMAL(10,2)
);


-- Create Sales Transaction table.
CREATE TABLE Sales_Transaction (
    Transaction_ID INT PRIMARY KEY,
    Customer_ID INT,
    Product_ID INT,
    Sale_Date DATE,
    Quantity INT,
    Amount DECIMAL(10,2),

    FOREIGN KEY (Customer_ID)
        REFERENCES Customer(Customer_ID),

    FOREIGN KEY (Product_ID)
        REFERENCES Product(Product_ID)
);


-- ============================================================
-- PART 3: INSERT SAMPLE DATA
-- ============================================================


-- Insert Customers.
INSERT INTO Customer VALUES
(1, 'Amit', 'Pune', 'Maharashtra'),
(2, 'Sneha', 'Mumbai', 'Maharashtra'),
(3, 'Rahul', 'Nashik', 'Maharashtra'),
(4, 'Priya', 'Nagpur', 'Maharashtra'),
(5, 'Rohan', 'Pune', 'Maharashtra');


-- Insert Products.
INSERT INTO Product VALUES
(101, 'Laptop', 'Electronics', 60000),
(102, 'Mobile', 'Electronics', 30000),
(103, 'Keyboard', 'Accessories', 1500),
(104, 'Mouse', 'Accessories', 800),
(105, 'Monitor', 'Electronics', 15000);


-- Insert Sales Transactions.
INSERT INTO Sales_Transaction VALUES
(1001, 1, 101, '2026-01-10', 2, 120000),
(1002, 2, 102, '2026-01-15', 3, 90000),
(1003, 3, 103, '2026-02-05', 5, 7500),
(1004, 4, 104, '2026-02-12', 4, 3200),
(1005, 5, 105, '2026-03-10', 2, 30000),
(1006, 1, 102, '2026-03-15', 1, 30000),
(1007, 2, 101, '2026-04-05', 1, 60000),
(1008, 3, 105, '2026-04-20', 3, 45000),
(1009, 4, 103, '2026-05-10', 10, 15000),
(1010, 5, 104, '2026-05-20', 5, 4000);


-- Display OLTP tables.
SELECT * FROM Customer;
SELECT * FROM Product;
SELECT * FROM Sales_Transaction;


-- ============================================================
-- PART 4: OLTP OPERATIONS
-- ============================================================


-- A. INSERT Operation: Add a new customer.
INSERT INTO Customer
VALUES (6, 'Neha', 'Thane', 'Maharashtra');


-- Check the Customer records.
SELECT * FROM Customer;


-- B. UPDATE Operation: Update the price of the Mouse.
UPDATE Product
SET Price = 900
WHERE Product_ID = 104;


-- Verify the updated Mouse record.
SELECT *
FROM Product
WHERE Product_ID = 104;


-- C. DELETE Operation: Delete a customer who has no transaction.
DELETE FROM Customer
WHERE Customer_ID = 6;


-- D. Transaction Processing: COMMIT saves the changes.
START TRANSACTION;

INSERT INTO Customer
VALUES (7, 'Kiran', 'Kolhapur', 'Maharashtra');

UPDATE Product
SET Price = 1550
WHERE Product_ID = 103;

COMMIT;


-- Transaction Processing: ROLLBACK cancels uncommitted changes.
START TRANSACTION;

UPDATE Product
SET Price = 2000
WHERE Product_ID = 103;

ROLLBACK;


-- Verify the final records after COMMIT and ROLLBACK.
SELECT * FROM Customer;
SELECT * FROM Product;


-- ============================================================
-- PART 5: CREATE STAR SCHEMA FOR OLAP
-- Data Warehouse tables: Fact_Sales, Dim_Customer,
-- Dim_Product and Dim_Date.
-- ============================================================


-- Create Customer Dimension.
CREATE TABLE Dim_Customer (
    Customer_Key INT PRIMARY KEY,
    Customer_ID INT,
    Customer_Name VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50)
);


-- Create Product Dimension.
CREATE TABLE Dim_Product (
    Product_Key INT PRIMARY KEY,
    Product_ID INT,
    Product_Name VARCHAR(50),
    Category VARCHAR(50),
    Price DECIMAL(10,2)
);


-- Create Date Dimension.
CREATE TABLE Dim_Date (
    Date_Key INT PRIMARY KEY,
    Full_Date DATE,
    Month INT,
    Quarter INT,
    Year INT
);


-- Create Fact Table.
CREATE TABLE Fact_Sales (
    Sales_Key INT PRIMARY KEY,
    Customer_Key INT,
    Product_Key INT,
    Date_Key INT,
    Quantity INT,
    Sales_Amount DECIMAL(10,2),

    FOREIGN KEY (Customer_Key)
        REFERENCES Dim_Customer(Customer_Key),

    FOREIGN KEY (Product_Key)
        REFERENCES Dim_Product(Product_Key),

    FOREIGN KEY (Date_Key)
        REFERENCES Dim_Date(Date_Key)
);


-- ============================================================
-- PART 6: POPULATE DIMENSION TABLES FROM OLTP TABLES
-- ============================================================


-- Populate Dim_Customer.
INSERT INTO Dim_Customer
SELECT
    Customer_ID,
    Customer_ID,
    Customer_Name,
    City,
    State
FROM Customer;


-- Populate Dim_Product.
INSERT INTO Dim_Product
SELECT
    Product_ID,
    Product_ID,
    Product_Name,
    Category,
    Price
FROM Product;


-- Populate Dim_Date.
-- DATE_FORMAT creates YYYYMMDD and CAST converts it to INT.
INSERT INTO Dim_Date
SELECT DISTINCT
    CAST(DATE_FORMAT(Sale_Date, '%Y%m%d') AS UNSIGNED) AS Date_Key,
    Sale_Date,
    MONTH(Sale_Date),
    QUARTER(Sale_Date),
    YEAR(Sale_Date)
FROM Sales_Transaction;


-- ============================================================
-- PART 7: POPULATE FACT TABLE
-- ============================================================


-- Populate Fact_Sales from Sales_Transaction.
INSERT INTO Fact_Sales
SELECT
    s.Transaction_ID,
    s.Customer_ID,
    s.Product_ID,
    CAST(DATE_FORMAT(s.Sale_Date, '%Y%m%d') AS UNSIGNED),
    s.Quantity,
    s.Amount
FROM Sales_Transaction s;


-- Check the Fact Table and Dimension Tables.
SELECT * FROM Dim_Customer;
SELECT * FROM Dim_Product;
SELECT * FROM Dim_Date;
SELECT * FROM Fact_Sales;


-- ============================================================
-- PART 8: OLAP OPERATIONS
-- The five major OLAP operations are Roll-up, Drill-down,
-- Slice, Dice and Pivot.
-- ============================================================


-- A. ROLL-UP
-- Roll-up summarizes detailed data into a higher-level summary.
-- Sales by Month.
SELECT
    d.Year,
    d.Month,
    SUM(f.Sales_Amount) AS Total_Sales
FROM Fact_Sales f
JOIN Dim_Date d
    ON f.Date_Key = d.Date_Key
GROUP BY d.Year, d.Month
ORDER BY d.Year, d.Month;


-- Sales by Year.
SELECT
    d.Year,
    SUM(f.Sales_Amount) AS Total_Sales
FROM Fact_Sales f
JOIN Dim_Date d
    ON f.Date_Key = d.Date_Key
GROUP BY d.Year;


-- Purpose: Month -> Quarter -> Year aggregation.


-- B. DRILL-DOWN
-- Drill-down moves from summarized information to more detail.
-- Year -> Month -> Category -> Product.
SELECT
    d.Year,
    d.Month,
    p.Category,
    p.Product_Name,
    SUM(f.Sales_Amount) AS Total_Sales
FROM Fact_Sales f
JOIN Dim_Date d
    ON f.Date_Key = d.Date_Key
JOIN Dim_Product p
    ON f.Product_Key = p.Product_Key
GROUP BY
    d.Year,
    d.Month,
    p.Category,
    p.Product_Name
ORDER BY
    d.Year,
    d.Month;


-- C. SLICE
-- Slice selects data based on one dimension.
-- Display sales for the year 2026.
SELECT
    p.Product_Name,
    SUM(f.Sales_Amount) AS Total_Sales
FROM Fact_Sales f
JOIN Dim_Product p
    ON f.Product_Key = p.Product_Key
JOIN Dim_Date d
    ON f.Date_Key = d.Date_Key
WHERE d.Year = 2026
GROUP BY p.Product_Name;


-- D. DICE
-- Dice selects data based on multiple dimensions.
-- Electronics products sold in Pune and Mumbai.
SELECT
    c.City,
    p.Product_Name,
    p.Category,
    SUM(f.Sales_Amount) AS Total_Sales
FROM Fact_Sales f
JOIN Dim_Customer c
    ON f.Customer_Key = c.Customer_Key
JOIN Dim_Product p
    ON f.Product_Key = p.Product_Key
WHERE c.City IN ('Pune', 'Mumbai')
  AND p.Category = 'Electronics'
GROUP BY
    c.City,
    p.Product_Name,
    p.Category;


-- E. PIVOT
-- Pivot changes rows into columns to compare information.
-- Compare sales by product category and month.
SELECT
    p.Category,

    SUM(CASE
        WHEN d.Month = 1 THEN f.Sales_Amount
        ELSE 0
    END) AS January,

    SUM(CASE
        WHEN d.Month = 2 THEN f.Sales_Amount
        ELSE 0
    END) AS February,

    SUM(CASE
        WHEN d.Month = 3 THEN f.Sales_Amount
        ELSE 0
    END) AS March,

    SUM(CASE
        WHEN d.Month = 4 THEN f.Sales_Amount
        ELSE 0
    END) AS April,

    SUM(CASE
        WHEN d.Month = 5 THEN f.Sales_Amount
        ELSE 0
    END) AS May

FROM Fact_Sales f
JOIN Dim_Product p
    ON f.Product_Key = p.Product_Key
JOIN Dim_Date d
    ON f.Date_Key = d.Date_Key
GROUP BY p.Category;


-- ============================================================
-- PART 9: ADDITIONAL OLAP QUERIES
-- ============================================================


-- Additional OLAP Query 1: Total Sales by Product.
SELECT
    p.Product_Name,
    SUM(f.Quantity) AS Total_Quantity,
    SUM(f.Sales_Amount) AS Total_Sales
FROM Fact_Sales f
JOIN Dim_Product p
    ON f.Product_Key = p.Product_Key
GROUP BY p.Product_Name
ORDER BY Total_Sales DESC;


-- Additional OLAP Query 2: Sales by City.
SELECT
    c.City,
    SUM(f.Sales_Amount) AS Total_Sales
FROM Fact_Sales f
JOIN Dim_Customer c
    ON f.Customer_Key = c.Customer_Key
GROUP BY c.City
ORDER BY Total_Sales DESC;


-- ============================================================
-- END OF EXPERIMENT 2
-- ============================================================
