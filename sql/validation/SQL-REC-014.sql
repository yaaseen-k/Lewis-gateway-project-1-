-- SQL-REC-014: Schema-level check.
SELECT cc.name AS ConstraintName, cc.definition
FROM sys.check_constraints cc
JOIN sys.tables t ON t.object_id = cc.parent_object_id
WHERE t.name = 'Products' AND cc.definition LIKE '%StockQuantity%';