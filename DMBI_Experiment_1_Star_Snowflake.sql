-- ============================================================
-- DMBI EXPERIMENT 1
-- AIM: To design and implement Star Schema and Snowflake Schema
--      for a Sales Data Warehouse using SQL.
-- SOFTWARE: MySQL Workbench
--
-- NOTE:
-- 1. Run this script from top to bottom in MySQL Workbench.
-- 2. Star Schema and Snowflake Schema use separate databases so
--    their table names do not conflict.
-- 3. Run this script once. To rerun, drop the databases first.
-- ============================================================


-- ============================================================
-- PART 1: STAR SCHEMA
-- ============================================================

-- Create and select the Star Schema database.
CREATE DATABASE DataWarehouse_Star;
USE DataWarehouse_Star;


-- Create Product Dimension.
CREATE TABLE Dim_Product (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(50),
    Category VARCHAR(50),
    Price DECIMAL(10,2)
);


-- Create Customer Dimension.
CREATE TABLE Dim_Customer (
    Customer_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50)
);


-- Create Time Dimension.
CREATE TABLE Dim_Time (
    Time_ID INT PRIMARY KEY,
    Day INT,
    Month INT,
    Year INT
);


-- Create Sales Fact Table.
CREATE TABLE Fact_Sales (
    Sales_ID INT PRIMARY KEY,
    Product_ID INT,
    Customer_ID INT,
    Time_ID INT,
    Quantity INT,
    Total_Amount DECIMAL(10,2),

    FOREIGN KEY (Product_ID)
        REFERENCES Dim_Product(Product_ID),

    FOREIGN KEY (Customer_ID)
        REFERENCES Dim_Customer(Customer_ID),

    FOREIGN KEY (Time_ID)
        REFERENCES Dim_Time(Time_ID)
);


-- Insert Product Dimension data.
INSERT INTO Dim_Product VALUES
(1, 'Laptop', 'Electronics', 50000),
(2, 'Mobile', 'Electronics', 20000);


-- Insert Customer Dimension data.
INSERT INTO Dim_Customer VALUES
(101, 'Rahul', 'Mumbai', 'Maharashtra'),
(102, 'Priya', 'Pune', 'Maharashtra');


-- Insert Time Dimension data.
INSERT INTO Dim_Time VALUES
(1, 10, 5, 2024),
(2, 15, 5, 2024);


-- Insert Sales Fact data.
INSERT INTO Fact_Sales VALUES
(1001, 1, 101, 1, 2, 100000),
(1002, 2, 102, 2, 1, 20000);


-- Display Star Schema tables.
SELECT * FROM Dim_Product;
SELECT * FROM Dim_Customer;
SELECT * FROM Dim_Time;
SELECT * FROM Fact_Sales;


-- Join Fact Table with all Dimension Tables.
SELECT
    C.Customer_Name,
    P.Product_Name,
    T.Month,
    F.Quantity,
    F.Total_Amount
FROM Fact_Sales F
JOIN Dim_Product P
    ON F.Product_ID = P.Product_ID
JOIN Dim_Customer C
    ON F.Customer_ID = C.Customer_ID
JOIN Dim_Time T
    ON F.Time_ID = T.Time_ID;


-- ============================================================
-- PART 2: SNOWFLAKE SCHEMA
-- ============================================================

-- Create and select a separate Snowflake Schema database.
CREATE DATABASE DataWarehouse_Snowflake;
USE DataWarehouse_Snowflake;


-- Create Category sub-dimension table.
CREATE TABLE Category (
    Category_ID INT PRIMARY KEY,
    Category_Name VARCHAR(50)
);


-- Create Product table connected to Category.
CREATE TABLE Product (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(50),
    Category_ID INT,
    Price DECIMAL(10,2),

    FOREIGN KEY (Category_ID)
        REFERENCES Category(Category_ID)
);


-- Create State sub-dimension table.
CREATE TABLE State (
    State_ID INT PRIMARY KEY,
    State_Name VARCHAR(50)
);


-- Create Customer table connected to State.
CREATE TABLE Customer (
    Customer_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(50),
    City VARCHAR(50),
    State_ID INT,

    FOREIGN KEY (State_ID)
        REFERENCES State(State_ID)
);


-- Create Time Dimension.
CREATE TABLE Time_Dim (
    Time_ID INT PRIMARY KEY,
    Day INT,
    Month INT,
    Year INT
);


-- Create Sales Fact Table.
CREATE TABLE Sales_Fact (
    Sales_ID INT PRIMARY KEY,
    Product_ID INT,
    Customer_ID INT,
    Time_ID INT,
    Quantity INT,
    Total_Amount DECIMAL(10,2),

    FOREIGN KEY (Product_ID)
        REFERENCES Product(Product_ID),

    FOREIGN KEY (Customer_ID)
        REFERENCES Customer(Customer_ID),

    FOREIGN KEY (Time_ID)
        REFERENCES Time_Dim(Time_ID)
);


-- Insert Category data.
INSERT INTO Category VALUES
(1, 'Electronics');


-- Insert Product data.
INSERT INTO Product VALUES
(1, 'Laptop', 1, 50000),
(2, 'Mobile', 1, 20000);


-- Insert State data.
INSERT INTO State VALUES
(1, 'Maharashtra');


-- Insert Customer data.
INSERT INTO Customer VALUES
(101, 'Rahul', 'Mumbai', 1),
(102, 'Priya', 'Pune', 1);


-- Insert Time data.
INSERT INTO Time_Dim VALUES
(1, 10, 5, 2024),
(2, 15, 5, 2024);


-- Insert Sales Fact data.
INSERT INTO Sales_Fact VALUES
(1001, 1, 101, 1, 2, 100000),
(1002, 2, 102, 2, 1, 20000);


-- Display Snowflake Schema tables.
SELECT * FROM Category;
SELECT * FROM Product;
SELECT * FROM State;
SELECT * FROM Customer;
SELECT * FROM Time_Dim;
SELECT * FROM Sales_Fact;


-- Join Fact Table with all normalized Dimension Tables.
SELECT
    C.Customer_Name,
    P.Product_Name,
    CA.Category_Name,
    S.State_Name,
    T.Month,
    F.Quantity,
    F.Total_Amount
FROM Sales_Fact F
JOIN Product P
    ON F.Product_ID = P.Product_ID
JOIN Category CA
    ON P.Category_ID = CA.Category_ID
JOIN Customer C
    ON F.Customer_ID = C.Customer_ID
JOIN State S
    ON C.State_ID = S.State_ID
JOIN Time_Dim T
    ON F.Time_ID = T.Time_ID;


-- ============================================================
-- END OF EXPERIMENT 1
-- ============================================================
