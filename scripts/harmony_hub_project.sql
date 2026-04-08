
/* =========================================================
   ProductOrders Database II Group Project
   Scenario: HarmonyHub Records - Online Music Retailer
   Platform: SQL Server
   =========================================================
   
*/
   
-- Creating a Schema

CREATE SCHEMA hh
GO

-- Staging Tables for Ingestion

CREATE TABLE hh.stg_Customers (
    CustID INT,
    CustFirstName VARCHAR(50),
    CustLastName VARCHAR(50),
    CustAddress VARCHAR(150),
    CustCity VARCHAR(60),
    CustState CHAR(2),
    CustZip VARCHAR(10),
    CustPhone VARCHAR(20),
    CustFax VARCHAR(20)
);
GO

CREATE TABLE hh.stg_Items (
    ItemID INT,
    Title VARCHAR(150),
    Artist VARCHAR(100),
    UnitPrice DECIMAL(10,2)
);
GO

CREATE TABLE hh.stg_Orders (
    OrderID INT,
    CustID INT,
    OrderDate DATETIME,
    ShippedDate DATETIME
);
GO

CREATE TABLE hh.stg_OrderDetails (
    OrderID INT,
    ItemID INT,
    Quantity INT
);
GO

/* -----------------------------
   4. Bulk Load Example Scripts
   Update file paths as needed.
------------------------------ */

BULK INSERT hh.stg_Customers
FROM 'C:\Data\NewCustomers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '
',
    TABLOCK
);
GO

BULK INSERT hh.stg_Items
FROM 'C:\Data\NewItems.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '
',
    TABLOCK
);
GO

BULK INSERT hh.stg_Orders
FROM 'C:\Data\NewOrders.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '
',
    TABLOCK
);
GO

BULK INSERT hh.stg_OrderDetails
FROM 'C:\Data\NewOrderDetails.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '
',
    TABLOCK
);
GO

/* -----------------------------
   5. Load from Staging to Final Tables
------------------------------ */

INSERT INTO Customers
SELECT DISTINCT CustFirstName, CustLastName, CustAddress, CustCity, CustState, CustZip, CustPhone, CustFax
FROM hh.stg_Customers;
GO

INSERT INTO Items
SELECT DISTINCT ItemID, Title, Artist, UnitPrice
FROM hh.stg_Items;
GO

INSERT INTO Orders
SELECT DISTINCT OrderID, CustID, OrderDate, ShippedDate
FROM hh.stg_Orders;
GO

INSERT INTO OrderDetails
SELECT DISTINCT OrderID, ItemID, Quantity
FROM hh.stg_OrderDetails;
GO

/* -----------------------------
   6. Audit Table
------------------------------ */
CREATE TABLE hh.AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TableName VARCHAR(100) NOT NULL,
    OperationType VARCHAR(10) NOT NULL,
    RecordID VARCHAR(200) NOT NULL,
    OldValue NVARCHAR(MAX) NULL,
    NewValue NVARCHAR(MAX) NULL,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedBy SYSNAME NOT NULL DEFAULT SUSER_SNAME()
);
GO

/* -----------------------------
   7. Audit Triggers
------------------------------ */

CREATE TRIGGER trg_Audit_Customers
ON Customers
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO hh.AuditLog (TableName, OperationType, RecordID, OldValue, NewValue)
    SELECT
        'Customers',
        CASE
            WHEN i.CustID IS NOT NULL AND d.CustID IS NULL THEN 'INSERT'
            WHEN i.CustID IS NOT NULL AND d.CustID IS NOT NULL THEN 'UPDATE'
            WHEN i.CustID IS NULL AND d.CustID IS NOT NULL THEN 'DELETE'
        END,
        COALESCE(CAST(i.CustID AS VARCHAR(20)), CAST(d.CustID AS VARCHAR(20))),
        CASE WHEN d.CustID IS NULL THEN NULL ELSE
            CONCAT('Name=', d.CustFirstName, ' ', d.CustLastName, '; City=', d.CustCity, '; State=', d.CustState)
        END,
        CASE WHEN i.CustID IS NULL THEN NULL ELSE
            CONCAT('Name=', i.CustFirstName, ' ', i.CustLastName, '; City=', i.CustCity, '; State=', i.CustState)
        END
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.CustID = d.CustID;
END;
GO

