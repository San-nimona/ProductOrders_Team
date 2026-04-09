/* =========================================================
   ProductOrders Database II Group Project
   Scenario: HarmonyHub Records - Online Music Retailer
   Platform: SQL Server
   =========================================================
   
   This script builds a database structure for an online music
   store called HarmonyHub Records. It creates a place to store
   incoming data, loads that data into final tables, tracks changes
   with an audit log, and creates a report-style procedure for
   dashboard summaries.
*/

/* ---------------------------------------------------------
   1. Create a new schema
   ---------------------------------------------------------
   A schema is like a folder inside the database.
   We use it to keep all HarmonyHub objects organized.
---------------------------------------------------------- */
CREATE SCHEMA hh
GO

/* ---------------------------------------------------------
   2. Create staging tables
   ---------------------------------------------------------
   Staging tables are temporary holding areas for imported data.
   Data is loaded here first before being moved into final tables.
---------------------------------------------------------- */

CREATE TABLE hh.stg_Customers (
    CustID INT,                     -- Customer ID
    CustFirstName VARCHAR(50),      -- First name
    CustLastName VARCHAR(50),       -- Last name
    CustAddress VARCHAR(150),       -- Street address
    CustCity VARCHAR(60),           -- City
    CustState CHAR(2),              -- State abbreviation
    CustZip VARCHAR(10),            -- ZIP code
    CustPhone VARCHAR(20),          -- Phone number
    CustFax VARCHAR(20)             -- Fax number
);
GO

CREATE TABLE hh.stg_Items (
    ItemID INT,                     -- Item ID
    Title VARCHAR(150),             -- Song or album title
    Artist VARCHAR(100),            -- Artist name
    UnitPrice DECIMAL(10,2)         -- Price of each item
);
GO

CREATE TABLE hh.stg_Orders (
    OrderID INT,                    -- Order ID
    CustID INT,                     -- Customer who placed the order
    OrderDate DATETIME,             -- Date the order was placed
    ShippedDate DATETIME            -- Date the order was shipped
);
GO

CREATE TABLE hh.stg_OrderDetails (
    OrderID INT,                    -- Order ID
    ItemID INT,                     -- Item purchased
    Quantity INT                    -- Number of units ordered
);
GO

/* ---------------------------------------------------------
   3. Bulk load examples
   ---------------------------------------------------------
   These commands import CSV files into the staging tables.
   The file paths may need to be changed depending on the computer.
---------------------------------------------------------- */

BULK INSERT hh.stg_Customers
FROM 'C:\\Data\\NewCustomers.csv'
WITH (
    FIRSTROW = 2,                  -- Skip the header row
    FIELDTERMINATOR = ',',         -- Values are separated by commas
    ROWTERMINATOR = '
',
    TABLOCK
);
GO

BULK INSERT hh.stg_Items
FROM 'C:\\Data\\NewItems.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '
',
    TABLOCK
);
GO

BULK INSERT hh.stg_Orders
FROM 'C:\\Data\\NewOrders.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '
',
    TABLOCK
);
GO

BULK INSERT hh.stg_OrderDetails
FROM 'C:\\Data\\NewOrderDetails.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '
',
    TABLOCK
);
GO

/* ---------------------------------------------------------
   4. Move data from staging into final tables
   ---------------------------------------------------------
   After data is cleaned and checked in staging, it is copied
   into the main business tables.
---------------------------------------------------------- */

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

/* ---------------------------------------------------------
   5. Create an audit log table
   ---------------------------------------------------------
   This table records who changed data, when they changed it,
   what table was changed, and what the old/new values were.
---------------------------------------------------------- */
CREATE TABLE hh.AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,   -- Unique log entry number
    TableName VARCHAR(100) NOT NULL,         -- Table that changed
    OperationType VARCHAR(10) NOT NULL,      -- INSERT, UPDATE, or DELETE
    RecordID VARCHAR(200) NOT NULL,          -- ID of the affected record
    OldValue NVARCHAR(MAX) NULL,             -- Previous value
    NewValue NVARCHAR(MAX) NULL,             -- Updated value
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),  -- Time of change
    ModifiedBy SYSNAME NOT NULL DEFAULT SUSER_SNAME()   -- User who made the change
);
GO

/* ---------------------------------------------------------
   6. Create audit triggers
   ---------------------------------------------------------
   Triggers automatically write to the audit log whenever data
   is added, changed, or deleted in important tables.
---------------------------------------------------------- */

/* Audit Customers table */
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

/* Audit Orders table */
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

/* Audit OrderDetails table */
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

/* ---------------------------------------------------------
   7. Create a stored procedure for dashboard reporting
   ---------------------------------------------------------
   A stored procedure is a saved query. This one calculates
   monthly sales, customer location, product performance,
   and shipping speed for a dashboard.
---------------------------------------------------------- */
CREATE OR ALTER PROCEDURE hh.usp_MonthlySalesDashboard
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        YEAR(o.OrderDate) AS SalesYear,                          -- Year of sale
        MONTH(o.OrderDate) AS SalesMonth,                        -- Month number
        DATENAME(MONTH, o.OrderDate) AS MonthName,               -- Month name
        c.CustState,                                             -- Customer state
        i.Artist,                                                -- Artist name
        i.Title,                                                 -- Item title
        SUM(od.Quantity) AS UnitsSold,                           -- Total units sold
        SUM(od.Quantity * i.UnitPrice) AS Revenue,               -- Total revenue
        AVG(DATEDIFF(DAY, o.OrderDate, o.ShippedDate) * 1.0) AS AvgShipDays, -- Avg shipping time
        COUNT(DISTINCT o.OrderID) AS TotalOrders,                -- Number of orders
        COUNT(DISTINCT o.CustID) AS UniqueCustomers              -- Number of customers
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

/* ---------------------------------------------------------
   8. Summary queries for presentation or dashboard testing
   ---------------------------------------------------------
   These queries show the main business metrics in simple form.
---------------------------------------------------------- */

-- Total revenue from all sales
SELECT SUM(od.Quantity * i.UnitPrice) AS TotalRevenue
FROM OrderDetails od
JOIN Items i ON od.ItemID = i.ItemID;
GO

-- Top 5 best-selling items by revenue
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

-- Top 5 states by revenue
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

-- Average number of days it takes to ship orders
SELECT AVG(DATEDIFF(DAY, OrderDate, ShippedDate) * 1.0) AS AvgShippingDays
FROM Orders
WHERE ShippedDate IS NOT NULL;
GO

/* ---------------------------------------------------------
   9. Audit log demo actions
   ---------------------------------------------------------
   These sample changes are made on purpose so the audit log
   can show that the triggers are working.
---------------------------------------------------------- */

-- Change a customer's city
UPDATE Customers
SET CustCity = 'Toronto'
WHERE CustID = 1;
GO

-- Change quantity in an order
UPDATE OrderDetails
SET Quantity = 3
WHERE OrderID = 264 AND ItemID = 8;
GO

-- Delete one order detail record
DELETE FROM OrderDetails
WHERE OrderID = 97 AND ItemID = 4;
GO

-- View the audit history, newest entries first
SELECT *
FROM hh.AuditLog
ORDER BY AuditID DESC;
GO
