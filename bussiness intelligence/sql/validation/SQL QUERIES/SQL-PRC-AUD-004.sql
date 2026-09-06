DECLARE @AssumedVatRate DECIMAL(10,2) = 0.15;
-- SQL-PRC-AUD-004: Implied VAT rate consistency check
SELECT Id, OrderId, ProductId,
       ROUND((LineTotal / NULLIF(Quantity * UnitPrice, 0)) - 1, 4) AS ImpliedVatRate
FROM OrderItems
WHERE ABS(ROUND((LineTotal / NULLIF(Quantity * UnitPrice, 0)) - 1, 4) - @AssumedVatRate) > 0.005;