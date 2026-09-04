-- Lewis Stores Database Validation Queries
-- Use these queries to verify data integrity and test layer synchronization
-- Required for QE testing coverage

USE [LewisStoresDb];
GO

-- ============================================================================
-- LAYER 1: DATA STRUCTURE VALIDATION QUERIES
-- ============================================================================

-- T-DB-INT-001: Verify all required tables exist
SELECT 
    TABLE_NAME as [TableName],
    'Exists' as [Status]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME;
GO

-- T-DB-INT-002: Verify table row counts
SELECT 
    OBJECT_NAME(p.object_id) as [TableName],
    SUM(p.rows) as [RowCount]
FROM sys.partitions p
WHERE p.index_id IN (0, 1) 
    AND OBJECT_SCHEMA_NAME(p.object_id) = 'dbo'
GROUP BY p.object_id
ORDER BY [TableName];
GO

-- ============================================================================
-- LAYER 2: REFERENCE INTEGRITY VALIDATION QUERIES
-- ============================================================================

-- T-DB-INT-003: Verify Orders have valid User references
SELECT 
    o.Id as [OrderId],
    o.UserId,
    u.Email,
    COUNT(*) as [RecordCount]
FROM Orders o
LEFT JOIN Users u ON o.UserId = u.Id
WHERE o.UserId IS NOT NULL AND u.Id IS NULL
GROUP BY o.Id, o.UserId, u.Email
ORDER BY o.Id;
GO

-- T-DB-INT-004: Verify Payment Methods reference valid Users
SELECT 
    pm.Id as [PaymentMethodId],
    pm.UserId,
    u.Email,
    COUNT(*) as [RecordCount]
FROM PaymentMethods pm
LEFT JOIN Users u ON pm.UserId = u.Id
WHERE u.Id IS NULL
GROUP BY pm.Id, pm.UserId, u.Email;
GO

-- T-DB-INT-005: Verify Support Cases reference valid Users
SELECT 
    sc.Id as [SupportCaseId],
    sc.UserId,
    u.Email as [CustomerEmail],
    au.Email as [AssignedAgentEmail]
FROM SupportCases sc
LEFT JOIN Users u ON sc.UserId = u.Id
LEFT JOIN Users au ON sc.AssignedToUserId = au.Id
WHERE u.Id IS NULL OR (sc.AssignedToUserId IS NOT NULL AND au.Id IS NULL);
GO

-- ============================================================================
-- LAYER 3: BUSINESS DATA VALIDATION QUERIES
-- ============================================================================

-- T-DB-INT-006: Order Total Calculation Verification
-- Compare order totals with calculated totals
SELECT 
    o.Id as [OrderId],
    o.Total as [StoredTotal],
    COALESCE(SUM(oi.LineTotal), 0) as [CalculatedTotal],
    COUNT(oi.Id) as [ItemCount],
    CASE WHEN o.Total = COALESCE(SUM(oi.LineTotal), 0) THEN 'Match' ELSE 'Mismatch' END as [Status]
FROM Orders o
LEFT JOIN OrderItems oi ON oi.OrderId = o.Id
GROUP BY o.Id, o.Total
ORDER BY o.Id;
GO

-- T-DB-INT-007: Product Inventory Consistency Check
-- Verify stock quantities are non-negative
SELECT 
    p.Id as [ProductId],
    p.Title,
    p.Sku,
    p.StockQuantity,
    CASE 
        WHEN p.StockQuantity < 0 THEN 'INVALID: Negative Stock'
        WHEN p.StockQuantity = 0 THEN 'OUT_OF_STOCK'
        ELSE 'VALID'
    END as [InventoryStatus]
FROM Products p
ORDER BY p.StockQuantity;
GO

-- T-DB-INT-008: User Account Validation
-- Verify all users have required fields
SELECT 
    u.Id,
    u.Email,
    CASE 
        WHEN u.Email IS NULL OR u.Email = '' THEN 'INVALID: Missing Email'
        WHEN u.FullName IS NULL OR u.FullName = '' THEN 'INVALID: Missing FullName'
        WHEN u.Role IS NULL OR u.Role = '' THEN 'INVALID: Missing Role'
        ELSE 'VALID'
    END as [ValidationStatus]
