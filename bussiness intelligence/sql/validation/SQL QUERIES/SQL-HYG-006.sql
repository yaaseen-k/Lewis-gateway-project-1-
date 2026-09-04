-- SQL-HYG-006: Broken/suspicious description text

SELECT Id, Sku, Description
FROM Products
WHERE Description IS NULL
   OR LTRIM(RTRIM(Description)) = ''
   OR Description LIKE '%<script%'
   OR Description LIKE '%<%>%'
   OR LEN(Description) > 4000;