-- Lewis Stores Test Data Seed Script
-- Populates the database with seed data for QE testing
-- Run this after schema creation

USE [LewisStoresDb];
GO

-- Clear existing data (maintain referential integrity order)
DELETE FROM [AuditLogs];
DELETE FROM [QaFeatureFlags];
DELETE FROM [MissionProgresses];
DELETE FROM [DefectReports];
DELETE FROM [SupportCases];
DELETE FROM [ReturnRequests];
DELETE FROM [CreditApplications];
DELETE FROM [PaymentMethods];
DELETE FROM [Deliveries];
DELETE FROM [OrderItems];
DELETE FROM [Orders];
DELETE FROM [CartItems];
DELETE FROM [Products];
DELETE FROM [Categories];
DELETE FROM [Users];
GO

-- Seed Categories
INSERT INTO [Categories] ([Id], [Name], [Description], [To], [Tone]) VALUES
(N'cat-1', N'Furniture', N'Architectural sofas, dining, and lounge essentials', N'/products', N'category-furniture'),
(N'cat-2', N'Appliances', N'Performance-first pieces for modern homes', N'/products', N'category-appliances'),
(N'cat-3', N'Electronics', N'Curated home tech and sound systems', N'/products', N'category-electronics'),
(N'cat-4', N'Decor', N'Lighting, art, and finishing details', N'/products', N'category-decor'),
(N'cat-5', N'Bedding', N'Mattresses, pillows, and linen essentials', N'/products', N'category-bedding'),
(N'cat-6', N'Office', N'Work-from-home desks, chairs, and accessories', N'/products', N'category-office');
GO

-- Seed Products
INSERT INTO [Products] ([Id], [Title], [Description], [Price], [OldPrice], [Tag], [Rating], [Category], [CategoryId], [Image], [Sku], [StockQuantity], [IsActive]) VALUES
-- Furniture Products
(N'luca-modular', N'Luca Modular Sofa', N'Textured ivory upholstery with brushed oak legs.', 24999.00, 27999.00, N'Limited Edition', 4.8, N'Furniture', N'cat-1', N'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&q=80&w=1200', N'LEW-FUR-0001', 12, 1),
(N'atlas-lounge', N'Atlas Lounge Chair', N'Low-profile silhouette with layered cushioning.', 10999.00, NULL, N'Best Seller', 4.6, N'Furniture', N'cat-1', N'https://images.unsplash.com/photo-1501045661006-fcebe0257c3f?auto=format&fit=crop&q=80&w=1200', N'LEW-FUR-0002', 9, 1),
(N'miren-table', N'Miren Coffee Table', N'Solid ash base and honed stone top.', 7699.00, NULL, NULL, 4.5, N'Furniture', N'cat-1', N'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&q=80&w=1200', N'LEW-FUR-0003', 15, 1),
-- Electronics Products
(N'aurora-speaker', N'Aurora Wireless Speaker', N'Premium sound system with adaptive bass.', 8999.00, 9999.00, N'Best Seller', 4.7, N'Electronics', N'cat-3', N'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&q=80&w=1200', N'LEW-ELE-0001', 20, 1),
(N'vertex-monitor', N'Vertex 4K Monitor', N'Ultra-wide curved 38-inch display.', 15999.00, 17999.00, N'New', 4.9, N'Electronics', N'cat-3', N'https://images.unsplash.com/photo-1527864550417-7fd231fc53f7?auto=format&fit=crop&q=80&w=1200', N'LEW-ELE-0002', 8, 1),
-- Bedding Products
(N'cloudrest-mattress', N'CloudRest Memory Foam Mattress', N'Orthopaedic support with cooling gel layer.', 22999.00, 25999.00, N'Best Seller', 4.8, N'Bedding', N'cat-5', N'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&q=80&w=1200', N'LEW-BED-0001', 6, 1),
(N'luxe-pillows', N'Luxe Down Pillows (Set of 2)', N'Premium Hungarian goose down.', 5999.00, NULL, NULL, 4.4, N'Bedding', N'cat-5', N'https://images.unsplash.com/photo-1584622181563-430f63602d4b?auto=format&fit=crop&q=80&w=1200', N'LEW-BED-0002', 25, 1),
-- Appliances
(N'espresso-machine', N'Professional Espresso Machine', N'Commercial-grade coffee maker.', 13999.00, 15999.00, N'New', 4.7, N'Appliances', N'cat-2', N'https://images.unsplash.com/photo-1559056199-641a0ac8b8d5?auto=format&fit=crop&q=80&w=1200', N'LEW-APP-0001', 5, 1),
(N'air-fryer', N'Smart Air Fryer Oven', N'IoT-enabled with app control.', 9999.00, 11999.00, N'Best Seller', 4.6, N'Appliances', N'cat-2', N'https://images.unsplash.com/photo-1584568694244-14fbbc2bd3a1?auto=format&fit=crop&q=80&w=1200', N'LEW-APP-0002', 14, 1),
-- Decor
(N'pendant-light', N'Scandinavian Pendant Light', N'Hand-blown glass with brass accents.', 3999.00, NULL, NULL, 4.5, N'Decor', N'cat-4', N'https://images.unsplash.com/photo-1523175335684-37898b6baf30?auto=format&fit=crop&q=80&w=1200', N'LEW-DEC-0001', 18, 1),
(N'mirror-wall', N'Large Wall Mirror with Frame', N'Gold-finished metal frame.', 5999.00, 6999.00, N'Limited Edition', 4.3, N'Decor', N'cat-4', N'https://images.unsplash.com/photo-1556740738-b6a63e27c4df?auto=format&fit=crop&q=80&w=1200', N'LEW-DEC-0002', 11, 1),
-- Office
(N'ergonomic-desk', N'Ergonomic Standing Desk', N'Motorized height adjustment.', 19999.00, 22999.00, N'Best Seller', 4.8, N'Office', N'cat-6', N'https://images.unsplash.com/photo-1593642532400-2682a8a60fc8?auto=format&fit=crop&q=80&w=1200', N'LEW-OFF-0001', 7, 1),
(N'office-chair', N'Executive Office Chair', N'Mesh back with lumbar support.', 12999.00, 14999.00, N'Best Seller', 4.7, N'Office', N'cat-6', N'https://images.unsplash.com/photo-1611269431281-ca522b8cb895?auto=format&fit=crop&q=80&w=1200', N'LEW-OFF-0002', 10, 1);
GO

