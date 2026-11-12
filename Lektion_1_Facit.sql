/*******************************************************************************
               FAILSAFE IT - ENBART FACIT & REFERENSKOD (LEKTION 1)
  Målgrupp: DevSecOps | Kurs: Databaser och SQL (4 veckor, 20 poäng)
  Beskrivning: Detta skript återställer miljön, skapar tabellstrukturen för
               FailSafe IT samt lägger till den initiala testdatan.
*******************************************************************************/

-- Vi ser till att börja på ett blankt blad i FailSafeIT_Local så att skriptet är 100% omkörbart
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'FailSafeIT')
BEGIN
    ALTER DATABASE FailSafeIT SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FailSafeIT;
END
GO

CREATE DATABASE FailSafeIT;
GO

USE FailSafeIT;
GO

-- Rensa gamla tabeller om de existerar från tidigare körningar
IF OBJECT_ID('dbo.Servers', 'U') IS NOT NULL DROP TABLE dbo.Servers;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

-- =============================================================================
-- SKAPA TABELLSTRUKTUR (DDL)
-- =============================================================================

-- 1. Skapa tabellen Users (Användarregister)
CREATE TABLE dbo.Users (
    Id INT IDENTITY(1,1) NOT NULL,
    Username NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    Role NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT UQ_Users_Username UNIQUE (Username)
);

-- 2. Skapa tabellen Servers (Infrastrukturregister med Foreign Key)
CREATE TABLE dbo.Servers (
    Id INT IDENTITY(1,1) NOT NULL,
    ServerName NVARCHAR(100) NOT NULL,
    IpAddress VARCHAR(15) NULL,
    Environment NVARCHAR(50) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Servers_IsActive DEFAULT 1,
    ManagedByUserId INT NULL,
    CONSTRAINT PK_Servers PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT FK_Servers_Users FOREIGN KEY (ManagedByUserId) REFERENCES dbo.Users (Id)
);
GO

-- =============================================================================
-- POPULERA TESTDATA (DML)
-- =============================================================================

INSERT INTO dbo.Users (Username, Email, Role) VALUES 
('alice_ops', 'alice@failsafe.it', 'DevSecOps Engineer'),
('bob_sec', 'bob@failsafe.it', 'Security Analyst'),
('charlie_dev', 'charlie@failsafe.it', 'Developer'),
('ghost_user', 'ghost@failsafe.it', 'Ex-Employee'); -- Tekniker utan tilldelad server

INSERT INTO dbo.Servers (ServerName, IpAddress, Environment, IsActive, ManagedByUserId) VALUES 
('Prod-Web-01', '10.0.0.15', 'Production', 1, 1), -- Tillhör Alice
('Prod-DB-01', '10.0.0.16', 'Production', 1, 1),  -- Tillhör Alice
('Staging-App-01', '10.0.0.25', 'Staging', 1, 2), -- Tillhör Bob
('Dev-Sandbox', '192.168.1.50', 'Development', 1, NULL), -- Herrelös server
('Legacy-Mainframe', '10.1.1.99', 'Production', 0, NULL); -- Herrelös och inaktiv
GO

PRINT 'FailSafe IT: Tabeller och testdata för Lektion 1 har skapats felfritt!';
