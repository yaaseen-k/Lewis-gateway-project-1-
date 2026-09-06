-- SQL-PRC-AUD-002: Line-level arithmetic — Quantity * UnitPrice should equal LineTotal
SELECT Id, OrderId, ProductId, Quantity, UnitPrice, LineTotal,
       ROUND(Quantity * UnitPrice, 2) AS RecalculatedLineTotal
FROM OrderItems
WHERE ROUND(LineTotal, 2) <> ROUND(Quantity * UnitPrice, 2);