-- Seed Users (Test Accounts for QE)
INSERT INTO [Users] ([Id], [Email], [Password], [Role], [FullName], [Phone], [Address]) VALUES
-- Standard Test Users
(N'user-001', N'test.customer@lewisstores.local', N'Password123!', N'Customer', N'Test Customer One', N'555-0001', N'123 Main St, City, State 12345'),
(N'user-002', N'sarah.johnson@lewisstores.local', N'Password123!', N'Customer', N'Sarah Johnson', N'555-0002', N'456 Oak Avenue, Town, State 54321'),
(N'user-003', N'michael.chen@lewisstores.local', N'Password123!', N'Customer', N'Michael Chen', N'555-0003', N'789 Pine Road, Village, State 99887'),
(N'user-004', N'emily.wilson@lewisstores.local', N'Password123!', N'Customer', N'Emily Wilson', N'555-0004', N'321 Elm Street, Borough, State 45678'),
(N'user-005', N'james.brown@lewisstores.local', N'Password123!', N'Customer', N'James Brown', N'555-0005', N'654 Maple Drive, Town, State 78901'),
-- Support Agent
(N'agent-support-001', N'support.agent@lewisstores.local', N'Password123!', N'SupportAgent', N'Support Agent Johnson', N'555-9001', N'100 Service Lane, HQ, State 00000'),
-- Admin
(N'admin-001', N'admin@lewisstores.local', N'Password123!', N'Admin', N'Admin User', N'555-9999', N'1 Admin Plaza, HQ, State 00000');
GO