FROM Users u
ORDER BY u.Email;
GO

-- T-DB-INT-009: Payment Method Validation
-- Verify all payment methods have complete data
SELECT 
    pm.Id as [PaymentMethodId],
    u.Email,
    pm.Last4,
    pm.Brand,
    pm.Expiry,
    pm.IsDefault,
    CASE 
        WHEN pm.CardholderName IS NULL OR pm.CardholderName = '' THEN 'INVALID: Missing Cardholder Name'
        WHEN pm.Last4 IS NULL OR LEN(pm.Last4) < 4 THEN 'INVALID: Invalid Last4'
        WHEN pm.Expiry NOT LIKE '[0-1][0-9]/[0-9][0-9]' THEN 'INVALID: Invalid Expiry Format'
        ELSE 'VALID'
    END as [ValidationStatus]
FROM PaymentMethods pm
JOIN Users u ON pm.UserId = u.Id
ORDER BY u.Email, pm.Id;
GO

-- ============================================================================
-- LAYER 4: AUDIT & COMPLIANCE VALIDATION QUERIES
-- ============================================================================

-- T-DB-INT-010: Order Status Distribution
SELECT 
    Status as [OrderStatus],
    COUNT(*) as [OrderCount],
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Orders), 2) as [Percentage]
FROM Orders
GROUP BY Status
ORDER BY [OrderCount] DESC;
GO

-- T-DB-INT-011: Support Case Priority Distribution
SELECT 
    Priority as [CasePriority],
    COUNT(*) as [CaseCount],
    AVG(DATEDIFF(HOUR, CreatedAtUtc, GETUTCDATE())) as [AvgAgeHours]
FROM SupportCases
GROUP BY Priority
ORDER BY [CaseCount] DESC;
GO

-- T-DB-INT-012: Return Request Status Report
SELECT 
    Status as [ReturnStatus],
    COUNT(*) as [ReturnCount],
    SUM(ISNULL(RequestedAmount, 0)) as [TotalRequestedAmount],
    SUM(ISNULL(ApprovedAmount, 0)) as [TotalApprovedAmount]
FROM ReturnRequests
GROUP BY Status
ORDER BY [ReturnCount] DESC;
GO

-- T-DB-INT-013: User Activity Summary
SELECT 
    u.Id as [UserId],
    u.Email,
    u.FullName,
    (
        SELECT COUNT(*)
        FROM Orders o
        WHERE o.UserId = u.Id
    ) as [OrderCount],
    (
        SELECT COALESCE(SUM(ISNULL(o.Total, 0)), 0)
        FROM Orders o
        WHERE o.UserId = u.Id
    ) as [TotalSpent],
    (
        SELECT COUNT(*)
        FROM PaymentMethods pm
        WHERE pm.UserId = u.Id
    ) as [PaymentMethodCount],
    (
        SELECT COUNT(*)
        FROM SupportCases sc
        WHERE sc.UserId = u.Id
    ) as [SupportCaseCount],
    (
        SELECT COUNT(*)
        FROM CreditApplications cr
        WHERE cr.UserId = u.Id
    ) as [CreditApplicationCount]
FROM Users u
ORDER BY [TotalSpent] DESC;
GO

-- T-DB-INT-014: Verify Products reference valid Categories
SELECT
    p.Id as [ProductId],
    p.Title,
    p.Category,
    p.CategoryId,
    c.Name as [CategoryName]
FROM Products p
LEFT JOIN Categories c ON p.CategoryId = c.Id
WHERE p.CategoryId IS NULL OR c.Id IS NULL
ORDER BY p.Id;
GO

-- T-DB-INT-015: Verify Order Items reference valid Products and carry positive quantities
SELECT
    oi.Id as [OrderItemId],
    oi.OrderId,
    oi.ProductId,
    p.Title,
    oi.Quantity,
    oi.UnitPrice,
    oi.LineTotal
FROM OrderItems oi
LEFT JOIN Products p ON oi.ProductId = p.Id
WHERE oi.Quantity <= 0 OR oi.UnitPrice <= 0 OR oi.LineTotal <= 0 OR p.Id IS NULL
ORDER BY oi.Id;
GO

