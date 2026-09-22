CREATE TABLE dbo.orders (
    OrderID VARCHAR(50) NOT NULL,
    OrderDate DATE,
    CustomerName VARCHAR(255),
    State VARCHAR(100),
    City VARCHAR(100)
);

--SELECT *
--FROM dbo.orders;

INSERT INTO dbo.orders (
    OrderID,
    OrderDate,
    CustomerName,
    State,
    City
)
SELECT
    OrderID,
    TRY_CONVERT(DATE, OrderDate, 105),
    CustomerName,
    State,
    City
FROM staging.orders;

-- tests
SELECT COUNT(*) AS InvalidDates
FROM staging.orders
WHERE OrderDate IS NOT NULL
  AND TRY_CONVERT(DATE, OrderDate, 105) IS NULL;

SELECT TOP 10 *
FROM dbo.orders
ORDER BY OrderDate;

SELECT COUNT(*) AS StagingRows
FROM staging.orders;

SELECT COUNT(*) AS DboRows
FROM dbo.orders;
