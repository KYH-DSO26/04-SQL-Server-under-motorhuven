-- =========================================================================
-- FAILSAFE IT - KÖR ALLA SKRIPT FRÅN LEKTION 1 - LEKTION 4
-- Kör detta skript så skapas databasen på nytt och fylls på
--
-- VIKTIGT: Börja med att aktivera SQLCMD Mode. 
--	Gå till toppmenyn, klicka på Query och välj SQLCMD Mode 
--	(du ser att bakgrunden bakom :r-raderna blir gråmarkerad när det är aktivt).
--
-- VIKTIGT 2: Kör inte detta skriptet direkt i SSMS. 
--			Det är till för att startas inifrån KörAlla.ps1
-- =========================================================================

-- Viktigt: Stoppa hela körningen direkt om ett av skripten kastar ett fel
:on error exit

PRINT '=== Startar körning av samtliga skript ===';

PRINT 'Steg 1: Kör Lektion 1 Facit...';
:r "Lektion_1_Facit.sql"
GO

PRINT 'Steg 2: Kör Lektion 2 Facit...';
:r "Lektion 2 Facit.sql"
GO

PRINT 'Steg 3: Kör Lektion 3 Facit...';
:r "Lektion 3 Facit.sql"
GO

PRINT 'Steg 4: Kör Lektion 4 Start...';
:r "Lektion 4 Start.sql"
GO

PRINT 'Steg 5: Kör Lektion 4 Facit...';
:r "Lektion 4 Facit.sql"
GO

PRINT '=== Alla skript har körts klart utan fel! ===';
