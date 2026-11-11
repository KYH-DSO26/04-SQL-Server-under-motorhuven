-- =========================================================================
-- FAILSAFE IT - STARTSKRIPT: LEKTION 4
-- Fokus: Fyller på med 10 000 incidenter för indextester och exekveringsplaner
-- Standard: PK heter Id, FK heter <Tabellnamn>Id
-- =========================================================================

USE FailSafeIT;
GO

-- Rensa tidigare incidenter och tilldelningar inför Lektion 4:s prestandatester
-- 1. Rensa data i exakt rätt ordning baserat på Foreign Keys (Kopplingstabellen först)
DELETE FROM dbo.IncidentAssignments;
DELETE FROM dbo.Incidents;
DELETE FROM dbo.SecurityTechs;
GO

-- 2. Återställ IDENTITY-räknarna (Identity Seed) till 0 så att nästa rad startar på 1
DBCC CHECKIDENT ('dbo.Incidents', RESEED, 0);
DBCC CHECKIDENT ('dbo.SecurityTechs', RESEED, 0);
GO

-- =========================================================================
-- HEAVY INJECTION LOOP (10 000 rader för prestandatester) - PIPELINE-SÄKRAD
-- =========================================================================
SET NOCOUNT ON;

-- 1. Ladda om teknikerna först så vi vet att de finns
INSERT INTO dbo.SecurityTechs (TechName) VALUES 
('Erik Nilsson'), ('Lina Berg'), ('Anna Stark'), ('Kalle Blomqvist');

-- 2. Hämta giltiga ServerId från tabellen Servers för att garantera referensintegritet
DECLARE @FirstServerId INT;
SELECT TOP 1 @FirstServerId = Id FROM dbo.Servers ORDER BY Id ASC;
IF @FirstServerId IS NULL SET @FirstServerId = 1;

-- 3. Hämta de faktiska ID-numren på teknikerna till en temporär tabell i minnet
DECLARE @TechIds TABLE (RowNumber INT IDENTITY(1,1), TechId INT);
INSERT INTO @TechIds (TechId) SELECT Id FROM dbo.SecurityTechs;

DECLARE @MaxTechs INT;
SELECT @MaxTechs = COUNT(*) FROM @TechIds;

-- Initiera räknare för loopen
DECLARE @Counter INT = 1;
DECLARE @TargetServerId INT;
DECLARE @Type NVARCHAR(100);
DECLARE @Sev NVARCHAR(50);
DECLARE @DaysAgo INT;
DECLARE @TargetTechId INT;
DECLARE @CurrentIncidentId INT;

WHILE @Counter <= 10000
BEGIN
    -- Fördela incidenterna dynamiskt över tillgängliga servrar
    SET @TargetServerId = @FirstServerId + (@Counter % 4);
    
    -- Rotera incidenttyper och allvarlighetsgrad
    IF @Counter % 3 = 0
    BEGIN
        SET @Type = N'SQLi-Attempt';
        SET @Sev = N'CRITICAL';
    END
    ELSE IF @Counter % 3 = 1
    BEGIN
        SET @Type = N'DDoS-Traffic';
        SET @Sev = N'HIGH';
    END
    ELSE
    BEGIN
        SET @Type = N'UnauthorizedAccess';
        SET @Sev = N'MEDIUM';
    END

    SET @DaysAgo = @Counter % 365;

    -- Skjut in incidentloggen
    INSERT INTO dbo.Incidents (ServersId, IncidentType, IncidentDate, Severity)
    VALUES (
        @TargetServerId, 
        @Type, 
        DATEADD(DAY, -@DaysAgo, '2026-11-11'), 
        @Sev
    );

    -- Hämta det exakta Id-numret som SQL Server just skapade för denna incident
    SET @CurrentIncidentId = SCOPE_IDENTITY();

    -- Hämta ett garanterat existerande TechId från vår minnestabell (rotera mellan 1 och @MaxTechs)
    SELECT @TargetTechId = TechId 
    FROM @TechIds 
    WHERE RowNumber = ((@Counter % @MaxTechs) + 1);

    -- Skapa kopplingen i IncidentAssignments helt utan risk för FK-konflikter
    INSERT INTO dbo.IncidentAssignments (IncidentsId, SecurityTechsId)
    VALUES (@CurrentIncidentId, @TargetTechId);

    SET @Counter = @Counter + 1;
END;

SET NOCOUNT OFF;
PRINT 'Lektion 4-datainjektionen är klar! 10 000 incidenter och tilldelningar laddade utan FK-fel.';
GO
