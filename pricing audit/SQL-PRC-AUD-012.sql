-- SQL-PRC-AUD-012: Orders billed against products currently marked inactive
SELECT oi.OrderId, oi.ProductId, p.IsActive, o.CreatedAtUtc
FROM OrderItems oi
JOIN Orders o ON o.Id = oi.OrderId
JOIN Products p ON p.Id = oi.ProductId
WHERE p.IsActive = 0;
