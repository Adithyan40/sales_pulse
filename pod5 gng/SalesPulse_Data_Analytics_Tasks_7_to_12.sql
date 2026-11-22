-- ============================================================
-- SALESPULSE: DATA ANALYTICS WORK AREA A (TASKS 7-12)
-- Dataset: SalesPulse Week 2 Day 3
-- Database: salespulse_week2_day3
-- Revenue = Quantity * UnitPrice
-- Estimated Gross Profit = Quantity * (UnitPrice - UnitCost)
-- Run after importing Customers, Products, Orders, OrderItems.
-- MySQL 8.0 compatible.
-- ============================================================

USE salespulse_week2_day3;

-- ------------------------------------------------------------
-- TASK 7: CUSTOMER SEGMENT ANALYSIS
-- 7.1 Number of customers in each segment
-- ------------------------------------------------------------
SELECT CustomerSegment, COUNT(*) AS CustomerCount
FROM Customers
GROUP BY CustomerSegment
ORDER BY CustomerCount DESC;

-- 7.2 Revenue, gross profit, orders and AOV by segment.
-- Each order's value is first calculated at order level to avoid
-- counting an order more than once when it contains several items.
WITH OrderTotals AS (
    SELECT o.OrderID, c.CustomerSegment,
           SUM(oi.Quantity * p.UnitPrice) AS OrderRevenue,
           SUM(oi.Quantity * (p.UnitPrice - p.UnitCost)) AS OrderGrossProfit
    FROM Orders o
    JOIN Customers c ON c.CustomerID = o.CustomerID
    JOIN OrderItems oi ON oi.OrderID = o.OrderID
    JOIN Products p ON p.ProductID = oi.ProductID
    GROUP BY o.OrderID, c.CustomerSegment
),
SegmentTotals AS (
    SELECT CustomerSegment, COUNT(*) AS TotalOrders,
           SUM(OrderRevenue) AS TotalRevenue,
           SUM(OrderGrossProfit) AS EstimatedGrossProfit
    FROM OrderTotals
    GROUP BY CustomerSegment
),
SegmentCustomerCounts AS (
    SELECT CustomerSegment, COUNT(*) AS CustomerCount
    FROM Customers
    GROUP BY CustomerSegment
)
SELECT st.CustomerSegment, scc.CustomerCount, st.TotalOrders,
       st.TotalRevenue, st.EstimatedGrossProfit,
       ROUND(st.TotalRevenue / NULLIF(st.TotalOrders, 0), 2) AS AverageOrderValue,
       ROUND(st.TotalRevenue / NULLIF(scc.CustomerCount, 0), 2) AS RevenuePerRegisteredCustomer
FROM SegmentTotals st
JOIN SegmentCustomerCounts scc ON scc.CustomerSegment = st.CustomerSegment
ORDER BY st.TotalRevenue DESC;

-- 7.3 Segment revenue share of total revenue
WITH SegmentRevenue AS (
    SELECT c.CustomerSegment,
           SUM(oi.Quantity * p.UnitPrice) AS Revenue
    FROM Customers c
    JOIN Orders o ON o.CustomerID = c.CustomerID
    JOIN OrderItems oi ON oi.OrderID = o.OrderID
    JOIN Products p ON p.ProductID = oi.ProductID
    GROUP BY c.CustomerSegment
)
SELECT CustomerSegment, Revenue,
       ROUND(100 * Revenue / SUM(Revenue) OVER (), 2) AS RevenueContributionPct
FROM SegmentRevenue
ORDER BY Revenue DESC;

-- ------------------------------------------------------------
-- TASK 8: LOCATION-BASED ANALYSIS
-- 8.1 Top five shipping cities by revenue and distinct orders
-- ------------------------------------------------------------
SELECT o.ShipCity,
       COUNT(DISTINCT o.OrderID) AS OrdersShipped,
       SUM(oi.Quantity * p.UnitPrice) AS Revenue
FROM Orders o
JOIN OrderItems oi ON oi.OrderID = o.OrderID
JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY o.ShipCity
ORDER BY Revenue DESC
LIMIT 5;

