-- SQL-BI-005: Overstock risk — high stock, low sell-through in the last 90 days
SELECT p.Id, p.Sku, p.Title, p.StockQuantity, ISNULL(sold.UnitsSold, 0) AS UnitsSoldLast90Days
FROM Products p
LEFT JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS UnitsSold
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.CreatedAtUtc >= DATEADD(DAY, -90, GETUTCDATE()) AND o.Status = 'Delivered'
    GROUP BY oi.ProductId
) sold ON sold.ProductId = p.Id
WHERE p.StockQuantity > 50   -- adjust to your business definition of "high stock"
  AND ISNULL(sold.UnitsSold, 0) < 5; -- adjust threshold for "low sell-through"