-- Seed Payment Methods
INSERT INTO [PaymentMethods] ([UserId], [CardholderName], [Last4], [Brand], [Expiry], [IsDefault]) VALUES
(N'user-001', N'Test Customer One', N'1111', N'Visa', N'12/26', 1),
(N'user-002', N'Sarah Johnson', N'2222', N'Mastercard', N'08/27', 1),
(N'user-003', N'Michael Chen', N'3333', N'Amex', N'05/28', 1),
(N'user-004', N'Emily Wilson', N'4444', N'Visa', N'11/26', 1),
(N'user-005', N'James Brown', N'5555', N'Discover', N'03/27', 1);
GO

-- Seed Cart Items
INSERT INTO [CartItems] ([Id], [Title], [Variant], [Quantity], [Price]) VALUES
(N'luca-modular', N'Luca Modular Sofa', N'Pearl Cloud, Matte Black Legs', 1, 24999.00),
(N'miren-table', N'Miren Coffee Table', N'Ash + Stone', 1, 7699.00);
GO

-- Seed Orders
INSERT INTO [Orders] ([Id], [Date], [Status], [Total], [UserId], [Items], [CreatedAtUtc], [UpdatedAtUtc]) VALUES
(N'ORD-001-20260512', N'May 12, 2026', N'Confirmed', 32698.00, N'user-001', N'Luca Modular Sofa x1, Miren Coffee Table x1', GETUTCDATE(), GETUTCDATE()),
(N'ORD-002-20260511', N'May 11, 2026', N'Shipped', 8999.00, N'user-002', N'Aurora Wireless Speaker x1', DATEADD(DAY, -1, GETUTCDATE()), DATEADD(DAY, -1, GETUTCDATE())),
(N'ORD-003-20260510', N'May 10, 2026', N'Delivered', 22999.00, N'user-003', N'CloudRest Memory Foam Mattress x1', DATEADD(DAY, -2, GETUTCDATE()), DATEADD(DAY, -2, GETUTCDATE())),
(N'ORD-004-20260509', N'May 9, 2026', N'Pending', 19999.00, N'user-004', N'Ergonomic Standing Desk x1', DATEADD(DAY, -3, GETUTCDATE()), DATEADD(DAY, -3, GETUTCDATE())),
(N'ORD-005-20260508', N'May 8, 2026', N'Cancelled', 12999.00, N'user-005', N'Executive Office Chair x1', DATEADD(DAY, -4, GETUTCDATE()), DATEADD(DAY, -4, GETUTCDATE()));
GO

-- Seed Order Items
INSERT INTO [OrderItems] ([OrderId], [ProductId], [Quantity], [UnitPrice], [LineTotal]) VALUES
(N'ORD-001-20260512', N'luca-modular', 1, 24999.00, 24999.00),
(N'ORD-001-20260512', N'miren-table', 1, 7699.00, 7699.00),
(N'ORD-002-20260511', N'aurora-speaker', 1, 8999.00, 8999.00),
(N'ORD-003-20260510', N'cloudrest-mattress', 1, 22999.00, 22999.00),
(N'ORD-004-20260509', N'ergonomic-desk', 1, 19999.00, 19999.00),
(N'ORD-005-20260508', N'office-chair', 1, 12999.00, 12999.00);
GO

