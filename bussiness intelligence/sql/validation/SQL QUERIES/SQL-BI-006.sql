-- SQL-BI-006: Category-level revenue contribution
SELECT p.CategoryId, p.Category, SUM(oi.LineTotal) AS TotalRevenue
FROM OrderItems oi
JOIN Products p ON p.Id = oi.ProductId
JOIN Orders o ON o.Id = oi.OrderId
WHERE o.Status = 'Delivered'
GROUP BY p.CategoryId, p.Category
ORDER BY TotalRevenue DESC;