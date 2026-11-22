-- =====================================================================
-- SalesPulse | Work Area A (Data Analytics) | Tasks 1 to 6
-- Database : MySQL
-- Author   : R Abhishek Kumar
--
-- ASSUMED TABLE / COLUMN NAMES (change them if your database differs):
--   Customers  (CustomerID, CustomerName, Email, City, CustomerSegment, RegistrationDate)
--   Products   (ProductID, ProductName, Category, Price, Cost, IsActive)
--   Orders     (OrderID, CustomerID, OrderDate, ShippingCity, OrderStatus, SalesChannel)
--   OrderItems (OrderItemID, OrderID, ProductID, Quantity, UnitPrice)
--
-- BUSINESS FORMULAS USED THROUGHOUT:
--   Item revenue        = Quantity * UnitPrice
--   Estimated gross profit = Quantity * (UnitPrice - Products.Cost)
--   Gross profit margin = Gross profit / Revenue * 100
--   AOV                 = Total revenue / Number of orders
-- (If OrderItems has no UnitPrice column, replace oi.UnitPrice with p.Price.)
-- =====================================================================


-- =====================================================================
-- TASK 1 : OVERALL BUSINESS PERFORMANCE
-- =====================================================================

-- Q1.1 Total number of customers
SELECT COUNT(*) AS total_customers
FROM Customers;

-- Q1.2 Total number of orders
SELECT COUNT(*) AS total_orders
FROM Orders;

-- Q1.3 Total number of products
SELECT COUNT(*) AS total_products
FROM Products;

-- Q1.4 Total quantity of products sold
SELECT SUM(Quantity) AS total_quantity_sold
FROM OrderItems;

-- Q1.5 Total revenue
SELECT ROUND(SUM(Quantity * UnitPrice), 2) AS total_revenue
FROM OrderItems;

-- Q1.6 Estimated gross profit (revenue minus product cost)
SELECT ROUND(SUM(oi.Quantity * (oi.UnitPrice - p.Cost)), 2) AS estimated_gross_profit
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID;

-- Q1.7 Gross profit margin (%)
SELECT ROUND(
         SUM(oi.Quantity * (oi.UnitPrice - p.Cost))
         / SUM(oi.Quantity * oi.UnitPrice) * 100, 2) AS gross_profit_margin_pct
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID;

-- Q1.8 Average order value (AOV) = total revenue / number of orders that have items
SELECT ROUND(SUM(Quantity * UnitPrice) / COUNT(DISTINCT OrderID), 2) AS average_order_value
FROM OrderItems;

-- Q1.ALL All eight KPIs in a single result row (use this for the report screenshot)
SELECT
    (SELECT COUNT(*) FROM Customers)                          AS total_customers,
    (SELECT COUNT(*) FROM Orders)                             AS total_orders,
    (SELECT COUNT(*) FROM Products)                           AS total_products,
    SUM(oi.Quantity)                                          AS total_quantity_sold,
    ROUND(SUM(oi.Quantity * oi.UnitPrice), 2)                 AS total_revenue,
    ROUND(SUM(oi.Quantity * (oi.UnitPrice - p.Cost)), 2)      AS estimated_gross_profit,
    ROUND(SUM(oi.Quantity * (oi.UnitPrice - p.Cost))
          / SUM(oi.Quantity * oi.UnitPrice) * 100, 2)         AS gross_profit_margin_pct,
    ROUND(SUM(oi.Quantity * oi.UnitPrice)
          / COUNT(DISTINCT oi.OrderID), 2)                    AS average_order_value
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID;


-- =====================================================================
-- TASK 2 : PRODUCT PERFORMANCE
-- =====================================================================

-- Q2.1 Top five products by revenue
SELECT p.ProductID, p.ProductName, p.Category,
       ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS revenue
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY revenue DESC
LIMIT 5;

-- Q2.2 Top five products by quantity sold
SELECT p.ProductID, p.ProductName, p.Category,
       SUM(oi.Quantity) AS quantity_sold
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY quantity_sold DESC
LIMIT 5;

