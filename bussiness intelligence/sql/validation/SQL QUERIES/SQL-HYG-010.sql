-- SQL-HYG-010: Stale cart pricing

SELECT ci.InternalId, ci.Id AS ProductId, ci.Title, ci.Price AS CartPrice, p.Price AS CurrentPrice
FROM CartItems ci
JOIN Products p ON p.Id = ci.Id
WHERE ci.Price <> p.Price;
