-- SQL-PRC-AUD-006: [REVISED] Dual-storage integrity — Orders.Items (free


WITH Split AS (
    SELECT o.Id AS OrderId, LTRIM(RTRIM(s.value)) AS ItemText
    FROM Orders o
    CROSS APPLY STRING_SPLIT(o.Items, ',') s
),
Parsed AS (
    SELECT OrderId, ItemText,
           CASE WHEN CHARINDEX('x ', REVERSE(ItemText)) > 0
                THEN LEN(ItemText) - CHARINDEX('x ', REVERSE(ItemText)) - 1
                ELSE NULL END AS SplitPos
    FROM Split
),
ParsedQty AS (
    SELECT OrderId,
           TRY_CAST(SUBSTRING(ItemText, SplitPos + 3, 20) AS INT) AS Qty
    FROM Parsed
    WHERE SplitPos IS NOT NULL
)
SELECT
    o.Id AS OrderId,
    ISNULL(txt.TextDerivedQty, 0) AS TextDerivedQty,
    ISNULL(row_sum.RowDerivedQty, 0) AS RowDerivedQty
FROM Orders o
LEFT JOIN (SELECT OrderId, SUM(Qty) AS TextDerivedQty FROM ParsedQty GROUP BY OrderId) txt ON txt.OrderId = o.Id
LEFT JOIN (SELECT OrderId, SUM(Quantity) AS RowDerivedQty FROM OrderItems GROUP BY OrderId) row_sum ON row_sum.OrderId = o.Id
WHERE ISNULL(txt.TextDerivedQty, 0) <> ISNULL(row_sum.RowDerivedQty, 0);