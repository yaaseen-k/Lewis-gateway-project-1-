-- Lewis Stores Database Schema
-- Entity Framework Core will create tables automatically, but this script
-- provides documentation of the database structure

USE [LewisStoresDb];
GO

-- Create tables for core entities
-- Note: EF Core will handle the actual creation via migrations or EnsureCreated()

-- Categories Table
CREATE TABLE [Categories] (
    [Id] NVARCHAR(450) NOT NULL,
    [Name] NVARCHAR(255) NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    [To] NVARCHAR(255) NULL,
    [Tone] NVARCHAR(255) NULL,
    CONSTRAINT [PK_Categories] PRIMARY KEY ([Id])
);
GO

-- Products Table
CREATE TABLE [Products] (
    [Id] NVARCHAR(450) NOT NULL,
    [Title] NVARCHAR(255) NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    [Price] DECIMAL(18,2) NOT NULL,
    [OldPrice] DECIMAL(18,2) NULL,
    [Tag] NVARCHAR(100) NULL,
    [Rating] FLOAT NOT NULL DEFAULT 0.0,
    [Category] NVARCHAR(255) NOT NULL,
    [CategoryId] NVARCHAR(450) NOT NULL,
    [Image] NVARCHAR(MAX) NULL,
    [Sku] NVARCHAR(100) NOT NULL UNIQUE,
    [StockQuantity] INT NOT NULL DEFAULT 0,
    [IsActive] BIT NOT NULL DEFAULT 1,
    CONSTRAINT [PK_Products] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Products_Categories] FOREIGN KEY ([CategoryId]) REFERENCES [Categories]([Id]),
    INDEX [IX_Products_Category] ([Category]),
    INDEX [IX_Products_CategoryId] ([CategoryId]),
    INDEX [IX_Products_Sku] ([Sku])
);
GO

-- Users Table
CREATE TABLE [Users] (
    [Id] NVARCHAR(450) NOT NULL,
    [Email] NVARCHAR(255) NOT NULL UNIQUE,
    [Password] NVARCHAR(255) NOT NULL,
    [Role] NVARCHAR(50) NOT NULL DEFAULT 'Customer',
    [FullName] NVARCHAR(255) NOT NULL,
    [Phone] NVARCHAR(20) NULL,
    [Address] NVARCHAR(MAX) NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY ([Id]),
    INDEX [IX_Users_Email] ([Email])
);
GO

-- Orders Table
CREATE TABLE [Orders] (
    [Id] NVARCHAR(450) NOT NULL,
    [Date] NVARCHAR(100) NOT NULL,
    [Status] NVARCHAR(50) NOT NULL DEFAULT 'Pending',
    [Total] DECIMAL(18,2) NOT NULL,
    [UserId] NVARCHAR(450) NULL,
    [Items] NVARCHAR(MAX) NOT NULL,
    [CreatedAtUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAtUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_Orders] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Orders_Users] FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]),
    INDEX [IX_Orders_UserId] ([UserId]),
    INDEX [IX_Orders_Status] ([Status])
);
GO

-- OrderItems Table
CREATE TABLE [OrderItems] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [OrderId] NVARCHAR(450) NOT NULL,
    [ProductId] NVARCHAR(450) NOT NULL,
    [Quantity] INT NOT NULL DEFAULT 1,
    [UnitPrice] DECIMAL(18,2) NOT NULL,
    [LineTotal] DECIMAL(18,2) NOT NULL,
    CONSTRAINT [PK_OrderItems] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_OrderItems_Orders] FOREIGN KEY ([OrderId]) REFERENCES [Orders]([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_OrderItems_Products] FOREIGN KEY ([ProductId]) REFERENCES [Products]([Id]),
    INDEX [IX_OrderItems_OrderId] ([OrderId]),
    INDEX [IX_OrderItems_ProductId] ([ProductId])
);
GO

