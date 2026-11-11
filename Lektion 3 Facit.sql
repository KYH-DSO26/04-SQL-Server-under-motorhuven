-- =========================================================================
-- FAILSAFE IT - FACIT-SKRIPT: LEKTION 3
-- Innehåller: Block 1 (Steg-för-steg Legacy-städning med Severity) & Block 2-4 (Greenfield M:M)
-- Namnstandard: PK heter alltid Id. FK heter <Tabellnamn>Id.
-- Central databas: Bygger vidare direkt inuti FailSafeIT
-- =========================================================================

USE FailSafeIT;
GO

-- =========================================================================
-- BLOCK 1: CASE A - STEG-FÖR-STEG NORMALISERING AV LEGACY KAOS-DATA
-- =========================================================================

-- --- STEG 0: DET O-NORMALISERADE TILLSTÅNDET (UNF) ---
IF OBJECT_ID('dbo.Legacy_Incident_Chaos', 'U') IS NOT NULL DROP TABLE dbo.Legacy_Incident_Chaos;
GO

CREATE TABLE dbo.Legacy_Incident_Chaos (
    ServerName NVARCHAR(100),
    Incident_Date_And_Severity NVARCHAR(250), -- Innehåller nu t.ex. "DDoS:2026-11-05:HIGH"
    InvestigatedByTechs NVARCHAR(MAX) 
);

INSERT INTO Legacy_Incident_Chaos VALUES 
('Prod-Web-01', 'DDoS:2026-11-05:HIGH', 'Erik Nilsson, Lina Berg'),
('Prod-Web-01', 'SQLi-Attempt:2026-11-06:CRITICAL', 'Lina Berg'),
('Dev-Db-01', 'UnauthorizedAccess:2026-11-07:MEDIUM', 'Erik Nilsson, Anna Stark'),
('Test-App-04', 'None:2026-11-08:LOW', 'Kalle Blomqvist');
GO


-- --- STEG 1: FÖRSTA NORMALFORMEN (1NF) ---
IF OBJECT_ID('dbo.Incident_1NF', 'U') IS NOT NULL DROP TABLE dbo.Incident_1NF;
GO

CREATE TABLE dbo.Incident_1NF (
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    ServerName NVARCHAR(100),
    IncidentType NVARCHAR(100),
    IncidentDate DATE,
    Severity NVARCHAR(50), -- Inkluderad i 1NF
    TechName NVARCHAR(150)
);

INSERT INTO dbo.Incident_1NF (ServerName, IncidentType, IncidentDate, Severity, TechName) VALUES 
('Prod-Web-01', 'DDoS', '2026-11-05', 'HIGH', 'Erik Nilsson'),
('Prod-Web-01', 'DDoS', '2026-11-05', 'HIGH', 'Lina Berg'),
('Prod-Web-01', 'SQLi-Attempt', '2026-11-06', 'CRITICAL', 'Lina Berg'),
('Dev-Db-01', 'UnauthorizedAccess', '2026-11-07', 'MEDIUM', 'Erik Nilsson'),
('Dev-Db-01', 'UnauthorizedAccess', '2026-11-07', 'MEDIUM', 'Anna Stark'),
('Test-App-04', 'None', '2026-11-08', 'LOW', 'Kalle Blomqvist');
GO


-- --- STEG 2: ANDRA NORMALFORMEN (2NF) ---
IF OBJECT_ID('dbo.Incidents_And_Techs_2NF', 'U') IS NOT NULL DROP TABLE dbo.Incidents_And_Techs_2NF;
IF OBJECT_ID('dbo.IncidentServers_2NF', 'U') IS NOT NULL DROP TABLE dbo.IncidentServers_2NF;
GO

CREATE TABLE dbo.IncidentServers_2NF (
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    ServerName NVARCHAR(100)
);

CREATE TABLE dbo.Incidents_And_Techs_2NF (
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    IncidentServers_2NFId INT, 
    IncidentType NVARCHAR(100),
    IncidentDate DATE,
    Severity NVARCHAR(50), -- Inkluderad i 2NF
    TechName NVARCHAR(150)
);

