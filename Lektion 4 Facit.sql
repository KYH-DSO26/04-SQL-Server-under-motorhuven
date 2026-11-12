-- =========================================================================
-- FAILSAFE IT - OFFICIAL FACIT-SKRIPT: LEKTION 4 (ALLA 15 UPPGIFTER)
-- Fokus: Heaps, Indexering, Exekveringsplaner, Prestanda & Säkerhet (usp_)
-- Namnstandard: PK heter Id, FK heter <Tabellnamn>Id
-- =========================================================================

USE FailSafeIT;
GO

-- =========================================================================
-- UPPGIFT 1: SKAPA EN HÖG (HEAP)
-- =========================================================================
IF OBJECT_ID('dbo.AuditLogs_Heap', 'U') IS NOT NULL DROP TABLE dbo.AuditLogs_Heap;
GO

CREATE TABLE dbo.AuditLogs_Heap (
    Id INT NOT NULL,
    LogMessage NVARCHAR(500) NOT NULL,
    CreatedAt DATETIME2 NOT NULL
);
GO

-- SVAR UPPGIFT 1:
-- Fråga: Vad kännetecknar en Heap i SQL Server och hur lagras datan?
-- Svar: En Heap saknar helt ett Clustered Index. Datan lagras i ett oordnat
-- kaos på disk (IAM-sidor håller koll på var sidorna finns). Nya rader 
-- läggs bara till där det råkar finnas ledigt utrymme.


-- =========================================================================
-- UPPGIFT 2: DET AUTOMATISKA INDEXET (CLUSTERED INDEX VIA PK)
-- =========================================================================
IF OBJECT_ID('dbo.AuditLogs_Clustered', 'U') IS NOT NULL DROP TABLE dbo.AuditLogs_Clustered;
GO

CREATE TABLE dbo.AuditLogs_Clustered (
    Id INT NOT NULL,
    LogMessage NVARCHAR(500) NOT NULL,
    CreatedAt DATETIME2 NOT NULL,
    CONSTRAINT PK_AuditLogs_Clustered PRIMARY KEY CLUSTERED (Id)
);
GO

-- SVAR UPPGIFT 2:
-- Fråga: Vad är den fysiska skillnaden under motorhuven mellan en Heap och en Clustered-tabell?
-- Svar: En Clustered-tabell ÄR ett index. Datan lagras inte i ett kaos, utan sorteras 
-- fysiskt på hårddisken i ett så kallat B-träd (balanserat träd) baserat på indexnyckeln (Id).


-- =========================================================================
-- UPPGIFT 3: MASSLADDNING AV 50 000 RADER TESTDATA (WHILE-LOOP)
-- =========================================================================
SET NOCOUNT ON;
DECLARE @Counter INT = 1;
DECLARE @RandomMessage NVARCHAR(500);
DECLARE @RandomDate DATETIME2;

WHILE @Counter <= 50000
BEGIN
    SET @RandomMessage = N'DevSecOps Audit Event Log #' + CAST(@Counter AS NVARCHAR(10)) + N' - Firewall traffic authorized.';
    SET @RandomDate = DATEADD(SECOND, @Counter, '2026-01-01 00:00:00');

    INSERT INTO dbo.AuditLogs_Heap (Id, LogMessage, CreatedAt)
    VALUES (@Counter, @RandomMessage, @RandomDate);

    INSERT INTO dbo.AuditLogs_Clustered (Id, LogMessage, CreatedAt)
    VALUES (@Counter, @RandomMessage, @RandomDate);

    SET @Counter = @Counter + 1;
END;
SET NOCOUNT OFF;
PRINT 'Uppgift 3 klar: 50 000 rader laddade.';
GO


-- =========================================================================
-- UPPGIFT 4: PRESTANDAPRÖVNING – TABLE SCAN VS INDEX SEEK
-- =========================================================================
-- Instruktion: Aktivera "Actual Execution Plan" (Ctrl+M) i SSMS innan körning!

-- Sökning i Heapen
SELECT * FROM dbo.AuditLogs_Heap WHERE Id = 25000;

-- Sökning i Clustered-tabellen
SELECT * FROM dbo.AuditLogs_Clustered WHERE Id = 25000;
GO

