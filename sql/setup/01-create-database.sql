-- Lewis Stores Database - Initial Setup Script
-- This script creates the LewisStoresDb database for offline QE testing
-- Run as SQL Server administrator or sa account

USE [master];
GO

-- Drop database if exists (for clean slate during development)
IF DB_ID('LewisStoresDb') IS NOT NULL
BEGIN
    ALTER DATABASE [LewisStoresDb] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [LewisStoresDb];
END
GO

-- Create database
CREATE DATABASE [LewisStoresDb];
GO

USE [LewisStoresDb];
GO

-- Verify database creation
PRINT 'Database LewisStoresDb created successfully.';
GO
