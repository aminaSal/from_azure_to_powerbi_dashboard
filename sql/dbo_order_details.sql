CREATE TABLE dbo.order_details (
    OrderID VARCHAR(50) NOT NULL,
    Amount DECIMAL(18,2),
    Profit DECIMAL(18,2),
    Quantity INT,
    Category VARCHAR(100),
    SubCategory VARCHAR(100)
);
GO

INSERT INTO dbo.order_details (
    OrderID,
    Amount,
    Profit,
    Quantity,
    Category,
    SubCategory
)
SELECT
    OrderID,
    Amount,
    Profit,
    Quantity,
    Category,
    SubCategory
FROM staging.order_details;