-- SVAR UPPGIFT 4:
-- Fråga: Vilka två olika operationer ser du i exekveringsplanerna och varför?
-- Svar: Heapen tvingar fram en "Table Scan" (SQL Server måste läsa igenom alla 50 000 
-- rader från start till slut för att hitta id 25000). Clustered-tabellen gör en 
-- "Clustered Index Seek", där den mha B-trädet hittar raden på 2-3 sidläsningar.


-- =========================================================================
-- UPPGIFT 5: SKAPA ETT NON-CLUSTERED INDEX (SÖKOPTIMERING)
-- =========================================================================
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLogs_Clustered_CreatedAt' AND object_id = OBJECT_ID('dbo.AuditLogs_Clustered'))
    DROP INDEX IX_AuditLogs_Clustered_CreatedAt ON dbo.AuditLogs_Clustered;
GO

CREATE NONCLUSTERED INDEX IX_AuditLogs_Clustered_CreatedAt
ON dbo.AuditLogs_Clustered (CreatedAt);
GO


-- =========================================================================
-- UPPGIFT 6: SÖKNING MED NON-CLUSTERED INDEX (INDEX SEEK VS LOOKUP)
-- =========================================================================
-- Query A: Hämtar bara nycklar och index-täckta fält
SELECT Id, CreatedAt FROM dbo.AuditLogs_Clustered 
WHERE CreatedAt = '2026-01-01 00:00:05.0000000';

-- Query B: Hämtar fält som inte finns i vårt Non-Clustered Index
SELECT * FROM dbo.AuditLogs_Clustered 
WHERE CreatedAt = '2026-01-01 00:00:05.0000000';
GO

-- SVAR UPPGIFT 6:
-- Fråga: Varför dyker det upp en "Key Lookup" i exekveringsplanen för Query B?
-- Svar: Eftersom kolumnen "LogMessage" inte finns sparad i vårt Non-Clustered index, 
-- måste SQL Server först göra en "Index Seek" i IX_AuditLogs_Clustered_CreatedAt, och 
-- sedan göra en dyr "Key Lookup" (hoppa till det fysiska databladet via Clustered Index) 
-- för att hämta textsträngen.


-- =========================================================================
-- UPPGIFT 7: COVERING INDEX (PRESTANDAMAXIMERING UTAN LOOKUPS)
-- =========================================================================
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AuditLogs_Covering_Optimization' AND object_id = OBJECT_ID('dbo.AuditLogs_Clustered'))
    DROP INDEX IX_AuditLogs_Covering_Optimization ON dbo.AuditLogs_Clustered;
GO

CREATE NONCLUSTERED INDEX IX_AuditLogs_Covering_Optimization
ON dbo.AuditLogs_Clustered (CreatedAt)
INCLUDE (LogMessage); -- Vi inkluderar datan i indexets bladnoder
GO


-- =========================================================================
-- UPPGIFT 8: PRESTANDATEST AV DET TÄCKANDE INDEXET
-- =========================================================================
SELECT Id, LogMessage FROM dbo.AuditLogs_Clustered 
WHERE CreatedAt BETWEEN '2026-01-01 00:00:01' AND '2026-01-01 00:00:10';
GO

-- SVAR UPPGIFT 8:
-- Fråga: Vad hände med vår Key Lookup i exekveringsplanen nu?
-- Svar: Den försvann helt och blev till en ren "Index Seek". Indexet är nu "täckande" 
-- (Covering Index) för denna query, eftersom all information som efterfrågas (Id, LogMessage 
-- och CreatedAt) finns lagrad direkt i själva indexstrukturen.


-- =========================================================================
-- UPPGIFT 9: PRESTANDA I KOMPLEXA JOINS (INCIDENTS & SERVERS)
-- =========================================================================
-- Körs mot de 10 000 tunga incident-raderna som matades in i startskriptet.
SELECT s.ServerName, i.IncidentType, i.Severity
FROM dbo.Incidents i
INNER JOIN dbo.Servers s ON i.ServersId = s.Id 
WHERE i.IncidentType = 'SQLi-Attempt' AND s.Environment = 'Production';
GO

-- SVAR UPPGIFT 9:
-- Fråga: Vilken JOIN-algoritm (Nested Loops, Hash Match eller Merge Join) valde SQL Server?
-- Svar: SQL Server väljer oftast en "Hash Match" eller "Table Scan / Clustered Index Scan" 
-- här eftersom det saknas lämpliga index på den främmande nyckeln i Incidents-tabellen.