INSERT INTO dbo.IncidentServers_2NF (ServerName)
SELECT DISTINCT ServerName FROM dbo.Incident_1NF;

INSERT INTO dbo.Incidents_And_Techs_2NF (IncidentServers_2NFId, IncidentType, IncidentDate, Severity, TechName) VALUES 
(1, 'DDoS', '2026-11-05', 'HIGH', 'Erik Nilsson'),
(1, 'DDoS', '2026-11-05', 'HIGH', 'Lina Berg'),
(1, 'SQLi-Attempt', '2026-11-06', 'CRITICAL', 'Lina Berg'),
(2, 'UnauthorizedAccess', '2026-11-07', 'MEDIUM', 'Erik Nilsson'),
(2, 'UnauthorizedAccess', '2026-11-07', 'MEDIUM', 'Anna Stark'),
(3, 'None', '2026-11-08', 'LOW', 'Kalle Blomqvist');
GO


-- --- STEG 3: TREDJE NORMALFORMEN (3NF & UPPLÖST M:M) ---
IF OBJECT_ID('dbo.IncidentAssignments', 'U') IS NOT NULL DROP TABLE dbo.IncidentAssignments;
IF OBJECT_ID('dbo.Incidents', 'U') IS NOT NULL DROP TABLE dbo.Incidents;
IF OBJECT_ID('dbo.SecurityTechs', 'U') IS NOT NULL DROP TABLE dbo.SecurityTechs;
GO

