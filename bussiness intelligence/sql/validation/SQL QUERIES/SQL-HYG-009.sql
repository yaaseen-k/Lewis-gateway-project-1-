-- SQL-HYG-009: Orders.Date values 

SELECT Id, [Date]
FROM Orders
WHERE TRY_CONVERT(datetime2, [Date]) IS NULL;