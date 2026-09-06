-- SQL-REC-001:
SELECT Id, Sku, StockQuantity AS CurrentStock
FROM Products
ORDER BY Sku;