-- 8.2 Revenue attributed to the customer's registered city.
-- Customer count includes all registered customers in that city.
WITH CityRevenue AS (
    SELECT c.City,
           COUNT(DISTINCT o.OrderID) AS Orders,
           SUM(oi.Quantity * p.UnitPrice) AS Revenue
    FROM Customers c
    LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
    LEFT JOIN OrderItems oi ON oi.OrderID = o.OrderID
    LEFT JOIN Products p ON p.ProductID = oi.ProductID
    GROUP BY c.City
),
CityCustomers AS (
    SELECT City, COUNT(*) AS RegisteredCustomers
    FROM Customers
    GROUP BY City
)
SELECT cc.City, cc.RegisteredCustomers,
       COALESCE(cr.Orders, 0) AS Orders,
       COALESCE(cr.Revenue, 0) AS Revenue,
       ROUND(COALESCE(cr.Revenue, 0) / NULLIF(cc.RegisteredCustomers, 0), 2)
           AS RevenuePerRegisteredCustomer
FROM CityCustomers cc
LEFT JOIN CityRevenue cr ON cr.City = cc.City
ORDER BY Revenue DESC;

-- 8.3 Customer city versus shipping city: order count by city pair
SELECT c.City AS CustomerCity, o.ShipCity,
       COUNT(DISTINCT o.OrderID) AS OrderCount
FROM Orders o
JOIN Customers c ON c.CustomerID = o.CustomerID
GROUP BY c.City, o.ShipCity
ORDER BY OrderCount DESC;

-- 8.4 Count orders shipped within the customer's city versus elsewhere
SELECT
    SUM(CASE WHEN c.City = o.ShipCity THEN 1 ELSE 0 END) AS SameCityOrders,
    SUM(CASE WHEN c.City <> o.ShipCity THEN 1 ELSE 0 END) AS DifferentCityOrders
FROM Orders o
JOIN Customers c ON c.CustomerID = o.CustomerID;

-- ------------------------------------------------------------
-- TASK 9: ORDER STATUS ANALYSIS
-- ------------------------------------------------------------
SELECT o.OrderStatus,
       COUNT(DISTINCT o.OrderID) AS OrderCount,
       ROUND(100 * COUNT(DISTINCT o.OrderID) /
             (SELECT COUNT(*) FROM Orders), 2) AS PercentageOfOrders,
       SUM(oi.Quantity * p.UnitPrice) AS RevenueAssociated,
       SUM(oi.Quantity * (p.UnitPrice - p.UnitCost)) AS EstimatedGrossProfit
FROM Orders o
LEFT JOIN OrderItems oi ON oi.OrderID = o.OrderID
LEFT JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY o.OrderStatus
ORDER BY OrderCount DESC;

-- ------------------------------------------------------------
-- TASK 10: DATA QUALITY INVESTIGATION
-- 10.1 Customers with NULL or empty email
-- ------------------------------------------------------------
SELECT CustomerID, CustomerName, Email
FROM Customers
WHERE Email IS NULL OR TRIM(Email) = '';

-- 10.2 Duplicate primary-key values (run for each table)
SELECT 'Customers' AS TableName, CustomerID AS DuplicateID, COUNT(*) AS Occurrences
FROM Customers GROUP BY CustomerID HAVING COUNT(*) > 1
UNION ALL
SELECT 'Products', ProductID, COUNT(*)
FROM Products GROUP BY ProductID HAVING COUNT(*) > 1
UNION ALL
SELECT 'Orders', OrderID, COUNT(*)
FROM Orders GROUP BY OrderID HAVING COUNT(*) > 1
UNION ALL
SELECT 'OrderItems', OrderItemID, COUNT(*)
FROM OrderItems GROUP BY OrderItemID HAVING COUNT(*) > 1;

-- 10.3 Orders without order items
SELECT o.OrderID
FROM Orders o
LEFT JOIN OrderItems oi ON oi.OrderID = o.OrderID
WHERE oi.OrderID IS NULL;

-- 10.4 Invalid or zero quantities
SELECT *
FROM OrderItems
WHERE Quantity IS NULL OR Quantity <= 0;

-- 10.5 Products with invalid prices/costs or cost greater than price
SELECT ProductID, ProductName, UnitPrice, UnitCost
FROM Products
WHERE UnitPrice IS NULL OR UnitCost IS NULL
   OR UnitPrice <= 0 OR UnitCost < 0 OR UnitCost > UnitPrice;

