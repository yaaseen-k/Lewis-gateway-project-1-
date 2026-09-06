-- SQL-BI-010: Rating vs. sales volume correlation report
SELECT p.Id, p.Sku, p.Title, p.Rating, ISNULL(sold.UnitsSold, 0) AS UnitsSold,
       CASE
           WHEN p.Rating >= 4.5 AND ISNULL(sold.UnitsSold, 0) < 10 THEN 'High Rating / Low Sales'
           WHEN p.Rating <= 3.0 AND ISNULL(sold.UnitsSold, 0) > 50 THEN 'Low Rating / High Sales'
           ELSE 'Normal'
       END AS Flag
FROM Products p
LEFT JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS UnitsSold
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE o.Status = 'Delivered'
    GROUP BY oi.ProductId
) sold ON sold.ProductId = p.Id
WHERE (p.Rating >= 4.5 AND ISNULL(sold.UnitsSold, 0) < 10)
   OR (p.Rating <= 3.0 AND ISNULL(sold.UnitsSold, 0) > 50);
