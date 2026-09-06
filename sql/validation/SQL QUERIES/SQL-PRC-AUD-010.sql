-- SQL-PRC-AUD-010: Orders billed with a nonzero Total but no corresponding OrderItems rows

SELECT o.Id, o.Total
FROM Orders o
WHERE o.Total > 0
  AND NOT EXISTS (SELECT 1 FROM OrderItems oi WHERE oi.OrderId = o.Id);