-- SQL-REC-002: Products with negative stock
SELECT Id, Sku, StockQuantity
FROM Products
WHERE StockQuantity < 0;