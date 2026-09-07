-- SQL-REC-010: Flag products with confirmed sales activity where StockQuantity was never decremented.
SELECT p.Id, p.Sku, p.StockQuantity, sold.TotalSold
FROM Products p
JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS TotalSold
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.Status = 'Delivered'
    GROUP BY oi.ProductId
) sold ON sold.ProductId = p.Id
WHERE sold.TotalSold > 20 
  AND p.StockQuantity % 10 = 0; 
