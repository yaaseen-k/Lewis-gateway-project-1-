-- SQL-PRC-AUD-001: Charged price vs. current catalog price
SELECT oi.OrderId, oi.ProductId, oi.UnitPrice AS ChargedPrice, p.Price AS CurrentCatalogPrice, o.CreatedAtUtc
FROM OrderItems oi
JOIN Products p ON p.Id = oi.ProductId
JOIN Orders o ON o.Id = oi.OrderId
WHERE oi.UnitPrice <> p.Price
ORDER BY o.CreatedAtUtc DESC;