-- SQL-REC-012:
SELECT
    (SELECT SUM(oi.Quantity)
     FROM OrderItems oi JOIN Orders o ON o.Id = oi.OrderId
     WHERE o.Status = 'Delivered') AS TotalUnitsSoldEver,
    (SELECT SUM(StockQuantity) FROM Products) AS CurrentTotalStockOnHand,
    'TotalReceived cannot be computed - no stock-increase audit trail exists' AS Note;
