-- SQL-PRC-AUD-007: [REVISED] Dual-storage item-count integrity — number of

SELECT
    o.Id AS OrderId,
    (LEN(o.Items) - LEN(REPLACE(o.Items, ',', '')) + 1) AS TextItemCount,
    (SELECT COUNT(*) FROM OrderItems oi WHERE oi.OrderId = o.Id) AS RowItemCount
FROM Orders o
WHERE (LEN(o.Items) - LEN(REPLACE(o.Items, ',', '')) + 1) <> (SELECT COUNT(*) FROM OrderItems oi WHERE oi.OrderId = o.Id);