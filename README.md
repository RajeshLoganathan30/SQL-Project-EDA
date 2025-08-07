# 🧾 SQL Customer KPI Reporting Project

## Overview

This project explores advanced SQL techniques to build an **automated KPI reporting system** for customer-level metrics using the AdventureWorks2022 dataset. It demonstrates a full end-to-end process with:

- 🛠 ETL logic using **Common Table Expressions (CTEs)**
- 🧮 KPI aggregation using **window functions**
- 🚦 **Error handling and logging**
- 💾 Output written to dedicated **reporting tables** for easy export or BI use

---

## 🔍 Objective

To simulate a **data exploration and reporting solution** similar to what financial institutions or sales organizations would need when measuring customer lifetime value, average revenue, and engagement patterns over time.

---

## 🧩 Technologies Used

- Microsoft SQL Server (AdventureWorks2022)
- SQL Server Management Studio (SSMS)
- Transact-SQL (T-SQL)
- GitHub for version control

---

## 📁 Stored Procedure Logic

Stored procedure: `usp_GenerateCustomerKPIReport`

| Feature | Details |
|--------|---------|
| ✅ Input Parameters | `@StartDate`, `@EndDate` (defaults to current date) |
| 🛠 Schema Handling | Auto-creates `Reporting` schema if it doesn’t exist |
| 📊 Data Model | Joins `SalesOrderHeader`, `SalesOrderDetail`, `Customer`, `Product`, and `Person` tables |
| 🧮 CTEs Used | `CustomerSales`, `OrderGaps`, and `AggregatedKPIs` |
| 🧾 Output Table | `Reporting.CustomerKPI` |
| 📋 Audit Log | `Reporting.ReportAuditLog` tracks run history and status |

---

## 🧠 KPIs Calculated

The following metrics are computed for each customer:

- `TotalOrders`
- `TotalRevenue`
- `TotalCost`
- `GrossProfit`
- `AvgOrderValue`
- `CustomerLifetimeMonths`
- `ARPU` (Average Revenue Per User)
- `AvgDaysBetweenOrders` (customer engagement)
- `CustomerTier`: Gold, Silver, Bronze (based on revenue)

---

## 📤 Output

### 📊 Main Table: `Reporting.CustomerKPI`

Use this query to view the result:

```sql
SELECT * FROM Reporting.CustomerKPI;
```

| CustomerID | FullName      | TotalRevenue | GrossProfit | CustomerTier |
|------------|---------------|--------------|--------------|---------------|
| 11001      | Jane Smith    | 15,800       | 5,600        | Gold          |
| 11045      | David Brown   | 7,240        | 2,300        | Silver        |

> 🖼️ Add screenshot here: _customer_kpi_output.png_

---

### 📜 Audit Table: `Reporting.ReportAuditLog`

Tracks when the procedure was run and if it succeeded or failed:

```sql
SELECT * FROM Reporting.ReportAuditLog ORDER BY ExecutionDate DESC;
```

| ReportName               | ExecutionDate        | TotalRowCount | Status  | ErrorMessage |
|--------------------------|----------------------|----------------|---------|---------------|
| usp_GenerateCustomerKPIReport | 2025-08-07 14:39 | 140            | Success | NULL          |

> 🖼️ Add screenshot here: _audit_log_output.png_

---

## 🚨 Error Handling

- If any issue occurs during execution, a rollback is performed and the failure is logged.
- You can view error messages directly in `Reporting.ReportAuditLog`.

---

## 📈 Real-World Use Case

This is a simplified but powerful simulation of:

- Customer profitability tracking
- Lifetime value modeling
- Tier-based segmentation
- Revenue insights for business analysts or BI teams

It mirrors what you would automate in **financial services, SaaS companies, or B2C retail environments**.

---

## 🛠 How to Run

```sql
EXEC usp_GenerateCustomerKPIReport 
    @StartDate = '2013-01-01', 
    @EndDate = '2014-12-31';
```

> This creates or refreshes both the KPI report and audit log.

---
