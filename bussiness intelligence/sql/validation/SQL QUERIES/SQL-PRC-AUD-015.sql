-- SQL-PRC-AUD-015: Full order-level audit sweep for the last 30 days
DECLARE @StartDate DATETIME2 = DATEADD(DAY, -30, GETUTCDATE());

SELECT o.Id AS OrderId, o.CreatedAtUtc,
       o.Total, SUM(oi.LineTotal) AS ComputedTotal,
       ABS(o.Total - SUM(oi.LineTotal)) AS Variance
FROM Orders o
JOIN OrderItems oi ON oi.OrderId = o.Id
WHERE o.CreatedAtUtc >= @StartDate
GROUP BY o.Id, o.CreatedAtUtc, o.Total
HAVING ABS(o.Total - SUM(oi.LineTotal)) > 0.01;


