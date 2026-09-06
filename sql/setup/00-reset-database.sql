-- Lewis Stores Database Reset Script
-- Use this script to reset the database to a clean state with fresh seed data
-- This is useful for running a fresh set of tests

USE [master];
GO

-- Check if database exists
IF DB_ID('LewisStoresDb') IS NOT NULL
BEGIN
    -- Drop the database to clean slate
    ALTER DATABASE [LewisStoresDb] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [LewisStoresDb];
    PRINT 'Existing database dropped.';
END
GO

-- Re-create the database
CREATE DATABASE [LewisStoresDb];
GO

PRINT 'Database LewisStoresDb recreated.';
GO

-- Now run the schema creation and seed data scripts
-- Execute: SQLCMD -S .\SQLEXPRESS -i "02-create-schema.sql"
-- Execute: SQLCMD -S .\SQLEXPRESS -i "03-seed-test-data.sql"

PRINT 'Database reset complete. Run 02-create-schema.sql and 03-seed-test-data.sql to initialize.';
GO
