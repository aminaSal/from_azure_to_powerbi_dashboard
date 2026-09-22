GO

CREATE TABLE staging.orders (
    OrderID VARCHAR(50) NOT NULL,
    OrderDate DATE,
    CustomerName VARCHAR(255),
    State VARCHAR(100),
    City VARCHAR(100)
);
GO

CREATE TABLE staging.order_details (
    OrderID VARCHAR(50) NOT NULL,
    Amount DECIMAL(18,2),
    Profit DECIMAL(18,2),
    Quantity INT,
    Category VARCHAR(100),
    SubCategory VARCHAR(100)
);

GO

CREATE TABLE staging.sales_target (
    MonthOfOrderDate VARCHAR(20),
    Category VARCHAR(100),
    Target DECIMAL(18,2)
);
