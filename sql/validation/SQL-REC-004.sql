-- SQL-REC-004: Cannot check for duplicate audit log entries when no
-- audit log exist.
SELECT JSON_VALUE(Details, '$.ProductId') AS ProductId,
       JSON_VALUE(Details, '$.NewStockQuantity') AS NewStockQuantity,
       TimestampUtc, COUNT(*) AS DuplicateCount
FROM AuditLogs
WHERE EventType = 'product.stock.updated'
GROUP BY JSON_VALUE(Details, '$.ProductId'), JSON_VALUE(Details, '$.NewStockQuantity'), TimestampUtc
HAVING COUNT(*) > 1;

