-- SQL-PRC-AUD-014: Discount tag vs. actual charged price reconciliation
SELECT oi.OrderId, oi.ProductId, p.Tag, p.OldPrice, oi.UnitPrice
FROM OrderItems oi
JOIN Products p ON p.Id = oi.ProductId
WHERE (p.Tag LIKE '%Sale%' OR p.Tag LIKE '%Discount%')
  AND p.OldPrice IS NOT NULL
  AND oi.UnitPrice >= p.OldPrice;