-- 10.6 Customers who have never placed an order
SELECT c.CustomerID, c.CustomerName, c.City, c.Email
FROM Customers c
LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
WHERE o.OrderID IS NULL;

-- 10.7 Products that have never been sold
SELECT p.ProductID, p.ProductName, p.Category, p.IsActive
FROM Products p
LEFT JOIN OrderItems oi ON oi.ProductID = p.ProductID
WHERE oi.ProductID IS NULL;

-- 10.8 Orphan foreign-key checks (should return no rows)
SELECT o.OrderID, o.CustomerID
FROM Orders o
LEFT JOIN Customers c ON c.CustomerID = o.CustomerID
WHERE c.CustomerID IS NULL;

SELECT oi.OrderItemID, oi.OrderID
FROM OrderItems oi
LEFT JOIN Orders o ON o.OrderID = oi.OrderID
WHERE o.OrderID IS NULL;

SELECT oi.OrderItemID, oi.ProductID
FROM OrderItems oi
LEFT JOIN Products p ON p.ProductID = oi.ProductID
WHERE p.ProductID IS NULL;

-- 10.9 Review unusually high/low product prices and estimated unit margins
SELECT ProductID, ProductName, Category, UnitPrice, UnitCost,
       (UnitPrice - UnitCost) AS UnitGrossProfit,
       ROUND(100 * (UnitPrice - UnitCost) / NULLIF(UnitPrice, 0), 2) AS MarginPct
FROM Products
ORDER BY UnitPrice DESC;

-- ------------------------------------------------------------
-- TASK 11: BUSINESS FINDINGS
-- The written report contains the seven evidence-based findings.
-- The following queries reproduce key evidence.
-- ------------------------------------------------------------

-- 11.1 Segment revenue and customer count
SELECT c.CustomerSegment,
       COUNT(DISTINCT c.CustomerID) AS Customers,
       COUNT(DISTINCT o.OrderID) AS Orders,
       SUM(oi.Quantity * p.UnitPrice) AS Revenue,
       SUM(oi.Quantity * (p.UnitPrice - p.UnitCost)) AS EstimatedGrossProfit
FROM Customers c
LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
LEFT JOIN OrderItems oi ON oi.OrderID = o.OrderID
LEFT JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY c.CustomerSegment
ORDER BY Revenue DESC;

-- 11.2 Shipping city revenue ranking
SELECT o.ShipCity, COUNT(DISTINCT o.OrderID) AS Orders,
       SUM(oi.Quantity * p.UnitPrice) AS Revenue
FROM Orders o
JOIN OrderItems oi ON oi.OrderID = o.OrderID
JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY o.ShipCity
ORDER BY Revenue DESC;

-- 11.3 Customer city revenue and registered customer count
SELECT c.City, COUNT(DISTINCT c.CustomerID) AS RegisteredCustomers,
       COUNT(DISTINCT o.OrderID) AS Orders,
       COALESCE(SUM(oi.Quantity * p.UnitPrice), 0) AS Revenue
FROM Customers c
LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
LEFT JOIN OrderItems oi ON oi.OrderID = o.OrderID
LEFT JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY c.City
ORDER BY Revenue DESC;

-- 11.4 Order status breakdown
SELECT o.OrderStatus, COUNT(DISTINCT o.OrderID) AS Orders,
       ROUND(100 * COUNT(DISTINCT o.OrderID) / (SELECT COUNT(*) FROM Orders), 2) AS OrderPct,
       SUM(oi.Quantity * p.UnitPrice) AS Revenue
FROM Orders o
LEFT JOIN OrderItems oi ON oi.OrderID = o.OrderID
LEFT JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY o.OrderStatus
ORDER BY Orders DESC;

-- 11.5 Email quality and inactive customer evidence
SELECT
    SUM(CASE WHEN Email IS NULL OR TRIM(Email) = '' THEN 1 ELSE 0 END) AS MissingEmailCustomers,
    (SELECT COUNT(*) FROM Customers c
     LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
     WHERE o.OrderID IS NULL) AS CustomersWithoutOrders
FROM Customers;

-- ------------------------------------------------------------
-- TASK 12: BUSINESS RECOMMENDATIONS
-- Recommendations and their evidence are documented in the report.
-- No additional SQL is required for narrative recommendations.
-- ------------------------------------------------------------