-- =========================================================================
-- UPPGIFT 10: OPTIMERING AV RELEVANTA FRÄMMANDE NYCKLAR (FK)
-- =========================================================================
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Incidents_ServersId' AND object_id = OBJECT_ID('dbo.Incidents'))
    DROP INDEX IX_Incidents_ServersId ON dbo.Incidents;
GO

CREATE NONCLUSTERED INDEX IX_Incidents_ServersId
ON dbo.Incidents (ServersId)
INCLUDE (IncidentType, Severity);
GO


-- =========================================================================
-- UPPGIFT 11: VERIFIERING AV FK-OPTIMERINGEN
-- =========================================================================
-- Kör om queryn från Uppgift 9 och analysera exekveringsplanen igen.
SELECT s.ServerName, i.IncidentType, i.Severity
FROM dbo.Incidents i
INNER JOIN dbo.Servers s ON i.ServersId = s.Id
WHERE i.IncidentType = 'SQLi-Attempt' AND s.Environment = 'Production';
GO

-- SVAR UPPGIFT 11:
-- Fråga: Hur förändrades exekveringsplanen efter att indexet på vår FK skapades?
-- Svar: Den gick från en dyr Scan/Hash Match till en extremt effektiv "Nested Loops" 
-- i kombination med en "Index Seek" på Incidents-tabellen. Databasen presterar nu 
-- mångdubbelt snabbare under hög belastning.


-- =========================================================================
-- UPPGIFT 12: SÄKRA STORED PROCEDURES MED NAMNSTANDARD (USP_)
-- =========================================================================
IF OBJECT_ID('dbo.usp_GetCriticalServerIncidents', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_GetCriticalServerIncidents;
GO

CREATE PROCEDURE dbo.usp_GetCriticalServerIncidents
    @Environment NVARCHAR(50),
    @Severity NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(*)
        s.ServerName, 
        s.IpAddress, 
        i.IncidentType, 
        i.IncidentDate, 
        i.Severity
    FROM dbo.Incidents i
    INNER JOIN dbo.Servers s ON i.ServersId = s.Id
    WHERE s.Environment = @Environment 
      AND i.Severity = @Severity;
END;
GO

-- SVAR UPPGIFT 12:
-- Fråga: Varför använder vi prefixet usp_ istället för sp_?
-- Svar: Prefixet sp_ är reserverat för Microsofts egna systemprocedurer. Om man döper en 
-- procedur till sp_ kommer SQL Server alltid att söka igenom master-databasen först, vilket 
-- slösar på prestandan. usp_ (User Stored Procedure) isolerar exekveringen till vår databas.


-- =========================================================================
-- UPPGIFT 13: EXEKVERING OCH PIPELINE-VERIFIERING
-- =========================================================================
EXEC dbo.usp_GetCriticalServerIncidents @Environment = N'Production', @Severity = N'CRITICAL';
GO

-- =========================================================================
-- UPPGIFT 14: EXTREM PRESTANDALAGNING (COMPOSITE INDEX)
-- =========================================================================
-- Skapa ett sammansatt index optimerat direkt för sökkriterierna i vår Stored Procedure
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Incidents_Type_Date' AND object_id = OBJECT_ID('dbo.Incidents'))
DROP INDEX IX_Incidents_Type_Date ON dbo.Incidents;
GO
CREATE NONCLUSTERED INDEX IX_Incidents_Type_Date
ON dbo.Incidents (IncidentType, IncidentDate);
GO
-- =========================================================================
-- UPPGIFT 15: SISTA PIPELINE-RENSNINGEN (CLEANUP-MODUL)
-- =========================================================================
-- Droppa enbart de temporära test-tabellerna vi skapade i Uppgift 1 och 2 för att frigöra utrymme,
-- men lämna den skarpare FailSafeIT-strukturen (Incidents/Servers) helt orörd.
IF OBJECT_ID('dbo.AuditLogs_Heap', 'U') IS NOT NULL DROP TABLE dbo.AuditLogs_Heap;
IF OBJECT_ID('dbo.AuditLogs_Clustered', 'U') IS NOT NULL DROP TABLE dbo.AuditLogs_Clustered;
GO
PRINT 'Lektion 4: Cleanup klar. Test-heaps borttagna, enterprise-strukturen säkrad!';
GO
