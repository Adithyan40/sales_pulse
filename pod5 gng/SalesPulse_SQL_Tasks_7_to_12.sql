-- ============================================================
-- Task 7 – Customer Order History
-- ============================================================

SELECT
    o.OrderID,
    o.OrderDate,
    o.OrderStatus,
    o.ShipCity,
    o.SalesChannel,
    COALESCE(
        GROUP_CONCAT(
            CONCAT(p.ProductName, ' (Qty: ', oi.Quantity, ')')
            ORDER BY p.ProductName SEPARATOR ', '
        ),
        'No items'
    ) AS ProductsPurchased,
    COALESCE(SUM(oi.Quantity * p.UnitPrice), 0) AS OrderTotal
FROM Orders AS o
LEFT JOIN OrderItems AS oi
    ON oi.OrderID = o.OrderID
LEFT JOIN Products AS p
    ON p.ProductID = oi.ProductID
WHERE o.CustomerID = ?
GROUP BY
    o.OrderID,
    o.OrderDate,
    o.OrderStatus,
    o.ShipCity,
    o.SalesChannel
ORDER BY o.OrderDate DESC, o.OrderID DESC;


-- ============================================================
-- Task 8 – Admin Order Details
-- ============================================================

SELECT
    o.OrderID,
    c.CustomerName,
    o.OrderDate,
    o.ShipCity,
    o.OrderStatus,
    o.SalesChannel,
    p.ProductName,
    oi.Quantity,
    p.UnitPrice AS ProductPrice,
    (oi.Quantity * p.UnitPrice) AS ItemRevenue
FROM Orders AS o
INNER JOIN Customers AS c
    ON c.CustomerID = o.CustomerID
INNER JOIN OrderItems AS oi
    ON oi.OrderID = o.OrderID
INNER JOIN Products AS p
    ON p.ProductID = oi.ProductID
WHERE o.OrderID = ?
ORDER BY p.ProductName;


-- ============================================================
-- Task 9 – Application SQL Queries
-- ============================================================

-- 9.1 Display customers with optional search and city filter
SELECT
    CustomerID, CustomerName, City, State, Email,
    CustomerSegment, JoinDate
FROM Customers
WHERE (
    ? IS NULL
    OR CustomerName LIKE CONCAT('%', ?, '%')
    OR CustomerID LIKE CONCAT('%', ?, '%')
    OR Email LIKE CONCAT('%', ?, '%')
)
AND (? IS NULL OR City = ?)
ORDER BY CustomerName;


-- 9.2 Display a customer's order history
SELECT
    o.OrderID,
    o.OrderDate,
    o.OrderStatus,
    o.ShipCity,
    o.SalesChannel,
    COALESCE(SUM(oi.Quantity * p.UnitPrice), 0) AS OrderTotal
FROM Orders AS o
LEFT JOIN OrderItems AS oi ON oi.OrderID = o.OrderID
LEFT JOIN Products AS p ON p.ProductID = oi.ProductID
WHERE o.CustomerID = ?
GROUP BY
    o.OrderID, o.OrderDate, o.OrderStatus,
    o.ShipCity, o.SalesChannel
ORDER BY o.OrderDate DESC;


-- 9.3 Display complete details of one order
SELECT
    o.OrderID,
    c.CustomerName,
    o.OrderDate,
    o.ShipCity,
    o.OrderStatus,
    o.SalesChannel,
    p.ProductName,
    oi.Quantity,
    p.UnitPrice,
    (oi.Quantity * p.UnitPrice) AS ItemRevenue
FROM Orders AS o
INNER JOIN Customers AS c ON c.CustomerID = o.CustomerID
INNER JOIN OrderItems AS oi ON oi.OrderID = o.OrderID
INNER JOIN Products AS p ON p.ProductID = oi.ProductID
WHERE o.OrderID = ?
ORDER BY p.ProductName;


-- 9.4 Display products with categories and prices
SELECT
    ProductID, ProductName, Category,
    UnitPrice, UnitCost, IsActive
