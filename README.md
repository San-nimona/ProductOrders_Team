# ProductOrders Team – Audit Trigger Demo

## Project Overview
This project demonstrates auditing on the `Orders` table of the `productorders_team` database using SQL Server triggers.  
All **INSERT**, **UPDATE**, and **DELETE** operations are logged automatically in an audit table (`Audit.ProductOrders_Audit`) with old/new values, operation type, timestamp, and the user who made the change.  
This simulates a real-world scenario for order creation, shipping updates, and cancellations.

---

## Database Structure

### Tables
- **Orders**: Tracks customer orders  
  - Columns: `OrderID`, `CustID`, `OrderDate`, `ShippedDate`
- **Customers**, **Items**, **OrderDetails**, **SalesAnalytics.ProductDemand**: Other tables in the database (structures can be added if needed)
- **Audit.ProductOrders_Audit**: Logs all changes
  - Columns:
    - `AuditID` – Auto-increment primary key
    - `TableName` – Name of the table affected
    - `OperationType` – INSERT / UPDATE / DELETE
    - `RecordID` – ID of the affected record
    - `OldValue` – JSON of old record
    - `NewValue` – JSON of new record
    - `ModifiedDate` – Timestamp of the change
    - `ModifiedBy` – SQL Server username who made the change

### Trigger
- `trg_Orders_Audit`: Fires AFTER INSERT, UPDATE, DELETE on `Orders`  
- Logs old/new values in JSON format  
- Captures who made the change using `SUSER_SNAME()`

---

## Setup Instructions

### 1. Run Scripts
1. `scripts/create_tables.sql` → Creates all tables.
2. `scripts/create_audit_table.sql` → Creates the audit table.
3. `scripts/create_triggers.sql` → Creates the audit trigger.
4. Optionally, run `scripts/insert_sample_data.sql` or import `csv/orders_test_data.csv` to populate the `Orders` table for demo purposes.

### 2. Import CSV (Optional)
- Using SSMS: **Tasks → Import Flat File → select `orders_test_data.csv` → finish**  
- Or via SQL:
```sql
BULK INSERT dbo.Orders
FROM 'C:\Temp\orders_test_data.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
