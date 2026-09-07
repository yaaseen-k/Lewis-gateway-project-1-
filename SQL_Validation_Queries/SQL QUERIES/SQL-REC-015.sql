-- SQL-REC-015: Full daily reconciliation summary.
DECLARE @ReportDate DATE = CAST(GETUTCDATE() AS DATE);

SELECT
    p.Id, p.Sku,
    ISNULL(day_sold.UnitsSold, 0) AS UnitsSoldToday,
    p.StockQuantity AS CurrentClosingStock
FROM Products p
LEFT JOIN (
    SELECT oi.ProductId, SUM(oi.Quantity) AS UnitsSold
    FROM OrderItems oi
    JOIN Orders o ON o.Id = oi.OrderId
    WHERE CAST(o.CreatedAtUtc AS DATE) = @ReportDate AND o.Status = 'Delivered'
    GROUP BY oi.ProductId
) day_sold ON day_sold.ProductId = p.Id;