-- Q2.3 Product with the lowest revenue (among products that have sales)
SELECT p.ProductID, p.ProductName, p.Category,
       ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS revenue
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY revenue ASC
LIMIT 1;

-- Q2.4 Product with the highest estimated gross profit
SELECT p.ProductID, p.ProductName, p.Category,
       ROUND(SUM(oi.Quantity * (oi.UnitPrice - p.Cost)), 2) AS gross_profit
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY gross_profit DESC
LIMIT 1;

-- Q2.5 Products that have no sales (LEFT JOIN, keep rows with no match)
SELECT p.ProductID, p.ProductName, p.Category, p.Price, p.IsActive
FROM Products p
LEFT JOIN OrderItems oi ON oi.ProductID = p.ProductID
WHERE oi.ProductID IS NULL;

-- Q2.6 Compare active and inactive products based on their sales
-- (IsActive is assumed to be 1 = active, 0 = inactive)
SELECT CASE WHEN p.IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS product_status,
       COUNT(DISTINCT p.ProductID)                                 AS number_of_products,
       COUNT(DISTINCT oi.ProductID)                                AS products_with_sales,
       COALESCE(SUM(oi.Quantity), 0)                               AS quantity_sold,
       ROUND(COALESCE(SUM(oi.Quantity * oi.UnitPrice), 0), 2)      AS revenue,
       ROUND(COALESCE(SUM(oi.Quantity * (oi.UnitPrice - p.Cost)), 0), 2) AS gross_profit
FROM Products p
LEFT JOIN OrderItems oi ON oi.ProductID = p.ProductID
GROUP BY product_status;


-- =====================================================================
-- TASK 3 : CATEGORY PERFORMANCE
-- =====================================================================

-- Q3.1 Category with the highest revenue
SELECT p.Category,
       ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS revenue
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY p.Category
ORDER BY revenue DESC
LIMIT 1;

-- Q3.2 Category with the highest gross profit
SELECT p.Category,
       ROUND(SUM(oi.Quantity * (oi.UnitPrice - p.Cost)), 2) AS gross_profit
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY p.Category
ORDER BY gross_profit DESC
LIMIT 1;

-- Q3.3 Quantity sold in each category
SELECT p.Category,
       SUM(oi.Quantity) AS quantity_sold
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY p.Category
ORDER BY quantity_sold DESC;

-- Q3.4 Average revenue per product in each category
-- (divides by ALL products in the category, including unsold ones)
SELECT p.Category,
       COUNT(DISTINCT p.ProductID)                                    AS products_in_category,
       ROUND(COALESCE(SUM(oi.Quantity * oi.UnitPrice), 0), 2)         AS category_revenue,
       ROUND(COALESCE(SUM(oi.Quantity * oi.UnitPrice), 0)
             / COUNT(DISTINCT p.ProductID), 2)                        AS avg_revenue_per_product
FROM Products p
LEFT JOIN OrderItems oi ON oi.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY avg_revenue_per_product DESC;

-- Q3.5 Weakest-performing category (lowest revenue)
SELECT p.Category,
       ROUND(COALESCE(SUM(oi.Quantity * oi.UnitPrice), 0), 2) AS revenue,
       COALESCE(SUM(oi.Quantity), 0)                          AS quantity_sold
FROM Products p
LEFT JOIN OrderItems oi ON oi.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY revenue ASC
LIMIT 1;

-- Q3.ALL Category summary table (useful for the report)
SELECT p.Category,
       COUNT(DISTINCT p.ProductID)                                         AS products,
       COALESCE(SUM(oi.Quantity), 0)                                       AS quantity_sold,
       ROUND(COALESCE(SUM(oi.Quantity * oi.UnitPrice), 0), 2)              AS revenue,
       ROUND(COALESCE(SUM(oi.Quantity * (oi.UnitPrice - p.Cost)), 0), 2)   AS gross_profit
FROM Products p
LEFT JOIN OrderItems oi ON oi.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY revenue DESC;


-- =====================================================================
-- TASK 4 : SALES CHANNEL INVESTIGATION
-- =====================================================================

