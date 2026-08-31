-- SQL-BI-008: Average order value, trended by month
SELECT
    FORMAT(CreatedAtUtc, 'yyyy-MM') AS OrderMonth,
    COUNT(*) AS OrderCount,
    AVG(Total) AS AvgOrderValue
FROM Orders
WHERE Status = 'Delivered'
GROUP BY FORMAT(CreatedAtUtc, 'yyyy-MM')
ORDER BY OrderMonth;