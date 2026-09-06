-- SQL-PRC-AUD-009: Zero, negative, or implausibly large quantities billed
SELECT * FROM OrderItems WHERE Quantity <= 0 OR Quantity > 10000;