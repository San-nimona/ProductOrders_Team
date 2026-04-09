
# HarmonyHub Records Project Proposal

## Project title
Data Integration, Auditing, and Business Intelligence for HarmonyHub Records

## Business scenario
HarmonyHub Records is a small online music retailer that sells albums and music products to customers across multiple U.S. states. Leadership wants a trusted reporting system that combines sales, customers, orders, and product data into one database, while also tracking changes to important records for governance and accountability.

## Business problem
The company currently has operational data spread across flat files. Management cannot easily answer questions such as:
- Which artists and titles generate the most revenue?
- Which states bring in the most sales?
- How long does shipping usually take?
- Which customers are most valuable?
- Who changed data, when was it changed, and what exactly changed?

## Project objective
Build a SQL Server solution that:
- loads external files into a relational schema,
- records INSERT, UPDATE, and DELETE activity through audit triggers,
- creates a business-ready aggregated dataset with a stored procedure,
- supports an executive dashboard for decision-making.

## Dataset overview
The project uses four core business tables:

| Table | Purpose | Key fields |
|---|---|---|
| Customers | Customer master data | CustID, name, city, state |
| Orders | Order header data | OrderID, CustID, OrderDate, ShippedDate |
| OrderDetails | Order line items | OrderID, ItemID, Quantity |
| Items | Product catalog | ItemID, Title, Artist, UnitPrice |

## Real-world framing
This project represents a common retail analytics use case. A sales organization needs a central database that supports both day-to-day operations and executive reporting. The audit layer adds governance, while the stored procedure creates a reusable dataset for Power BI, Tableau, Excel, or Python dashboards.

## Scope of work
### 1. Data ingestion
- Create schema `hh` inside the project database.
- Create staging tables and final tables.
- Load CSV files into staging tables using `BULK INSERT`.
- Validate and move clean data into final normalized tables.

### 2. Data governance and auditing
- Create one central audit table called `hh.AuditLog`.
- Add triggers to key business tables.
- Record operation type, record id, old value, new value, modified date, and modified by.

### 3. Data aggregation
- Create a stored procedure named `hh.usp_MonthlySalesDashboard`.
- Generate metrics such as revenue, units sold, average shipping days, total orders, and unique customers.

### 4. Dashboard storytelling
The dashboard should answer the following executive questions:
- Which products and artists drive the most revenue?
- Which states are strongest markets?
- Are shipping times improving or worsening?
- Where should marketing and operations focus next?

## Proposed architecture
1. Source files: CSV exports from the legacy order system.
2. Staging layer: `stg_Customers`, `stg_Orders`, `stg_OrderDetails`, `stg_Items`.
3. Governance layer: audit table and DML triggers.
4. Analytics layer: stored procedure output consumed by BI tools.

## Database design notes
- `Customers` stores one row per customer.
- `Orders` stores one row per order.
- `OrderDetails` stores one row per product in each order.
- `Items` stores the product catalog.
- `Orders` links customers to transactions.
- `OrderDetails` links orders to items.

This design supports referential integrity, prevents repeated data, and makes reporting easier.

## Example business logic for stored procedure
The stored procedure joins all four business tables and calculates:
- `UnitsSold = SUM(Quantity)`
- `Revenue = SUM(Quantity * UnitPrice)`
- `AvgShipDays = AVG(DATEDIFF(day, OrderDate, ShippedDate))`
- `TotalOrders = COUNT(DISTINCT OrderID)`
- `UniqueCustomers = COUNT(DISTINCT CustID)`

This produces a clean executive dataset at the monthly, state, artist, and title level.

## Dashboard KPIs
Recommended KPI cards:
- Total Revenue
- Total Orders
- Units Sold
- Average Shipping Days
- Top Artist
- Top State by Revenue

Recommended charts:
- Monthly revenue trend line
- Revenue by artist bar chart
- Revenue by state map or bar chart
- Top 10 titles by units sold
- Shipping performance trend by month

## Audit demonstration plan
Run three short demo actions during the presentation:
1. Update a customer city.
2. Update the quantity on one order detail row.
3. Delete one order detail row.

Then query `hh.AuditLog` to show that the trigger captured:
- table name,
- operation type,
- affected record,
- old value,
- new value,
- date/time,
- SQL user.

## Business insights you can present
Potential insights from the dashboard:
- Certain artists may contribute a large share of revenue.
- A few states may dominate total sales.
- Shipping performance may vary over time.
- Some customers may be repeat buyers with higher lifetime value.
- Product bundles or best sellers can guide promotion strategy.

## Executive recommendations
- Increase promotion for top-performing artists and titles.
- Target marketing in the highest-revenue states.
- Investigate long shipping times and improve order fulfillment.
- Use audit logs as part of data governance and compliance practice.
- Reuse the stored procedure as the official source for executive reporting.


## Submission checklist
- SQL schema creation script
- Table DDL
- Load scripts
- Trigger code
- Stored procedure code
- Sample CSV files
- Dashboard file
- Presentation deck
- Short documentation

## Presentation angle
We present ourselves as the data engineering and analytics team for HarmonyHub Records. The executive message is the company now has a governed, scalable reporting pipeline that turns raw sales files into trusted business insight.

