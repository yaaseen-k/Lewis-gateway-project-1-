-- SQL-PRC-AUD-005: Order-level rollup integrity — Orders.Total vs SUM(OrderItems.LineTotal)
SELECT o.Id, o.Total AS StoredTotal, SUM(oi.LineTotal) AS ComputedTotal
FROM Orders o
JOIN OrderItems oi ON oi.OrderId = o.Id
GROUP BY o.Id, o.Total
HAVING ROUND(o.Total, 2) <> ROUND(SUM(oi.LineTotal), 2);
