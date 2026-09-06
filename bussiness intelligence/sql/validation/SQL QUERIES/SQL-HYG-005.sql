-- SQL-HYG-005: Empty-string Title

SELECT Id, Sku, Title
FROM Products
WHERE LTRIM(RTRIM(Title)) = '';