/* ============================================================================
   FAILSAFE IT - INFRASTRUKTUR- OCH BEHÖRIGHETSREGISTER
   FACIT & LÖSNINGAR FÖR LEKTION 2: Relationsdjup, Indexering & Databashärdning
   ============================================================================ */

USE FailSafeIT;
GO

-- ============================================================================
/* 🟢 GRÖNA UPPGIFTER: RELATIONER & TABELLPUSSEL */
-- ============================================================================

-- Uppgift 1: Den interna inventeringen
-- Skriver en INNER JOIN för att endast hämta servrar som har en matchad administratör.
PRINT 'Kör lösning för Uppgift 1...';
SELECT 
    s.ServerName, 
    s.IpAddress, 
    s.Environment, 
    u.Username, 
    u.Email
FROM Servers s
INNER JOIN Users u ON s.ManagedByUserId = u.Id;
GO


-- Uppgift 2: Orkestreringsluckan
-- Använder LEFT JOIN för att lista ALLA användare, inklusive elena_ghost som saknar serveransvar.
PRINT 'Kör lösning för Uppgift 2...';
SELECT 
    u.Username, 
    u.Role, 
    s.ServerName, 
    s.Environment
FROM Users u
LEFT JOIN Servers s ON u.Id = s.ManagedByUserId
ORDER BY s.ServerName ASC;
GO


-- Uppgift 3: De herrelösa maskinerna
-- Använder RIGHT JOIN kombinerat med ett WHERE-villkor för att isolera servrar utan administratör.
PRINT 'Kör lösning för Uppgift 3...';
SELECT 
    s.ServerName, 
    s.IpAddress, 
    s.Environment,
    u.Username
FROM Users u
RIGHT JOIN Servers s ON u.Id = s.ManagedByUserId
WHERE s.ManagedByUserId IS NULL;
GO


-- Uppgift 4: Den totala överblicken
-- Använder FULL OUTER JOIN för att göra en totalreconciliation över hela registret.
PRINT 'Kör lösning för Uppgift 4...';
SELECT 
    u.Username, 
    s.ServerName, 
    s.Environment
FROM Users u
FULL OUTER JOIN Servers s ON u.Id = s.ManagedByUserId;
GO


-- Uppgift 5: Det fysiska låset
-- Skapar en stenhård databasregel (Foreign Key Constraint) med ON DELETE SET NULL.
PRINT 'Kör lösning för Uppgift 5...';
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Servers_Users')
BEGIN
    ALTER TABLE Servers 
    ADD CONSTRAINT FK_Servers_Users 
    FOREIGN KEY (ManagedByUserId) REFERENCES Users(Id)
    ON DELETE SET NULL;
    PRINT '-> Foreign Key Constraint upprättad framgångsrikt.';
END
ELSE
BEGIN
    PRINT '-> Foreign Key Constraint existerar redan.';
END
GO


-- ============================================================================
/* 🟡 GULA UPPGIFTER: APP, PRESTANDA & PARAMETRISERING */
-- ============================================================================

-- Uppgift 6: Miljökontrollen
-- Filtrerar en INNER JOIN med IN-operatorn för att sourca specifika miljöer.
PRINT 'Kör lösning för Uppgift 6...';
SELECT 
    u.Username, 
    s.ServerName, 
    s.Environment
FROM Users u
INNER JOIN Servers s ON u.Id = s.ManagedByUserId
WHERE s.Environment IN ('Production', 'Staging');
GO


-- Uppgift 7: Snabba spår i loggen
-- Skapar ett Non-Clustered Index för att transformera Table Scans till Index Seeks vid FK-validering.
PRINT 'Kör lösning för Uppgift 7...';
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Servers_ManagedByUserId')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Servers_ManagedByUserId 
    ON Servers(ManagedByUserId);
    PRINT '-> Non-Clustered Index IX_Servers_ManagedByUserId har skapats.';
END
ELSE
BEGIN
    PRINT '-> Indexet existerar redan.';
END
GO

