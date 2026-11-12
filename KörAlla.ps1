# Spara denna fil som KörAlla.ps1 i samma mapp som dina .sql-filer
$Server = "(localdb)\MSSQLLocalDB"
$Databas = "FailSafeIT"

# Kliv in i mappen där skripten ligger (fungerar alltid, även med mellanslag)
Set-Location -Path $PSScriptRoot

Write-Host "Startar körning av skript mot $Databas på $Server..." -ForegroundColor Cyan
$StartTid = Get-Date

# Kör sqlcmd och skicka in den aktuella mappens sökväg
# Flaggan -b gör att sqlcmd returnerar en felkod vid SQL-fel
# Lägg märke till citattecknen runt variabelvärdet
sqlcmd -S $Server -d $Databas -E -b -i "HuvudSkript.sql"

# Kontrollera om sqlcmd avslutades med en felkod ($LASTEXITCODE skilt från 0)
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[FEL] Körningen avbröts på grund av ett fel i SQL-skriptet!" -ForegroundColor Red
    Write-Host "Kontrollera felmeddelandet ovan för att se vilket steg som misslyckades." -ForegroundColor Yellow
} 
else {
    $SlutTid = Get-Date
    $Tidsatgang = $SlutTid - $StartTid
    Write-Host "`n[KLART] Samtliga skript kördes utan fel!" -ForegroundColor Green
    Write-Host ("Total exekveringstid: {0:hh\:mm\:ss\.fff}" -f $Tidsatgang) -ForegroundColor Cyan
}

# Pausa så att fönstret inte stängs automatiskt om du dubbelklickar på filen
Write-Host "`nTryck på valfri tangent för att stänga..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