-- Q4.1 Orders, revenue, gross profit, AOV and % contribution for each channel
SELECT o.SalesChannel,
       COUNT(DISTINCT o.OrderID)                                        AS total_orders,
       ROUND(SUM(oi.Quantity * oi.UnitPrice), 2)                        AS total_revenue,
       ROUND(SUM(oi.Quantity * (oi.UnitPrice - p.Cost)), 2)             AS gross_profit,
       ROUND(SUM(oi.Quantity * oi.UnitPrice)
             / COUNT(DISTINCT o.OrderID), 2)                            AS average_order_value,
       ROUND(SUM(oi.Quantity * oi.UnitPrice) * 100
             / (SELECT SUM(Quantity * UnitPrice) FROM OrderItems), 2)   AS revenue_contribution_pct
FROM Orders o
JOIN OrderItems oi ON oi.OrderID  = o.OrderID
JOIN Products p    ON p.ProductID = oi.ProductID
GROUP BY o.SalesChannel
ORDER BY total_revenue DESC;

-- Q4.2 Gross profit margin by channel (extra evidence for "which channel is best")
SELECT o.SalesChannel,
       ROUND(SUM(oi.Quantity * (oi.UnitPrice - p.Cost))
             / SUM(oi.Quantity * oi.UnitPrice) * 100, 2) AS gross_profit_margin_pct
FROM Orders o
JOIN OrderItems oi ON oi.OrderID  = o.OrderID
JOIN Products p    ON p.ProductID = oi.ProductID
GROUP BY o.SalesChannel
ORDER BY gross_profit_margin_pct DESC;


-- =====================================================================
-- TASK 5 : MONTHLY SALES ANALYSIS
-- (LAG() needs MySQL 8.0 or above)
-- =====================================================================

-- Q5.1 / Q5.3 Monthly revenue and gross profit
SELECT DATE_FORMAT(o.OrderDate, '%Y-%m')                         AS sales_month,
       ROUND(SUM(oi.Quantity * oi.UnitPrice), 2)                 AS revenue,
       ROUND(SUM(oi.Quantity * (oi.UnitPrice - p.Cost)), 2)      AS gross_profit
FROM Orders o
JOIN OrderItems oi ON oi.OrderID  = o.OrderID
JOIN Products p    ON p.ProductID = oi.ProductID
GROUP BY sales_month
ORDER BY sales_month;

-- Q5.1 Month with the highest revenue
SELECT DATE_FORMAT(o.OrderDate, '%Y-%m')         AS sales_month,
       ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS revenue
FROM Orders o
JOIN OrderItems oi ON oi.OrderID = o.OrderID
GROUP BY sales_month
ORDER BY revenue DESC
LIMIT 1;

-- Q5.2 Month with the lowest revenue
SELECT DATE_FORMAT(o.OrderDate, '%Y-%m')         AS sales_month,
       ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS revenue
FROM Orders o
JOIN OrderItems oi ON oi.OrderID = o.OrderID
GROUP BY sales_month
ORDER BY revenue ASC
LIMIT 1;

-- Q5.4 Revenue compared with the previous month (change and % change)
WITH monthly AS (
    SELECT DATE_FORMAT(o.OrderDate, '%Y-%m')         AS sales_month,
           SUM(oi.Quantity * oi.UnitPrice)           AS revenue
    FROM Orders o
    JOIN OrderItems oi ON oi.OrderID = o.OrderID
    GROUP BY sales_month
)
SELECT sales_month,
       ROUND(revenue, 2)                                              AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY sales_month), 2)             AS previous_month_revenue,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY sales_month), 2)   AS change_amount,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY sales_month))
             / LAG(revenue) OVER (ORDER BY sales_month) * 100, 2)    AS change_pct
FROM monthly
ORDER BY sales_month;

