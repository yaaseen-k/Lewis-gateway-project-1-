-- SQL-BI-007: Products nearing stockout, weighted by recent sales velocity
SELECT p.Id, p.Sku, p.Title, p.StockQuantity,
       ISNULL(velocity.UnitsSoldLast30Days, 0) AS UnitsSoldLast30Days,
       CASE WHEN ISNULL(velocity.UnitsSoldLast30Days, 0) > 0
            THEN p.StockQuantity / (velocity.UnitsSoldLast30Days / 30.0)
            ELSE NULL END AS EstimatedDaysOfStockLeft
FROM Products p
LEFT JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS UnitsSoldLast30Days
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.CreatedAtUtc >= DATEADD(DAY, -30, GETUTCDATE()) AND o.Status = 'Delivered'
    GROUP BY oi.ProductId
) velocity ON velocity.ProductId = p.Id
WHERE p.StockQuantity < 20 -- adjust reorder threshold as needed
ORDER BY EstimatedDaysOfStockLeft ASC;