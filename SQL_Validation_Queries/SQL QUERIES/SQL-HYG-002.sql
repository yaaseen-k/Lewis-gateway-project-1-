-- SQL-HYG-002: Empty-string SKU

SELECT Id, Title, Sku
FROM Products
WHERE LTRIM(RTRIM(Sku)) = '';