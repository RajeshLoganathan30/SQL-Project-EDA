-- =============================================
-- Stored Procedure: usp_GenerateCustomerKPIReport
-- Description: KPI Reporting with window functions, CTEs, error handling, and logging
-- Database: AdventureWorks2022
-- Author: Rajesh Loganathan
-- =============================================

ALTER PROCEDURE usp_GenerateCustomerKPIReport
    @StartDate DATE = '2011-01-01',
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @EndDate IS NULL
        SET @EndDate = GETDATE();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Optional: Create schema if it doesn't exist
        IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Reporting')
            EXEC sp_executesql N'CREATE SCHEMA Reporting';

        -- Drop existing report table
        IF OBJECT_ID('Reporting.CustomerKPI', 'U') IS NOT NULL
            DROP TABLE Reporting.CustomerKPI;

        -- Step 1: Prepare sales & customer data
        WITH CustomerSales AS (
            SELECT
                c.CustomerID,
                soh.SalesOrderID,
                soh.OrderDate,
                sod.LineTotal,
                sod.OrderQty,
                sod.UnitPrice,
                pr.StandardCost,
                sod.UnitPrice * sod.OrderQty AS GrossSales,
                ISNULL(pr.StandardCost * sod.OrderQty, sod.UnitPrice * sod.OrderQty * 0.6) AS EstimatedCost,
                per.FirstName + ' ' + per.LastName AS FullName
            FROM Sales.SalesOrderHeader soh
            JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
            JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
            JOIN Production.Product pr ON sod.ProductID = pr.ProductID
            LEFT JOIN Person.Person per ON c.PersonID = per.BusinessEntityID
            WHERE soh.OrderDate BETWEEN @StartDate AND @EndDate
        )
        , OrderGaps AS (
            SELECT
                CustomerID,
                OrderDate,
                DATEDIFF(DAY,
                    LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate),
                    OrderDate) AS DaysBetweenOrders
            FROM CustomerSales
        )
        , AggregatedKPIs AS (
            SELECT
                cs.CustomerID,
                cs.FullName,
                COUNT(DISTINCT cs.SalesOrderID) AS TotalOrders,
                SUM(cs.LineTotal) AS TotalRevenue,
                SUM(cs.EstimatedCost) AS TotalCost,
                SUM(cs.LineTotal - cs.EstimatedCost) AS GrossProfit,
                AVG(cs.LineTotal) AS AvgOrderValue,
                DATEDIFF(MONTH, MIN(cs.OrderDate), MAX(cs.OrderDate)) AS CustomerLifetimeMonths,
                SUM(cs.LineTotal) / NULLIF(DATEDIFF(MONTH, MIN(cs.OrderDate), MAX(cs.OrderDate)), 0) AS ARPU,
                AVG(ISNULL(og.DaysBetweenOrders, 0)) AS AvgDaysBetweenOrders,
                CASE
                    WHEN SUM(cs.LineTotal) > 10000 THEN 'Gold'
                    WHEN SUM(cs.LineTotal) > 5000 THEN 'Silver'
                    ELSE 'Bronze'
                END AS CustomerTier
            FROM CustomerSales cs
            LEFT JOIN OrderGaps og ON cs.CustomerID = og.CustomerID AND cs.OrderDate = og.OrderDate
            GROUP BY cs.CustomerID, cs.FullName
        )

        -- Final Report Output
        SELECT *
        INTO Reporting.CustomerKPI
        FROM AggregatedKPIs;

        -- Step 2: Audit Logging
        IF OBJECT_ID('Reporting.ReportAuditLog', 'U') IS NULL
        BEGIN
            CREATE TABLE Reporting.ReportAuditLog (
                ReportName NVARCHAR(100),
                ExecutionDate DATETIME,
                TotalRowCount INT,
                Status NVARCHAR(50),
                ErrorMessage NVARCHAR(MAX)
            );
        END

        INSERT INTO Reporting.ReportAuditLog (ReportName, ExecutionDate, TotalRowCount, Status, ErrorMessage)
        SELECT 'usp_GenerateCustomerKPIReport', GETDATE(), COUNT(*), 'Success', NULL
        FROM Reporting.CustomerKPI;

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION;

        IF OBJECT_ID('Reporting.ReportAuditLog', 'U') IS NULL
        BEGIN
            CREATE TABLE Reporting.ReportAuditLog (
                ReportName NVARCHAR(100),
                ExecutionDate DATETIME,
                TotalRowCount INT,
                Status NVARCHAR(50),
                ErrorMessage NVARCHAR(MAX)
            );
        END

        INSERT INTO Reporting.ReportAuditLog (ReportName, ExecutionDate, TotalRowCount, Status, ErrorMessage)
        VALUES ('usp_GenerateCustomerKPIReport', GETDATE(), 0, 'Failed', ERROR_MESSAGE());

        THROW;
    END CATCH
END;