-- Q5.5 Growth or decline: first month vs last month, and number of up/down months
WITH monthly AS (
    SELECT DATE_FORMAT(o.OrderDate, '%Y-%m')         AS sales_month,
           SUM(oi.Quantity * oi.UnitPrice)           AS revenue
    FROM Orders o
    JOIN OrderItems oi ON oi.OrderID = o.OrderID
    GROUP BY sales_month
),
changes AS (
    SELECT sales_month, revenue,
           revenue - LAG(revenue) OVER (ORDER BY sales_month) AS diff
    FROM monthly
)
SELECT
    (SELECT ROUND(revenue, 2) FROM monthly ORDER BY sales_month ASC  LIMIT 1) AS first_month_revenue,
    (SELECT ROUND(revenue, 2) FROM monthly ORDER BY sales_month DESC LIMIT 1) AS last_month_revenue,
    SUM(CASE WHEN diff > 0 THEN 1 ELSE 0 END)                                 AS months_with_growth,
    SUM(CASE WHEN diff < 0 THEN 1 ELSE 0 END)                                 AS months_with_decline
FROM changes;


-- =====================================================================
-- TASK 6 : CUSTOMER BEHAVIOUR ANALYSIS
-- =====================================================================

-- Q6.1 Top five customers by spending
SELECT c.CustomerID, c.CustomerName, c.City,
       ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS total_spent
FROM Customers c
JOIN Orders o       ON o.CustomerID = c.CustomerID
JOIN OrderItems oi  ON oi.OrderID   = o.OrderID
GROUP BY c.CustomerID, c.CustomerName, c.City
ORDER BY total_spent DESC
LIMIT 5;

-- Q6.2 Top five customers by number of orders
SELECT c.CustomerID, c.CustomerName, c.City,
       COUNT(o.OrderID) AS number_of_orders
FROM Customers c
JOIN Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.City
ORDER BY number_of_orders DESC
LIMIT 5;

-- Q6.3 Average spending per customer
-- (a) among customers who actually bought
-- (b) among ALL registered customers
SELECT
    ROUND(SUM(oi.Quantity * oi.UnitPrice) / COUNT(DISTINCT o.CustomerID), 2)               AS avg_spend_buying_customers,
    ROUND(SUM(oi.Quantity * oi.UnitPrice) / (SELECT COUNT(*) FROM Customers), 2)           AS avg_spend_all_customers
FROM Orders o
JOIN OrderItems oi ON oi.OrderID = o.OrderID;

-- Q6.4 Repeat customers (more than one order)
SELECT c.CustomerID, c.CustomerName,
       COUNT(o.OrderID) AS number_of_orders
FROM Customers c
JOIN Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName
HAVING COUNT(o.OrderID) > 1
ORDER BY number_of_orders DESC;

-- Q6.5 Repeat customers vs one-time customers
WITH customer_summary AS (
    SELECT o.CustomerID,
           COUNT(DISTINCT o.OrderID)                  AS orders_count,
           SUM(oi.Quantity * oi.UnitPrice)            AS total_spent
    FROM Orders o
    JOIN OrderItems oi ON oi.OrderID = o.OrderID
    GROUP BY o.CustomerID
)
SELECT CASE WHEN orders_count > 1 THEN 'Repeat customer' ELSE 'One-time customer' END AS customer_type,
       COUNT(*)                                          AS number_of_customers,
       ROUND(SUM(total_spent), 2)                        AS total_revenue,
       ROUND(AVG(total_spent), 2)                        AS avg_spend_per_customer,
       ROUND(AVG(orders_count), 2)                       AS avg_orders_per_customer,
       ROUND(SUM(total_spent) * 100
             / (SELECT SUM(total_spent) FROM customer_summary), 2) AS revenue_share_pct
FROM customer_summary
GROUP BY customer_type;

-- Q6.6 Customers who registered but never placed an order
SELECT c.CustomerID, c.CustomerName, c.Email, c.City, c.CustomerSegment
FROM Customers c
LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
WHERE o.OrderID IS NULL;

-- Q6.6b Count of such customers
SELECT COUNT(*) AS customers_without_orders
FROM Customers c
LEFT JOIN Orders o ON o.CustomerID = c.CustomerID
WHERE o.OrderID IS NULL;

-- ============================ END OF FILE ============================
