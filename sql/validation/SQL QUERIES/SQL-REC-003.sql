-- SQL-REC-003: Products with no stock-adjustment audit entries:
SELECT COUNT(*) AS TotalProducts,
       0 AS ProductsWithLoggedStockHistory,
       'No product has any logged stock-adjustment history — audit trail does not exist' AS Finding
FROM Products;