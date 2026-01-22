# Solution rapide : Supprime uniquement les fichiers corrompus du cache Gradle
# Plus rapide que de tout supprimer

Write-Host "Correction du cache Gradle corrompu..." -ForegroundColor Yellow
Write-Host ""

$cachePath = "$env:USERPROFILE\.gradle\caches"

# Arreter les processus Java/Gradle
Write-Host "Arret des processus Java/Gradle..." -ForegroundColor Cyan
Get-Process | Where-Object {$_.ProcessName -like "*java*" -or $_.ProcessName -like "*gradle*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Supprimer uniquement le journal corrompu (le fichier problematique)
Write-Host "Suppression du journal corrompu..." -ForegroundColor Cyan
$journalPath = "$cachePath\journal-1"
if (Test-Path $journalPath) {
    Remove-Item -Path "$journalPath\file-access.bin" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$journalPath" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "OK - Journal corrompu supprime" -ForegroundColor Green
}

# Supprimer les caches Kotlin DSL corrompus
Write-Host "Suppression des caches Kotlin DSL..." -ForegroundColor Cyan
$kotlinDslPath = "$cachePath\8.9\kotlin-dsl"
if (Test-Path $kotlinDslPath) {
    Remove-Item -Path "$kotlinDslPath\accessors" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "OK - Cache Kotlin DSL supprime" -ForegroundColor Green
}

Write-Host ""
Write-Host "Cache corrige ! Vous pouvez maintenant lancer: flutter build apk --release" -ForegroundColor Green