CREATE TABLE dbo.SecurityTechs (
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    TechName NVARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE dbo.Incidents (
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    ServersId INT FOREIGN KEY REFERENCES dbo.Servers(Id), -- Länkad till Lektion 1 centrala tabell
    IncidentType NVARCHAR(100) NOT NULL,
    IncidentDate DATE NOT NULL,
    Severity NVARCHAR(50) NOT NULL -- Nu säkrad i skarp 3NF inför Lektion 4!
);

CREATE TABLE dbo.IncidentAssignments (
    IncidentsId INT NOT NULL,
    SecurityTechsId INT NOT NULL,
    CONSTRAINT PK_IncidentAssignments PRIMARY KEY (IncidentsId, SecurityTechsId),
    CONSTRAINT FK_Assignment_Incidents FOREIGN KEY (IncidentsId) REFERENCES dbo.Incidents(Id),
    CONSTRAINT FK_Assignment_SecurityTechs FOREIGN KEY (SecurityTechsId) REFERENCES dbo.SecurityTechs(Id)
);
GO

-- Slutgiltig migrering
INSERT INTO dbo.SecurityTechs (TechName) VALUES 
('Erik Nilsson'), ('Lina Berg'), ('Anna Stark'), ('Kalle Blomqvist');

DECLARE @BaseServerId INT;
SELECT TOP 1 @BaseServerId = Id FROM dbo.Servers ORDER BY Id ASC;
IF @BaseServerId IS NULL SET @BaseServerId = 1;

INSERT INTO dbo.Incidents (ServersId, IncidentType, IncidentDate, Severity) VALUES 
(@BaseServerId, 'DDoS', '2026-11-05', 'HIGH'),
(@BaseServerId, 'SQLi-Attempt', '2026-11-06', 'CRITICAL'),
(@BaseServerId, 'UnauthorizedAccess', '2026-11-07', 'MEDIUM'),
(@BaseServerId, 'None', '2026-11-08', 'LOW');

INSERT INTO dbo.IncidentAssignments (IncidentsId, SecurityTechsId) VALUES 
(1, 1), (1, 2), (2, 2), (3, 1), (3, 3), (4, 4);
GO

-- --- VERIFIERING VIA JOINS ---
SELECT 
    s.ServerName,
    i.IncidentType + ':' + CONVERT(VARCHAR, i.IncidentDate, 23) AS Incident_And_Date,
    i.Severity,
    t.TechName AS InvestigatedByTech
FROM dbo.Incidents i
INNER JOIN dbo.Servers s ON i.ServersId = s.Id
INNER JOIN dbo.IncidentAssignments a ON i.Id = a.IncidentsId
INNER JOIN dbo.SecurityTechs t ON a.SecurityTechsId = t.Id;
GO


-- =========================================================================
-- BLOCK 2: CASE B - HÄRDAD GREENFIELD M:M DDL (Från User Stories)
-- =========================================================================
IF OBJECT_ID('dbo.BackupAuditTrail', 'U') IS NOT NULL DROP TABLE dbo.BackupAuditTrail;
IF OBJECT_ID('dbo.ServerPolicyMaps', 'U') IS NOT NULL DROP TABLE dbo.ServerPolicyMaps;
IF OBJECT_ID('dbo.BackupPolicies', 'U') IS NOT NULL DROP TABLE dbo.BackupPolicies;
IF OBJECT_ID('dbo.BackupServers', 'U') IS NOT NULL DROP TABLE dbo.BackupServers;
GO

CREATE TABLE dbo.BackupServers (
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    ServerName NVARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dbo.BackupPolicies (
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    PolicyName NVARCHAR(100) NOT NULL UNIQUE,
    IntervalHours INT NOT NULL
);

CREATE TABLE dbo.ServerPolicyMaps (
    BackupServersId INT NOT NULL,
    BackupPoliciesId INT NOT NULL,
    IsActive BIT DEFAULT 1,
    CONSTRAINT PK_ServerPolicyMaps PRIMARY KEY (BackupServersId, BackupPoliciesId),
    CONSTRAINT FK_Map_BackupServers FOREIGN KEY (BackupServersId) REFERENCES dbo.BackupServers(Id),
    CONSTRAINT FK_Map_BackupPolicies FOREIGN KEY (BackupPoliciesId) REFERENCES dbo.BackupPolicies(Id)
);

CREATE TABLE dbo.BackupAuditTrail (
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    BackupServersId INT NOT NULL,
    BackupPoliciesId INT NOT NULL,
    ActionExecuted NVARCHAR(100) NOT NULL,
    ExecutedByUser NVARCHAR(100) DEFAULT SYSTEM_USER,
    LogTimestamp DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Audit_ServerPolicyMaps FOREIGN KEY (BackupServersId, BackupPoliciesId) REFERENCES dbo.ServerPolicyMaps(BackupServersId, BackupPoliciesId)
);
GO


-- =========================================================================
-- BLOCK 3: SEED-DATA & DML FRÅN MOCKAROO (Slank testdata för pipelines)
-- =========================================================================
INSERT INTO dbo.BackupServers (ServerName) VALUES 
('Prod-Web-01-Backup'), 
('Dev-Db-01-Backup'), 
('Stage-App-02-Backup');

INSERT INTO dbo.BackupPolicies (PolicyName, IntervalHours) VALUES 
('Daily-Incremental', 24), 
('Weekly-Full', 168);

INSERT INTO dbo.ServerPolicyMaps (BackupServersId, BackupPoliciesId) VALUES 
(1, 1),
(1, 2),
(2, 1),
(3, 2);

INSERT INTO dbo.BackupAuditTrail (BackupServersId, BackupPoliciesId, ActionExecuted) VALUES 
(1, 1, 'POLICY_ATTACHED_SUCCESS');
GO


-- =========================================================================
-- BLOCK 4: AUTOMATISERAD VERIFIERINGSLOGG (Pipeline-kontroll)
-- =========================================================================
SELECT 'Skarpa Incident Servers Count' AS TableName, COUNT(*) FROM dbo.Servers
UNION ALL
SELECT 'Skarpa Security Techs Count', COUNT(*) FROM dbo.SecurityTechs
UNION ALL
SELECT 'Skarpa Total Incidents Count', COUNT(*) FROM dbo.Incidents
UNION ALL
SELECT 'Greenfield Backup Servers', COUNT(*) FROM dbo.BackupServers
UNION ALL
SELECT 'Greenfield Backup Policies', COUNT(*) FROM dbo.BackupPolicies
UNION ALL
SELECT 'Greenfield M:M Policy Maps', COUNT(*) FROM dbo.ServerPolicyMaps
UNION ALL
SELECT 'Greenfield Audit Trail Logs', COUNT(*) FROM dbo.BackupAuditTrail;
GO