-- Seed Deliveries
INSERT INTO [Deliveries] ([OrderId], [UserId], [Status], [Carrier], [TrackingNumber], [Origin], [Destination], [CurrentLocation], [ShippedAtUtc], [EstimatedDeliveryAtUtc], [DeliveredAtUtc], [UpdatedAtUtc]) VALUES
(N'ORD-001-20260512', N'user-001', N'Processing', N'Lewis Logistics', N'LL-ORD-001-20260512', N'Johannesburg Distribution Centre', N'123 Main St, City, State 12345', N'Queued for packing', NULL, DATEADD(DAY, 4, GETUTCDATE()), NULL, GETUTCDATE()),
(N'ORD-002-20260511', N'user-002', N'Shipped', N'Lewis Logistics', N'LL-ORD-002-20260511', N'Johannesburg Distribution Centre', N'456 Oak Avenue, Town, State 54321', N'In transit between regional hubs', DATEADD(DAY, -1, GETUTCDATE()), DATEADD(DAY, 2, GETUTCDATE()), NULL, DATEADD(HOUR, -6, GETUTCDATE())),
(N'ORD-003-20260510', N'user-003', N'Delivered', N'Lewis Logistics', N'LL-ORD-003-20260510', N'Johannesburg Distribution Centre', N'789 Pine Road, Village, State 99887', N'Delivered to recipient', DATEADD(DAY, -2, GETUTCDATE()), DATEADD(DAY, -1, GETUTCDATE()), DATEADD(HOUR, -20, GETUTCDATE()), DATEADD(HOUR, -20, GETUTCDATE())),
(N'ORD-004-20260509', N'user-004', N'Processing', N'Lewis Logistics', N'LL-ORD-004-20260509', N'Johannesburg Distribution Centre', N'321 Elm Street, Borough, State 45678', N'Order received at dispatch hub', NULL, DATEADD(DAY, 3, GETUTCDATE()), NULL, DATEADD(HOUR, -2, GETUTCDATE())),
(N'ORD-005-20260508', N'user-005', N'Cancelled', N'Lewis Logistics', N'LL-ORD-005-20260508', N'Johannesburg Distribution Centre', N'654 Maple Drive, Town, State 78901', N'Shipment cancelled', NULL, DATEADD(DAY, 1, GETUTCDATE()), NULL, DATEADD(DAY, -3, GETUTCDATE()));
GO

-- Seed Credit Applications
INSERT INTO [CreditApplications] ([UserId], [Status], [ApplicationDate], [IdNumber], [EmploymentStatus], [MonthlyIncome], [MonthlyExpenses]) VALUES
(N'user-001', N'Approved', GETUTCDATE(), N'ID-001-12345', N'Employed', 5000.00, 2000.00),
(N'user-002', N'Pending', DATEADD(DAY, -1, GETUTCDATE()), N'ID-002-67890', N'Self-Employed', 6500.00, 2500.00),
(N'user-003', N'Rejected', DATEADD(DAY, -5, GETUTCDATE()), N'ID-003-11111', N'Unemployed', 0.00, 1500.00),
(N'user-004', N'Under Review', DATEADD(DAY, -2, GETUTCDATE()), N'ID-004-22222', N'Employed', 7000.00, 3000.00);
GO

-- Seed Return Requests
INSERT INTO [ReturnRequests] ([OrderId], [UserId], [Reason], [Status], [RequestedAmount], [ApprovedAmount], [ResolutionNotes], [RequestedAtUtc], [UpdatedAtUtc]) VALUES
(N'ORD-003-20260510', N'user-003', N'Item defective', N'Approved', 22999.00, 22999.00, N'Full refund issued to original payment method', DATEADD(DAY, -1, GETUTCDATE()), GETUTCDATE()),
(N'ORD-004-20260509', N'user-004', N'Changed mind', N'PendingReview', 19999.00, NULL, N'Awaiting customer response', DATEADD(HOUR, -12, GETUTCDATE()), DATEADD(HOUR, -12, GETUTCDATE()));
GO

-- Seed Support Cases
INSERT INTO [SupportCases] ([OrderId], [UserId], [Subject], [Description], [Status], [Priority], [AssignedToUserId], [CreatedAtUtc], [UpdatedAtUtc]) VALUES
(N'ORD-001-20260512', N'user-001', N'Delivery inquiry', N'When will my order be delivered?', N'Open', N'High', N'agent-support-001', DATEADD(HOUR, -2, GETUTCDATE()), DATEADD(HOUR, -2, GETUTCDATE())),
(N'ORD-002-20260511', N'user-002', N'Product quality concern', N'Speaker has poor sound quality', N'Assigned', N'Medium', N'agent-support-001', DATEADD(DAY, -1, GETUTCDATE()), GETUTCDATE()),
(NULL, N'user-005', N'Account issue', N'Unable to reset password', N'Open', N'High', NULL, DATEADD(HOUR, -4, GETUTCDATE()), DATEADD(HOUR, -4, GETUTCDATE()));
GO

