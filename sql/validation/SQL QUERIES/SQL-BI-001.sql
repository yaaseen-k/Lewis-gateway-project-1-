-- SQL-BI-001: Top 10 best-selling products by units sold
SELECT TOP 10 p.Sku, p.Title, SUM(oi.Quantity) AS UnitsSold
FROM OrderItems oi
JOIN Products p ON p.Id = oi.ProductId
JOIN Orders o ON o.Id = oi.OrderId
WHERE o.Status = 'Delivered'
GROUP BY p.Sku, p.Title
ORDER BY UnitsSold DESC;