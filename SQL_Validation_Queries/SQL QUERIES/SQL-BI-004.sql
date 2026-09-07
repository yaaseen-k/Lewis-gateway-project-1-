-- SQL-BI-004: Inventory turnover ratio per category
SELECT p.CategoryId, p.Category,
       SUM(oi.Quantity) AS UnitsSold,
       AVG(p.StockQuantity) AS AvgStockHeld,
       CAST(SUM(oi.Quantity) AS FLOAT) / NULLIF(AVG(p.StockQuantity), 0) AS TurnoverRatio
FROM Products p
LEFT JOIN OrderItems oi ON oi.ProductId = p.Id
LEFT JOIN Orders o ON o.Id = oi.OrderId AND o.Status = 'Delivered'
GROUP BY p.CategoryId, p.Category
ORDER BY TurnoverRatio DESC;