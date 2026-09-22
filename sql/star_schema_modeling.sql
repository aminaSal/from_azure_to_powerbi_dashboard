-- Star schema modeling
-- volume verification
SELECT 'orders' AS TableName, COUNT(*) AS NbRows
FROM dbo.orders

UNION ALL

SELECT 'order_details', COUNT(*)
FROM dbo.order_details

UNION ALL

SELECT 'sales_target', COUNT(*)
FROM dbo.sales_target;

-- Do all detail rows have a corresponding order in the Orders table? 0 => oui
SELECT COUNT(*) AS DetailsWithoutOrder
FROM dbo.order_details d
LEFT JOIN dbo.orders o
    ON d.OrderID = o.OrderID
WHERE o.OrderID IS NULL;

-- duplicates : empty => OK
SELECT
    OrderID,
    COUNT(*) AS Nb
FROM dbo.orders
GROUP BY OrderID
HAVING COUNT(*) > 1;

-- unique month-category combination ? => OK
SELECT
    MonthOfOrderDate,
    Category,
    COUNT(*) AS Nb
FROM dbo.sales_target
GROUP BY MonthOfOrderDate, Category
HAVING COUNT(*) > 1;


SELECT
    MIN(OrderDate) AS MinOrderDate,
    MAX(OrderDate) AS MaxOrderDate
FROM dbo.orders;

-- 1)	A) create Date dimension
CREATE TABLE dbo.dim_date (
    DateKey INT NOT NULL PRIMARY KEY,
    Date DATE NOT NULL,
    Year INT NOT NULL,
    MonthNumber INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    Quarter VARCHAR(2) NOT NULL,
    YearMonth VARCHAR(7) NOT NULL
);

-- B) Automatic population of the dim_date table
DECLARE @StartDate DATE = '2018-04-01';
DECLARE @EndDate DATE = '2019-03-31';

WITH Dates AS (
    SELECT @StartDate AS DateValue

    UNION ALL

    SELECT DATEADD(DAY, 1, DateValue)
    FROM Dates
    WHERE DateValue < @EndDate
)
INSERT INTO dbo.dim_date (
    DateKey,
    Date,
    Year,
    MonthNumber,
    MonthName,
    Quarter,
    YearMonth
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), DateValue, 112)) AS DateKey,
    DateValue,
    YEAR(DateValue),
    MONTH(DateValue),
    DATENAME(MONTH, DateValue),
    CONCAT('Q', DATEPART(QUARTER, DateValue)),
    CONVERT(CHAR(7), DateValue, 120)
FROM Dates
OPTION (MAXRECURSION 400);

-- 2)	A) dim_product creation
CREATE TABLE dbo.dim_product (
    ProductKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Category VARCHAR(100) NOT NULL,
    SubCategory VARCHAR(100) NOT NULL
);

-- B) dim_product population

INSERT INTO dbo.dim_product (
    Category,
    SubCategory
)
SELECT DISTINCT
    Category,
    SubCategory
FROM dbo.order_details
WHERE Category IS NOT NULL
  AND SubCategory IS NOT NULL;

-- verifications
SELECT *
FROM dbo.dim_product
ORDER BY Category, SubCategory;

SELECT
    Category,
    SubCategory,
    COUNT(*) AS Nb
FROM dbo.dim_product
GROUP BY Category, SubCategory
HAVING COUNT(*) > 1;
-- OK => no duplicates

-- 3)	A) dim_customer creation
CREATE TABLE dbo.dim_customer (
    CustomerKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerName VARCHAR(255) NOT NULL
);

-- table population
INSERT INTO dbo.dim_customer (
    CustomerName
)
SELECT DISTINCT
    CustomerName
FROM dbo.orders
WHERE CustomerName IS NOT NULL
  AND LTRIM(RTRIM(CustomerName)) <> '';

-- verifications
SELECT *
FROM dbo.dim_customer
ORDER BY CustomerName;

SELECT
    CustomerName,
    COUNT(*) AS Nb
FROM dbo.dim_customer
GROUP BY CustomerName
HAVING COUNT(*) > 1;

-- 4)	A) dim_location creation
CREATE TABLE dbo.dim_location (
    LocationKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    State VARCHAR(100) NOT NULL,
    City VARCHAR(100) NOT NULL
);

-- B)  dim_location population
INSERT INTO dbo.dim_location (
    State,
    City
)
SELECT DISTINCT
    State,
    City
FROM dbo.orders
WHERE State IS NOT NULL
  AND City IS NOT NULL
  AND LTRIM(RTRIM(State)) <> ''
  AND LTRIM(RTRIM(City)) <> '';

-- 5)	A) fact_sales table creation
CREATE TABLE dbo.fact_sales (
    SalesKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OrderID VARCHAR(50) NOT NULL,
    DateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    LocationKey INT NOT NULL,
    Amount DECIMAL(18,2),
    Profit DECIMAL(18,2),
    Quantity INT
);

-- B) fact_sales population 

INSERT INTO dbo.fact_sales (
    OrderID,
    DateKey,
    CustomerKey,
    ProductKey,
    LocationKey,
    Amount,
    Profit,
    Quantity
)
SELECT
    d.OrderID,
    dd.DateKey,
    dc.CustomerKey,
    dp.ProductKey,
    dl.LocationKey,
    d.Amount,
    d.Profit,
    d.Quantity
FROM dbo.order_details d
INNER JOIN dbo.orders o
    ON d.OrderID = o.OrderID
INNER JOIN dbo.dim_date dd
    ON o.OrderDate = dd.Date
INNER JOIN dbo.dim_customer dc
    ON o.CustomerName = dc.CustomerName
INNER JOIN dbo.dim_product dp
    ON d.Category = dp.Category
    AND d.SubCategory = dp.SubCategory
INNER JOIN dbo.dim_location dl
    ON o.State = dl.State
    AND o.City = dl.City;


-- 6)	A) Fact_sales_target
-- create the Category dimension first, since the Sales_Target table does not contain a sub-category

CREATE TABLE dbo.dim_category (
    CategoryKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Category VARCHAR(100) NOT NULL
);

INSERT INTO dbo.dim_category (Category)
SELECT DISTINCT Category
FROM dbo.sales_target
WHERE Category IS NOT NULL
  AND LTRIM(RTRIM(Category)) <> '';

SELECT *
FROM dbo.dim_category
ORDER BY Category;

-- dim_sales_target creation
CREATE TABLE dbo.fact_sales_target (
    TargetKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DateKey INT NOT NULL,
    CategoryKey INT NOT NULL,
    Target DECIMAL(18,2) NOT NULL
);

-- loading data

INSERT INTO dbo.fact_sales_target (
    DateKey,
    CategoryKey,
    Target
)
SELECT
    dd.DateKey,
    dc.CategoryKey,
    st.Target
FROM dbo.sales_target st
INNER JOIN dbo.dim_date dd
    ON st.MonthOfOrderDate = dd.Date
INNER JOIN dbo.dim_category dc
    ON st.Category = dc.Category;

-- verifications
SELECT TOP 20 *
FROM dbo.fact_sales_target
ORDER BY DateKey, CategoryKey;

SELECT COUNT(*) AS TargetRows
FROM dbo.fact_sales_target;

SELECT
    dd.Year,
    dd.MonthNumber,
    dc.Category,
    fst.Target
FROM dbo.fact_sales_target fst
INNER JOIN dbo.dim_date dd
    ON fst.DateKey = dd.DateKey
INNER JOIN dbo.dim_category dc
    ON fst.CategoryKey = dc.CategoryKey
ORDER BY
    dd.Date,
    dc.Category;

-- => OK
