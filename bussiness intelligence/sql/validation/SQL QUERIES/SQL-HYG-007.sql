-- SQL-HYG-007: Orphaned CategoryId 

SELECT p.Id, p.Sku, p.CategoryId
FROM Products p
LEFT JOIN Categories c ON c.Id = p.CategoryId
WHERE c.Id IS NULL;