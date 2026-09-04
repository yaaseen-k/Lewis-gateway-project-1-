-- SQL-PRC-AUD-013: Duplicate line items within the same order (possible double-billing)
SELECT OrderId, ProductId, COUNT(*) AS LineCount
FROM OrderItems
GROUP BY OrderId, ProductId
HAVING COUNT(*) > 1;