-- Seed Defect Reports
INSERT INTO [DefectReports] ([MissionKey], [Title], [Severity], [StepsToReproduce], [ExpectedResult], [ActualResult], [EnvironmentNotes], [Status], [SubmittedByUserId], [SubmittedAtUtc], [InstructorFeedback], [Score]) VALUES
(N'M-AUTH-001', N'Login fails with special characters in password', N'High', N'1. Navigate to login page 2. Enter email: test@test.com 3. Enter password with special chars: P@ssw0rd! 4. Click Login', N'User logs in successfully', N'Form validation error displayed', N'Chrome 125 on Windows 11', N'Submitted', N'user-001', DATEADD(DAY, -1, GETUTCDATE()), N'Good catch! This is a known issue in the auth service.', 85),
(N'M-ORDER-001', N'Order total calculation incorrect', N'Critical', N'1. Add 2x Luca Modular @ $24,999 2. Add 1x Miren Table @ $7,699 3. Verify total equals $57,697', N'Total should be $57,697', N'Total displays $57,697 but order confirmation shows $60,000', N'Safari on MacOS', N'Under Review', N'user-002', DATEADD(DAY, -2, GETUTCDATE()), NULL, NULL);
GO

-- Seed QA Feature Flags
INSERT INTO [QaFeatureFlags] ([Key], [Description], [IsEnabled], [UpdatedAtUtc]) VALUES
(N'product_duplicate_in_list', N'Intentional defect: duplicate one product on catalog list responses.', 1, GETUTCDATE()),
(N'order_total_mismatch', N'Intentional defect: one order total may be inconsistent with expected line-item sum.', 1, GETUTCDATE()),
(N'auth_email_case_sensitive', N'Intentional defect: registration duplicate check can be case-sensitive.', 1, GETUTCDATE()),
(N'audit_verbose_events', N'Enable detailed auth and order lifecycle events in audit logs.', 1, GETUTCDATE()),
(N'returns_refund_delay', N'Intentional defect: approved refunds remain in pending payout state longer than expected.', 1, GETUTCDATE()),
(N'support_assignment_conflict', N'Intentional defect: assignment updates may overwrite existing assignee in high-concurrency simulation.', 1, GETUTCDATE());
GO

-- Seed Audit Logs
INSERT INTO [AuditLogs] ([TimestampUtc], [EventType], [UserId], [Severity], [Details]) VALUES
(GETUTCDATE(), N'auth.login.success', N'user-001', N'Info', N'{\"source\":\"api\",\"ip\":\"127.0.0.1\"}'),
(DATEADD(MINUTE, -5, GETUTCDATE()), N'auth.register.success', N'user-002', N'Info', N'{\"source\":\"api\"}'),
(DATEADD(MINUTE, -10, GETUTCDATE()), N'order.created', N'user-003', N'Info', N'{\"orderId\":\"ORD-003-20260510\",\"total\":22999}'),
(DATEADD(MINUTE, -15, GETUTCDATE()), N'order.cancelled', N'user-005', N'Warning', N'{\"orderId\":\"ORD-005-20260508\",\"reason\":\"user_requested\"}');
GO

-- Mission Progresses
INSERT INTO [MissionProgresses] ([MissionKey], [UserId], [PersonaKey], [Status], [Score], [Badge], [StartedAtUtc], [CompletedAtUtc]) VALUES
(N'M-AUTH-001', N'user-001', N'customer', N'Completed', 92, N'Certified', DATEADD(DAY, -5, GETUTCDATE()), DATEADD(DAY, -3, GETUTCDATE())),
(N'M-ORDER-001', N'user-002', N'customer', N'Completed', 88, N'Certified', DATEADD(DAY, -4, GETUTCDATE()), DATEADD(DAY, -2, GETUTCDATE())),
(N'M-PAYMENT-001', N'user-003', N'customer', N'InProgress', 0, N'None', DATEADD(DAY, -1, GETUTCDATE()), NULL),
(N'M-RETURN-001', N'user-004', N'customer', N'NotStarted', 0, N'None', GETUTCDATE(), NULL);
GO

PRINT 'Seed data inserted successfully!';
PRINT 'Users created: 7 (5 customers, 1 support agent, 1 admin)';
PRINT 'Products created: 12';
PRINT 'Orders created: 5';
PRINT 'Deliveries created: 5';
PRINT 'Payment methods: 5';
PRINT 'Support cases: 3';
PRINT 'Defect reports: 2';
GO
