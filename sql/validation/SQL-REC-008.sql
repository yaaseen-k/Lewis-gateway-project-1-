-- SQL-REC-008: Oversell detection — pending order quantity exceeds available
-- stock.
SELECT p.Id, p.Sku, p.StockQuantity, pending.PendingQty
FROM Products p
JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS PendingQty
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.Status IN ('Pending', 'Confirmed', 'Shipped')
    GROUP BY oi.ProductId
) pending ON pending.ProductId = p.Id
WHERE pending.PendingQty > p.StockQuantity;