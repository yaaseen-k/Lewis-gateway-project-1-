-- SQL-BI-009: "Best Seller" tag validation against actual sales rank
WITH Ranked AS (
    SELECT p.Id, p.Sku, p.Tag, SUM(oi.Quantity) AS UnitsSold,
           RANK() OVER (ORDER BY SUM(oi.Quantity) DESC) AS SalesRank
    FROM Products p
    LEFT JOIN OrderItems oi ON oi.ProductId = p.Id
    LEFT JOIN Orders o ON o.Id = oi.OrderId AND o.Status = 'Delivered'
    GROUP BY p.Id, p.Sku, p.Tag
)
SELECT * FROM Ranked
WHERE Tag = 'Best Seller' AND SalesRank > 20; -- adjust "top N" threshold as needed