CREATE TRIGGER trg_Audit_Orders
ON Orders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO hh.AuditLog (TableName, OperationType, RecordID, OldValue, NewValue)
    SELECT
        'Orders',
        CASE
            WHEN i.OrderID IS NOT NULL AND d.OrderID IS NULL THEN 'INSERT'
            WHEN i.OrderID IS NOT NULL AND d.OrderID IS NOT NULL THEN 'UPDATE'
            WHEN i.OrderID IS NULL AND d.OrderID IS NOT NULL THEN 'DELETE'
        END,
        COALESCE(CAST(i.OrderID AS VARCHAR(20)), CAST(d.OrderID AS VARCHAR(20))),
        CASE WHEN d.OrderID IS NULL THEN NULL ELSE
            CONCAT('CustID=', d.CustID, '; OrderDate=', CONVERT(VARCHAR(19), d.OrderDate, 120), '; ShipDate=', CONVERT(VARCHAR(19), d.ShippedDate, 120))
        END,
        CASE WHEN i.OrderID IS NULL THEN NULL ELSE
            CONCAT('CustID=', i.CustID, '; OrderDate=', CONVERT(VARCHAR(19), i.OrderDate, 120), '; ShipDate=', CONVERT(VARCHAR(19), i.ShippedDate, 120))
        END
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.OrderID = d.OrderID;
END;
GO

CREATE TRIGGER trg_Audit_OrderDetails
ON OrderDetails
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO hh.AuditLog (TableName, OperationType, RecordID, OldValue, NewValue)
    SELECT
        'OrderDetails',
        CASE
            WHEN i.OrderID IS NOT NULL AND d.OrderID IS NULL THEN 'INSERT'
            WHEN i.OrderID IS NOT NULL AND d.OrderID IS NOT NULL THEN 'UPDATE'
            WHEN i.OrderID IS NULL AND d.OrderID IS NOT NULL THEN 'DELETE'
        END,
        CONCAT(COALESCE(CAST(i.OrderID AS VARCHAR(20)), CAST(d.OrderID AS VARCHAR(20))), '-', COALESCE(CAST(i.ItemID AS VARCHAR(20)), CAST(d.ItemID AS VARCHAR(20)))),
        CASE WHEN d.OrderID IS NULL THEN NULL ELSE
            CONCAT('ItemID=', d.ItemID, '; Qty=', d.Quantity)
        END,
        CASE WHEN i.OrderID IS NULL THEN NULL ELSE
            CONCAT('ItemID=', i.ItemID, '; Qty=', i.Quantity)
        END
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.OrderID = d.OrderID AND i.ItemID = d.ItemID;
END;
GO

/* -----------------------------
   8. Aggregation SP
------------------------------ */
CREATE OR ALTER PROCEDURE hh.usp_MonthlySalesDashboard
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        YEAR(o.OrderDate) AS SalesYear,
        MONTH(o.OrderDate) AS SalesMonth,
        DATENAME(MONTH, o.OrderDate) AS MonthName,
        c.CustState,
        i.Artist,
        i.Title,
        SUM(od.Quantity) AS UnitsSold,
        SUM(od.Quantity * i.UnitPrice) AS Revenue,
        AVG(DATEDIFF(DAY, o.OrderDate, o.ShippedDate) * 1.0) AS AvgShipDays,
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        COUNT(DISTINCT o.CustID) AS UniqueCustomers
    FROM Orders o
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    INNER JOIN Items i ON od.ItemID = i.ItemID
    INNER JOIN Customers c ON o.CustID = c.CustID
    GROUP BY
        YEAR(o.OrderDate),
        MONTH(o.OrderDate),
        DATENAME(MONTH, o.OrderDate),
        c.CustState,
        i.Artist,
        i.Title
    ORDER BY SalesYear, SalesMonth, Revenue DESC;
END;
GO

/* -----------------------------
   9. Executive Summary Queries
------------------------------ */
-- Total revenue
SELECT SUM(od.Quantity * i.UnitPrice) AS TotalRevenue
FROM OrderDetails od
JOIN Items i ON od.ItemID = i.ItemID;
GO

-- Top 5 items
SELECT TOP 5
    i.Title,
    i.Artist,
    SUM(od.Quantity) AS UnitsSold,
    SUM(od.Quantity * i.UnitPrice) AS Revenue
FROM OrderDetails od
JOIN Items i ON od.ItemID = i.ItemID
GROUP BY i.Title, i.Artist
ORDER BY Revenue DESC;
GO

-- Top 5 states
SELECT TOP 5
    c.CustState,
    SUM(od.Quantity * i.UnitPrice) AS Revenue
FROM Orders o
JOIN Customers c ON o.CustID = c.CustID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Items i ON od.ItemID = i.ItemID
GROUP BY c.CustState
ORDER BY Revenue DESC;
GO

-- Average shipping time
SELECT AVG(DATEDIFF(DAY, OrderDate, ShippedDate) * 1.0) AS AvgShippingDays
FROM Orders
WHERE ShippedDate IS NOT NULL;
GO

/* -----------------------------
   10. Audit Demo Statements
------------------------------ */
UPDATE Customers
SET CustCity = 'Toronto'
WHERE CustID = 1;
GO

UPDATE OrderDetails
SET Quantity = 3
WHERE OrderID = 264 AND ItemID = 8;
GO

DELETE FROM OrderDetails
WHERE OrderID = 97 AND ItemID = 4;
GO

SELECT *
FROM hh.AuditLog
ORDER BY AuditID DESC;
GO

