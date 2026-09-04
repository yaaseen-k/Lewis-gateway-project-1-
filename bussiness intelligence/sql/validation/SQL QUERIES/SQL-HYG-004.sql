-- SQL-HYG-004: Illogical discount — OldPrice lower than current Price

SELECT Id, Sku, Price, OldPrice
FROM Products
WHERE OldPrice IS NOT NULL AND OldPrice < Price;