-- Deliveries Table
CREATE TABLE [Deliveries] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [OrderId] NVARCHAR(450) NOT NULL,
    [UserId] NVARCHAR(450) NOT NULL,
    [Status] NVARCHAR(50) NOT NULL DEFAULT 'Processing',
    [Carrier] NVARCHAR(100) NOT NULL,
    [TrackingNumber] NVARCHAR(100) NOT NULL,
    [Origin] NVARCHAR(255) NOT NULL,
    [Destination] NVARCHAR(255) NOT NULL,
    [CurrentLocation] NVARCHAR(255) NOT NULL,
    [ShippedAtUtc] DATETIME2 NULL,
    [EstimatedDeliveryAtUtc] DATETIME2 NOT NULL,
    [DeliveredAtUtc] DATETIME2 NULL,
    [UpdatedAtUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_Deliveries] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Deliveries_Orders] FOREIGN KEY ([OrderId]) REFERENCES [Orders]([Id]),
    CONSTRAINT [FK_Deliveries_Users] FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]),
    INDEX [IX_Deliveries_OrderId] ([OrderId]),
    INDEX [IX_Deliveries_UserId] ([UserId]),
    INDEX [IX_Deliveries_Status] ([Status]),
    INDEX [IX_Deliveries_UpdatedAtUtc] ([UpdatedAtUtc])
);
GO

-- CartItems Table
CREATE TABLE [CartItems] (
    [InternalId] INT IDENTITY(1,1) NOT NULL,
    [Id] NVARCHAR(450) NOT NULL,
    [Title] NVARCHAR(255) NOT NULL,
    [Variant] NVARCHAR(255) NULL,
    [Quantity] INT NOT NULL DEFAULT 1,
    [Price] DECIMAL(18,2) NOT NULL,
    CONSTRAINT [PK_CartItems] PRIMARY KEY ([InternalId]),
    CONSTRAINT [FK_CartItems_Products] FOREIGN KEY ([Id]) REFERENCES [Products]([Id])
);
GO

-- PaymentMethods Table
CREATE TABLE [PaymentMethods] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserId] NVARCHAR(450) NOT NULL,
    [CardholderName] NVARCHAR(255) NOT NULL,
    [Last4] NVARCHAR(4) NOT NULL,
    [Brand] NVARCHAR(50) NOT NULL DEFAULT 'Card',
    [Expiry] NVARCHAR(10) NOT NULL,
    [IsDefault] BIT NOT NULL DEFAULT 0,
    CONSTRAINT [PK_PaymentMethods] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_PaymentMethods_Users] FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]),
    INDEX [IX_PaymentMethods_UserId] ([UserId])
);
GO

-- CreditApplications Table
CREATE TABLE [CreditApplications] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserId] NVARCHAR(450) NOT NULL,
    [Status] NVARCHAR(50) NOT NULL DEFAULT 'Pending',
    [ApplicationDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [IdNumber] NVARCHAR(50) NOT NULL,
    [EmploymentStatus] NVARCHAR(100) NOT NULL,
    [MonthlyIncome] DECIMAL(18,2) NOT NULL,
    [MonthlyExpenses] DECIMAL(18,2) NOT NULL,
    CONSTRAINT [PK_CreditApplications] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CreditApplications_Users] FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]),
    INDEX [IX_CreditApplications_UserId] ([UserId]),
    INDEX [IX_CreditApplications_Status] ([Status])
);
GO

-- ReturnRequests Table
CREATE TABLE [ReturnRequests] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [OrderId] NVARCHAR(450) NOT NULL,
    [UserId] NVARCHAR(450) NOT NULL,
    [Reason] NVARCHAR(255) NOT NULL,
    [Status] NVARCHAR(50) NOT NULL DEFAULT 'PendingReview',
    [RequestedAmount] DECIMAL(18,2) NOT NULL,
    [ApprovedAmount] DECIMAL(18,2) NULL,
    [ResolutionNotes] NVARCHAR(MAX) NULL,
    [RequestedAtUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAtUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_ReturnRequests] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_ReturnRequests_Orders] FOREIGN KEY ([OrderId]) REFERENCES [Orders]([Id]),
    CONSTRAINT [FK_ReturnRequests_Users] FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]),
    INDEX [IX_ReturnRequests_OrderId] ([OrderId]),
    INDEX [IX_ReturnRequests_UserId] ([UserId]),
    INDEX [IX_ReturnRequests_Status] ([Status])
);
GO

