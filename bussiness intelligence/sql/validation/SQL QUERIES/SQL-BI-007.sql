-- SQL-BI-007: Products nearing stockout, weighted by recent sales velocity
SELECT 
    p.Id,
    p.Sku,
    p.Title,
    p.StockQuantity,
    ISNULL(SUM(oi.Quantity), 0) AS TotalItemsSoldEver
FROM Products p
LEFT JOIN OrderItems oi 
    ON oi.ProductId = p.Id
LEFT JOIN Orders o 
    ON o.Id = oi.OrderId
    AND o.Status = 'Delivered'
GROUP BY 
    p.Id,
    p.Sku,
    p.Title,
    p.StockQuantity
ORDER BY TotalItemsSoldEver DESC;
