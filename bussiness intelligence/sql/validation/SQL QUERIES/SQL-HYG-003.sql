-- SQL-HYG-003: Negative price fields (no CHECK constraint prevents this)

SELECT Id, Sku, Price, OldPrice
FROM Products
WHERE Price < 0 OR OldPrice < 0;
