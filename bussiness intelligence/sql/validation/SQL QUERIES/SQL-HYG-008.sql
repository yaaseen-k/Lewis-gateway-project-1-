-- SQL-HYG-008: Rating outside a valid 0–5 bound

SELECT Id, Sku, Rating
FROM Products
WHERE Rating < 0 OR Rating > 5;
