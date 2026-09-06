-- SQL-REC-006: Reconciliation
SELECT p.Id, p.Sku, p.StockQuantity AS CurrentStock, ISNULL(sold.TotalSold, 0) AS TotalUnitsSoldEver
FROM Products p
LEFT JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS TotalSold
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.Status = 'Delivered'
    GROUP BY oi.ProductId
) sold ON sold.ProductId = p.Id
ORDER BY TotalUnitsSoldEver DESC;
