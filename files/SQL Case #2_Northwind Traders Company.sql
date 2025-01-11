---[1] Employee Analysis
--1. Find employees hired before January 1, 1994, sorted from newest to oldest hire.
SELECT 
    EmployeeID, 
    FirstName, 
    LastName, 
    HireDate
FROM 
    Employees
WHERE 
    HireDate < '1994-01-01'
ORDER BY 
    HireDate DESC;
	
--2. Determine employees who processed over $100,000 in total value and show their 10 most recent orders.
-- Step 1: Find employees who processed over $100,000 in total sales
WITH EmployeeSales AS (
    SELECT e.EmployeeID, e.FirstName, e.LastName, SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalSales
    FROM Employees AS e
    JOIN Orders AS o ON e.EmployeeID = o.EmployeeID
    JOIN OrderDetails AS od ON o.OrderID = od.OrderID
    GROUP BY e.EmployeeID, e.FirstName, e.LastName
    HAVING SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) > 100000)
	
-- Step 2: Get 10 most recent orders for qualifying employees
SELECT e.FirstName, e.LastName, o.OrderID, o.OrderDate, 
    ROUND(CAST(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS NUMERIC), 2) AS OrderValue
FROM EmployeeSales AS es
JOIN Employees AS e ON es.EmployeeID = e.EmployeeID
JOIN Orders AS o ON e.EmployeeID = o.EmployeeID
JOIN OrderDetails AS od ON o.OrderID = od.OrderID
GROUP BY e.EmployeeID, e.FirstName, e.LastName, o.OrderID, o.OrderDate
ORDER BY e.EmployeeID, o.OrderDate DESC
LIMIT 10;

--3. Classify employees by the number of orders processed: High (≥75), Mid (50-74), Low (<50).
SELECT 
    e.EmployeeID, 
    e.FirstName || ' ' || e.LastName AS EmployeeName,
    COUNT(o.OrderID) AS OrdersProcessed,
    CASE
        WHEN COUNT(o.OrderID) >= 75 THEN 'High'
        WHEN COUNT(o.OrderID) BETWEEN 50 AND 74 THEN 'Mid'
        ELSE 'Low'
    END AS Classification
FROM Employees e
LEFT JOIN Orders o ON e.EmployeeID = o.EmployeeID
GROUP BY e.EmployeeID, e.FirstName, e.LastName
ORDER BY OrdersProcessed DESC;

---[3] Customer Insights
--4. Find high-value customers who made orders worth $10,000 or more in 1996.
SELECT 
    c.CustomerID, 
    c.CompanyName AS CustomerName, 
    ROUND(SUM(od.Quantity * od.UnitPrice * (1 - od.Discount))::NUMERIC, 2) AS TotalOrderValue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE o.OrderDate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY c.CustomerID, c.CompanyName
HAVING SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) >= 10000
ORDER BY TotalOrderValue DESC;

--5. Report the company name, contact name, and number of orders for the top 5 customers.
SELECT c.CustomerID, c.ContactName, c.CompanyName, COUNT(o.OrderID) AS NumberOfOrders
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID
ORDER BY NumberOfOrders DESC
LIMIT 5;

--6. Show customer IDs and the number of orders for customers exceeding the average orders per customer.
SELECT c.CustomerID, COUNT(o.OrderID) AS NumberOfOrders
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID
HAVING 
	COUNT(o.OrderID) >
        (SELECT AVG(NumberOfOrders)
        FROM (SELECT COUNT(o.OrderID) AS NumberOfOrders
            FROM Customers c
            JOIN Orders o ON c.CustomerID = o.CustomerID
            GROUP BY c.CustomerID) SubQuery)

ORDER BY NumberOfOrders DESC;

---[4] Order and Shipping Analysis
--7. Show orders shipping to Brazil, Mexico, Argentina, and Venezuela, sorted by freight value.
SELECT o.OrderID, o.ShipCountry, o.Freight
FROM Orders o
WHERE o.ShipCountry IN ('Brazil', 'Mexico', 'Argentina', 'Venezuela')
ORDER BY o.Freight DESC;

--8. Find the three ship countries with the highest average freight for Speedy Express in 1996.
SELECT o.ShipCountry, ROUND(AVG(o.Freight)::NUMERIC, 2) AS AverageFreight
FROM Orders o
JOIN Shippers s ON o.ShipVia = s.ShipperID
WHERE s.CompanyName = 'Speedy Express'
    AND o.OrderDate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY o.ShipCountry
ORDER BY AverageFreight DESC
LIMIT 3;

--9. Find salespeople with at least 5 late orders.
SELECT e.EmployeeID, e.FirstName || ' ' || e.LastName AS EmployeeName, COUNT(o.OrderID) AS LateOrders
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
WHERE o.RequiredDate < o.ShippedDate
GROUP BY e.EmployeeID, e.FirstName, e.LastName
HAVING COUNT(o.OrderID) >= 5
ORDER BY LateOrders DESC;

---[5] Product and Inventory Insights
--10. Identify products requiring reordering based on stock and order thresholds. 
--Definition: ReorderLevel is the threshold quantity below which the product needs to be reordered.
--Defintion: UnitsInStock + UnitsOnOrder <= ReorderLevel checks if the total stock (including pending orders) 
--is less than or equal to the reorder threshold, indicating that the product needs reordering.
SELECT p.ProductID, p.ProductName, p.UnitsInStock, p.UnitsOnOrder, p.ReorderLevel
FROM Products p
WHERE p.UnitsInStock + p.UnitsOnOrder <= p.ReorderLevel
ORDER BY p.ReorderLevel DESC;

--11. Produce a report for products with prices above the average but units in stock below average.
WITH AverageValues AS (
    SELECT AVG(p.UnitPrice) AS AvgPrice, AVG(p.UnitsInStock) AS AvgStock
    FROM Products p)
SELECT p.ProductID, p.ProductName, p.UnitPrice, p.UnitsInStock
FROM Products p
JOIN AverageValues a 
ON p.UnitPrice > a.AvgPrice AND p.UnitsInStock < a.AvgStock
ORDER BY p.UnitPrice DESC;

--12. Identify product categories with average total discounts exceeding the overall average discount.
SELECT c.CategoryID, c.CategoryName, ROUND(AVG(od.Discount)::NUMERIC, 4) AS AvgCategoryDiscount
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY c.CategoryID, c.CategoryName
HAVING AVG(od.Discount) > (SELECT AVG(Discount) FROM OrderDetails)
ORDER BY AvgCategoryDiscount DESC;