FROM Products
WHERE (? IS NULL OR Category = ?)
ORDER BY Category, ProductName;


-- 9.5 Display total spending for a selected customer
SELECT
    c.CustomerID,
    c.CustomerName,
    COALESCE(SUM(oi.Quantity * p.UnitPrice), 0) AS TotalSpending
FROM Customers AS c
LEFT JOIN Orders AS o ON o.CustomerID = c.CustomerID
LEFT JOIN OrderItems AS oi ON oi.OrderID = o.OrderID
LEFT JOIN Products AS p ON p.ProductID = oi.ProductID
WHERE c.CustomerID = ?
GROUP BY c.CustomerID, c.CustomerName;


-- 9.6 Search orders by status and date range
SELECT
    OrderID, CustomerID, OrderDate,
    ShipCity, OrderStatus, SalesChannel
FROM Orders
WHERE (? IS NULL OR OrderStatus = ?)
  AND OrderDate >= ?
  AND OrderDate < DATE_ADD(?, INTERVAL 1 DAY)
ORDER BY OrderDate DESC;


-- 9.7 Show active products for order selection
SELECT
    ProductID, ProductName, Category, UnitPrice
FROM Products
WHERE IsActive = 'Yes'
  AND UnitPrice > 0
ORDER BY Category, ProductName;


-- ============================================================
-- Task 10 – Database Performance: Index SQL
-- ============================================================

CREATE INDEX idx_orders_customer
    ON Orders(CustomerID);

CREATE INDEX idx_orders_orderdate
    ON Orders(OrderDate);

CREATE INDEX idx_orders_status
    ON Orders(OrderStatus);

CREATE INDEX idx_orderitems_order
    ON OrderItems(OrderID);

CREATE INDEX idx_orderitems_product
    ON OrderItems(ProductID);

CREATE INDEX idx_customers_name
    ON Customers(CustomerName);

CREATE INDEX idx_customers_email
    ON Customers(Email);


-- ============================================================
-- Task 11 – Data Security and Safe Database Access
-- ============================================================

-- 11.1 Unsafe example – do not use
-- sql = "SELECT * FROM Customers WHERE Email = '" + userInput + "'";


-- 11.2 Safer parameterized query
SELECT CustomerID, CustomerName, Email
FROM Customers
WHERE Email = ?;


-- 11.3 Validate a customer before showing their orders
SELECT CustomerID, CustomerName
FROM Customers
WHERE CustomerID = ?;


-- 11.4 Return only the signed-in customer's orders
SELECT OrderID, OrderDate, OrderStatus, ShipCity
FROM Orders
WHERE CustomerID = ?
ORDER BY OrderDate DESC;


-- ============================================================
-- Task 12 – Order Saving Process
-- ============================================================

START TRANSACTION;

-- Step 1
SELECT CustomerID
FROM Customers
WHERE CustomerID = ?
FOR UPDATE;

-- Step 2
SELECT ProductID, UnitPrice, UnitCost, IsActive
FROM Products
WHERE ProductID = ?
FOR UPDATE;

-- Step 3
INSERT INTO Orders
    (OrderID, CustomerID, OrderDate, ShipCity, OrderStatus, SalesChannel)
VALUES
    (?, ?, CURRENT_DATE(), ?, 'Pending', ?);

-- Step 4
INSERT INTO OrderItems
    (OrderItemID, OrderID, ProductID, Quantity)
VALUES
    (?, ?, ?, ?);

-- Step 5
COMMIT;

-- ROLLBACK;


-- Optional: verify the saved order total
SELECT
    o.OrderID,
    COALESCE(SUM(oi.Quantity * p.UnitPrice), 0) AS OrderTotal
FROM Orders AS o
LEFT JOIN OrderItems AS oi ON oi.OrderID = o.OrderID
LEFT JOIN Products AS p ON p.ProductID = oi.ProductID
WHERE o.OrderID = ?
GROUP BY o.OrderID;
