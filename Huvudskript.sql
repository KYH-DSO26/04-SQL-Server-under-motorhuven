-- Uppgift 1 Skapa en hög (Heap)
create table AuditLogs_Heap (
	Id INT NOT NULL,
	LogMessage NVARCHAR(500) NOT NULL,
	CreatedAt DATETIME2 NOT NULL
);
GO

-- Uppgift 2 - Det automatiska indexet (Clustered)
create table AuditLogs_Clustered (
	Id INT NOT NULL,
	LogMessage NVARCHAR(500) NOT NULL,
	CreatedAt DATETIME2 NOT NULL,
	constraint PK_AuditLogs_Clustered primary key clustered (Id)
);
GO

-- POPULERA 50 000 RADER TESTDATA
-- Sätt tidmätning och räknare i minnet
set nocount on;	-- För attt slippa få ut "1 row affected" 100 000 gånger
declare @Counter INT = 1;
declare @RandomMessage NVARCHAR(500);
declare @RandomDate DATETIME2;

-- Starta loopen för 50 000 exekveringar
while @Counter <= 50000
BEGIN
	-- Generera lite testdata för varje rad
	set @RandomMessage = N'DevSecOps Audit event log #' 
		+ CAST(@Counter as nvarchar(10))
		+ N' - Firewall traffic authorized.';
	set @RandomDate = dateadd(second, @Counter, '2026-01-01 00:00:00'); -- Sprider ut tidsstämplarna

	-- Skjut in i Heap
	insert into AuditLogs_Heap(id, LogMessage, CreatedAt)
	values (@Counter, @RandomMessage, @RandomDate);

	-- Skjut in i Clustered-tabell
	insert into AuditLogs_Clustered(id, LogMessage, CreatedAt)
	values (@Counter, @RandomMessage, @RandomDate);

	-- Öka på räknaren
	set @Counter = @Counter + 1;
END;

-- Återställ systeminställning och verifiera dataladdningen
set nocount off;
print 'Dataladdning klar! Verifierar radantal:';

SELECT 'AuditLogs_Heap' AS TableName, COUNT(*) AS 'Number of rows' FROM dbo.AuditLogs_Heap
UNION ALL
SELECT 'AuditLogs_Clustered', COUNT(*)  FROM dbo.AuditLogs_Clustered;
GO

-- Uppgift 3: Det kirurgiska snittet (Non-Clustered)
create nonclustered index IX_AuditLogs_CreatedAt
on AuditLogs_Clustered(CreatedAt);
go

-- Uppgift 4. Verifiera indexstrukturen
-- select top 10 * from sys.indexes

select name, type_desc, is_unique
from sys.indexes
where object_id = object_id('dbo.AuditLogs_Clustered');

-- Uppgift 5
alter table dbo.Servers
add constraint UQ_Servers_ServerName unique (ServerName);
-- Ger oss ett (UNIQUE NONCLUSTERED INDEX)
-- Villket ger oss att det inte kan bli några dubletter för ServerName