-- T-DB-INT-014: Credit Application Status Report
SELECT 
    Status as [ApplicationStatus],
    COUNT(*) as [ApplicationCount],
    AVG(ISNULL(MonthlyIncome, 0)) as [AvgMonthlyIncome],
    AVG(ISNULL(MonthlyExpenses, 0)) as [AvgMonthlyExpenses]
FROM CreditApplications
GROUP BY Status
ORDER BY [ApplicationCount] DESC;
GO

-- T-DB-INT-015: Audit Log Event Summary
SELECT 
    a.EventType as [AuditEventType],
    COUNT(*) as [EventCount],
    MIN(a.TimestampUtc) as [EarliestEvent],
    MAX(a.TimestampUtc) as [LatestEvent],
    (
        SELECT COUNT(*)
        FROM (
            SELECT DISTINCT a2.UserId
            FROM AuditLogs a2
            WHERE a2.EventType = a.EventType
                AND a2.UserId IS NOT NULL
        ) distinct_users
    ) as [UniqueUsers]
FROM AuditLogs a
GROUP BY a.EventType
ORDER BY [EventCount] DESC;
GO

-- ============================================================================
-- LAYER 5: CROSS-LAYER SYNCHRONIZATION VALIDATION
-- ============================================================================

-- T-DB-INT-016: Verify all Orders have valid Product references (if items tracked)
-- Show orders and counts of associated items and any missing product references
SELECT
    o.Id as [OrderId],
    COUNT(oi.Id) as [OrderItemCount],
    SUM(CASE WHEN p.Id IS NULL THEN 1 ELSE 0 END) as [MissingProductRefs],
    STRING_AGG(CONCAT(oi.ProductId, ' x', oi.Quantity), ', ') WITHIN GROUP (ORDER BY oi.Id) as [ItemsSummary]
FROM Orders o
LEFT JOIN OrderItems oi ON oi.OrderId = o.Id
LEFT JOIN Products p ON p.Id = oi.ProductId
GROUP BY o.Id
ORDER BY o.Id;
GO

-- T-DB-INT-017: Verify Feature Flags are properly configured
SELECT 
    [Key] as [FeatureFlagKey],
    [Description],
    [IsEnabled],
    [UpdatedAtUtc],
    DATEDIFF(HOUR, [UpdatedAtUtc], GETUTCDATE()) as [HoursSinceUpdate]
FROM QaFeatureFlags
ORDER BY [UpdatedAtUtc] DESC;
GO

-- T-DB-INT-018: Defect Report Quality Check
SELECT 
    MissionKey,
    Status as [ReportStatus],
    COUNT(*) as [ReportCount],
    AVG(CAST(ISNULL(Score, 0) AS FLOAT)) as [AvgScore],
    SUM(CASE WHEN InstructorFeedback IS NOT NULL THEN 1 ELSE 0 END) as [ReviewedCount]
FROM DefectReports
GROUP BY MissionKey, Status
ORDER BY MissionKey, Status;
GO

-- T-DB-INT-019: Mission Progress Summary
SELECT 
    MissionKey,
    PersonaKey,
    Status as [ProgressStatus],
    COUNT(*) as [StudentCount],
    AVG(CAST(ISNULL(Score, 0) AS FLOAT)) as [AvgScore],
    SUM(CASE WHEN CompletedAtUtc IS NOT NULL THEN 1 ELSE 0 END) as [CompletedCount]
FROM MissionProgresses
GROUP BY MissionKey, PersonaKey, Status
ORDER BY MissionKey, PersonaKey, Status;
GO

-- T-DB-INT-020: Data Freshness Check
SELECT 
    'Categories' as [TableName], CAST(NULL AS DATETIME2) as [LastUpdate]
FROM Categories
UNION ALL
SELECT 'Products', CAST(NULL AS DATETIME2)
FROM Products
UNION ALL
SELECT 'Orders', MAX(UpdatedAtUtc)
FROM Orders
UNION ALL
SELECT 'Users', CAST(NULL AS DATETIME2)
FROM Users
UNION ALL
SELECT 'AuditLogs', MAX(TimestampUtc)
FROM AuditLogs
ORDER BY [TableName];
GO

PRINT 'All validation queries ready for QE testing.';
GO