-- SupportCases Table
CREATE TABLE [SupportCases] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [OrderId] NVARCHAR(450) NULL,
    [UserId] NVARCHAR(450) NOT NULL,
    [Subject] NVARCHAR(255) NOT NULL,
    [Description] NVARCHAR(MAX) NOT NULL,
    [Status] NVARCHAR(50) NOT NULL DEFAULT 'Open',
    [Priority] NVARCHAR(50) NOT NULL DEFAULT 'Normal',
    [AssignedToUserId] NVARCHAR(450) NULL,
    [CreatedAtUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAtUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_SupportCases] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_SupportCases_Orders] FOREIGN KEY ([OrderId]) REFERENCES [Orders]([Id]),
    CONSTRAINT [FK_SupportCases_Users] FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]),
    CONSTRAINT [FK_SupportCases_AssignedUsers] FOREIGN KEY ([AssignedToUserId]) REFERENCES [Users]([Id]),
    INDEX [IX_SupportCases_UserId] ([UserId]),
    INDEX [IX_SupportCases_Status] ([Status]),
    INDEX [IX_SupportCases_Priority] ([Priority])
);
GO

-- DefectReports Table
CREATE TABLE [DefectReports] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [MissionKey] NVARCHAR(100) NOT NULL,
    [Title] NVARCHAR(255) NOT NULL,
    [Severity] NVARCHAR(50) NOT NULL DEFAULT 'Medium',
    [StepsToReproduce] NVARCHAR(MAX) NOT NULL,
    [ExpectedResult] NVARCHAR(MAX) NOT NULL,
    [ActualResult] NVARCHAR(MAX) NOT NULL,
    [EnvironmentNotes] NVARCHAR(MAX) NULL,
    [Status] NVARCHAR(50) NOT NULL DEFAULT 'Submitted',
    [SubmittedByUserId] NVARCHAR(450) NOT NULL,
    [SubmittedAtUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [InstructorFeedback] NVARCHAR(MAX) NULL,
    [Score] INT NULL,
    CONSTRAINT [PK_DefectReports] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_DefectReports_Users] FOREIGN KEY ([SubmittedByUserId]) REFERENCES [Users]([Id]),
    INDEX [IX_DefectReports_MissionKey] ([MissionKey]),
    INDEX [IX_DefectReports_Status] ([Status]),
    INDEX [IX_DefectReports_Severity] ([Severity])
);
GO

-- MissionProgresses Table
CREATE TABLE [MissionProgresses] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [MissionKey] NVARCHAR(100) NOT NULL,
    [UserId] NVARCHAR(450) NOT NULL,
    [PersonaKey] NVARCHAR(100) NOT NULL DEFAULT 'customer',
    [Status] NVARCHAR(50) NOT NULL DEFAULT 'NotStarted',
    [Score] INT NOT NULL DEFAULT 0,
    [Badge] NVARCHAR(100) NOT NULL DEFAULT 'None',
    [StartedAtUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [CompletedAtUtc] DATETIME2 NULL,
    CONSTRAINT [PK_MissionProgresses] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_MissionProgresses_Users] FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]),
    INDEX [IX_MissionProgresses_UserId] ([UserId]),
    INDEX [IX_MissionProgresses_MissionKey] ([MissionKey]),
    INDEX [IX_MissionProgresses_Status] ([Status])
);
GO

-- QaFeatureFlags Table
CREATE TABLE [QaFeatureFlags] (
    [Key] NVARCHAR(255) NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    [IsEnabled] BIT NOT NULL DEFAULT 0,
    [UpdatedAtUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_QaFeatureFlags] PRIMARY KEY ([Key])
);
GO

-- AuditLogs Table
CREATE TABLE [AuditLogs] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [TimestampUtc] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [EventType] NVARCHAR(100) NOT NULL,
    [UserId] NVARCHAR(450) NULL,
    [Severity] NVARCHAR(50) NOT NULL DEFAULT 'Info',
    [Details] NVARCHAR(MAX) NULL,
    CONSTRAINT [PK_AuditLogs] PRIMARY KEY ([Id]),
    INDEX [IX_AuditLogs_TimestampUtc] ([TimestampUtc]),
    INDEX [IX_AuditLogs_EventType] ([EventType]),
    INDEX [IX_AuditLogs_UserId] ([UserId]),
    INDEX [IX_AuditLogs_Severity] ([Severity])
);
GO

PRINT 'Schema created successfully.';
GO
