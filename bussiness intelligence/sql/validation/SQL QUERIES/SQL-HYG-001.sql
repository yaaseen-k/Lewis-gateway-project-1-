--SQL-HYG-001: Duplicate SKUs

SELECT Sku, COUNT(*) AS Occurrences
FROM Products
GROUP BY Sku
HAVING COUNT(*) > 1;