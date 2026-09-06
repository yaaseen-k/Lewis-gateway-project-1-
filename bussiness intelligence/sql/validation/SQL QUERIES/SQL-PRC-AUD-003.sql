DECLARE @AssumedVatRate DECIMAL(5,4) = 0.15;
-- SQL-PRC-AUD-003: VAT-inclusive hypothesis check
SELECT Id, OrderId, ProductId, Quantity, UnitPrice, LineTotal,
       ROUND(Quantity * UnitPrice * (1 + @AssumedVatRate), 2) AS RecalculatedVatInclusiveTotal
FROM OrderItems
WHERE ROUND(LineTotal, 2) <> ROUND(Quantity * UnitPrice * (1 + @AssumedVatRate), 2);