-- Notering till Uppgift 8, 9 och 10: 
-- Dessa löses inuti C#-applikationen (Program.cs) med ADO.NET (SqlParameter).


-- ============================================================================
/* 🔴 RÖDA UPPGIFTER: AVANCERAD DEVSECOPS & DATABASHÄRDNING */
-- ============================================================================

-- Uppgift 11: Inkapsling via DDL
-- Skapar en lagrad procedur för säker och kontrollerad inmatning.
PRINT 'Skapar eller uppdaterar Stored Procedure för Uppgift 11...';
GO
CREATE OR ALTER PROCEDURE usp_RegisterServer
    @ServerName NVARCHAR(100),
    @IpAddress VARCHAR(50),
    @Environment NVARCHAR(50),
    @ManagedByUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Servers (ServerName, IpAddress, Environment, ManagedByUserId)
    VALUES (@ServerName, @IpAddress, @Environment, @ManagedByUserId);
END;
GO
PRINT '-> Stored Procedure usp_RegisterServer är redo.';
GO


-- Uppgift 14: Principen om minsta behörighet (Least Privilege)
-- Skapar applikationskontot och klipper bort all direkt tabellåtkomst.
PRINT 'Kör lösning för Uppgift 14...';
GO

-- Skapa SQL Server-inloggning om den inte finns
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'FailsafeApp')
BEGIN
    CREATE LOGIN FailsafeApp WITH PASSWORD = 'DbPassword_Secure123!';
END

-- Skapa databasanvändaren om den inte finns
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'FailsafeApp')
BEGIN
    CREATE USER FailsafeApp FOR LOGIN FailsafeApp;
END
GO

-- Tillämpa stenhård DENY-policy på tabellnivå
DENY SELECT, INSERT, UPDATE, DELETE ON Users TO FailsafeApp;
DENY SELECT, INSERT, UPDATE, DELETE ON Servers TO FailsafeApp;
PRINT '-> Råtabeller helt låsta för användaren FailsafeApp (DENY aktiverat).';
GO


-- Uppgift 15: Skölden aktiveras
-- Ger exekveringsrättighet exklusivt till den säkra Stored Proceduren.
PRINT 'Kör lösning för Uppgift 15...';
GRANT EXECUTE ON sp_RegisterServer TO FailsafeApp;
PRINT '-> EXEKVERINGSRÄTTIGHET (GRANT EXECUTE) har tilldelats FailsafeApp.';
GO


-- VERIFIERINGSTEST AV SKÖLDEN (Simuleras inifrån SSMS)
PRINT '============================================================================';
PRINT 'STARTAR FUNKTIONSTEST AV HANDS-ON INTEGRITET OCH SÄKERHET';
PRINT '============================================================================';
GO

-- Byt till den begränsade användarens säkerhetskontext
EXECUTE AS USER = 'FailsafeApp';
PRINT 'Loggar in virtuellt som: ' + USER_NAME();

BEGIN TRY
    -- Detta SKA misslyckas på grund av vår DENY-regel
    PRINT 'Försöker köra en direkt SELECT * FROM Users...';
    SELECT * FROM Users;
END TRY
BEGIN CATCH
    PRINT '👉 [STOPPAD AV DATABASEN] Direktsökning blockerad som förväntat! Felmeddelande: ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    -- Detta SKA lyckas eftersom vi har GRANT EXECUTE på denna procedur
    PRINT 'Försöker registrera en ny server via den säkra sp_RegisterServer...';
    EXEC usp_RegisterServer 
        @ServerName = 'isolated-dmz-01', 
        @IpAddress = '10.10.10.10', 
        @Environment = 'Production', 
        @ManagedByUserId = 1;
    PRINT '👉 [GODKÄND] Servern registrerades säkert via RPC!';
END TRY
BEGIN CATCH
    PRINT '❌ Fel uppstod vid proceduranrop: ' + ERROR_MESSAGE();
END CATCH;

-- Återställ säkerhetskontexten till administratör (sa)
REVERT;
PRINT 'Återställd säkerhetskontext till administratör: ' + USER_NAME();
PRINT '============================================================================';
