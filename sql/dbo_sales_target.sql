CREATE TABLE dbo.sales_target (
    MonthOfOrderDate DATE,
    Category VARCHAR(100),
    Target DECIMAL(18,2)
);
GO

INSERT INTO dbo.sales_target (
    MonthOfOrderDate,
    Category,
    Target
)
SELECT 
    TRY_CONVERT(
    DATE, '01-' + MonthOfOrderDate, 106),
    Category,
    Target
FROM staging.sales_target

-- tests
SELECT
    COUNT(*) AS InvalidDates
FROM staging.sales_target
WHERE MonthOfOrderDate IS NOT NULL
  AND TRY_CONVERT(DATE, '01-' + MonthOfOrderDate, 106) IS NULL;

SELECT TOP 20 *
FROM dbo.sales_target
ORDER BY MonthOfOrderDate, Category;
