-- SQL-PRC-AUD-011: Quantity * UnitPrice mismatch with stored LineTotal (tamper/rounding check)
SELECT Id, OrderId, ProductId, Quantity, UnitPrice, LineTotal,
       ROUND(Quantity * UnitPrice, 2) AS RecalculatedSubtotal
FROM OrderItems
WHERE ROUND(LineTotal, 2) <> ROUND(Quantity * UnitPrice, 2);