-- SQL-BI-002: Top 10 products by total revenue generated
SELECT TOP 10 p.Sku, p.Title, SUM(oi.LineTotal) AS TotalRevenue
FROM OrderItems oi
JOIN Products p ON p.Id = oi.ProductId
JOIN Orders o ON o.Id = oi.OrderId
WHERE o.Status = 'Delivered'
GROUP BY p.Sku, p.Title
ORDER BY TotalRevenue DESC;