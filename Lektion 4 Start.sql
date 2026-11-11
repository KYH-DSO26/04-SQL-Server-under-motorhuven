-- =========================================================================
-- FAILSAFE IT - STARTSKRIPT: LEKTION 4
-- Fokus: Fyller på med 10 000 incidenter för indextester och exekveringsplaner
-- Standard: PK heter Id, FK heter <Tabellnamn>Id
-- =========================================================================

USE FailSafeIT;
GO

-- Rensa tidigare incidenter och tilldelningar inför Lektion 4:s prestandatester
TRUNCATE TABLE dbo.IncidentAssignments;
ALTER TABLE dbo.Incidents NOCHECK CONSTRAINT FK_Incidents_Servers;
TRUNCATE TABLE dbo.Incidents;
ALTER TABLE dbo.Incidents CHECK CONSTRAINT FK_Incidents_Servers;
GO

-- =========================================================================
-- HEAVY INJECTION LOOP (10 000 rader för prestandatester)
-- =========================================================================
SET NOCOUNT ON;

DECLARE @FirstServerId INT;
SELECT TOP 1 @FirstServerId = Id FROM dbo.Servers ORDER BY Id ASC;

-- Säkerställ att det finns minst ett ServerId att länka till
IF @FirstServerId IS NULL
BEGIN
    INSERT INTO dbo.Servers (ServerName, IpAddress, Environment) VALUES ('Fallback-Server', '127.0.0.1', 'Staging');
    SELECT TOP 1 @FirstServerId = Id FROM dbo.Servers ORDER BY Id ASC;
END

DECLARE @Counter INT = 1;
DECLARE @TargetServerId INT;
DECLARE @Type NVARCHAR(100);
DECLARE @Sev NVARCHAR(50);
DECLARE @DaysAgo INT;
DECLARE @MaxTechs INT;

SELECT @MaxTechs = COUNT(*) FROM dbo.SecurityTechs;

WHILE @Counter <= 10000
BEGIN
    -- Fördela incidenterna dynamiskt över tillgängliga servrar från Lektion 1
    SET @TargetServerId = @FirstServerId + (@Counter % 4);
    
    -- Rotera incidenttyper och allvarlighetsgrad för bra statistikspridning
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
    INSERT INTO dbo.Incidents (ServersId, IncidentType, IncidentDate, Severity, Description)
    VALUES (
        @TargetServerId, 
        @Type, 
        DATEADD(DAY, -@DaysAgo, '2026-11-11'), 
        @Sev, 
        N'DevSecOps automated security alert #' + CAST(@Counter AS NVARCHAR(10)) + N' triggered on production server infrastructure.'
    );

    -- Skapa en automatisk koppling till en säkerhetstekniker (om tekniker saknas, använd standard ID 1)
    INSERT INTO dbo.IncidentAssignments (IncidentsId, SecurityTechsId)
    VALUES (@Counter, CASE WHEN @MaxTechs > 0 THEN (@Counter % @MaxTechs) + 1 ELSE 1 END);

    SET @Counter = @Counter + 1;
END;

SET NOCOUNT OFF;
PRINT 'Lektion 4-datainjektionen är klar! 10 000 incidenter laddade i FailSafeIT.';
GO
