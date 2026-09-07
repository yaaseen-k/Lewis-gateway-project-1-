-- SQL-BI-003: Dead stock report — in stock but no sales in the last 90 days
SELECT p.Id, p.Sku, p.Title, p.StockQuantity
FROM Products p
WHERE p.StockQuantity > 0
  AND p.Id NOT IN (
      SELECT oi.ProductId
      FROM OrderItems oi
      JOIN Orders o ON o.Id = oi.OrderId
      WHERE o.CreatedAtUtc >= DATEADD(DAY, -90, GETUTCDATE())
        AND o.Status = 'Delivered'
  );