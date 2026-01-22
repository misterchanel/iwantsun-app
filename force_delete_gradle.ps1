# Script pour forcer la suppression du cache Gradle
# Utilisez ce script si la suppression normale echoue

Write-Host "Suppression forcee du cache Gradle..." -ForegroundColor Yellow
Write-Host ""

$gradleCachePath = "$env:USERPROFILE\.gradle"

if (-not (Test-Path $gradleCachePath)) {
    Write-Host "Le cache Gradle n'existe pas." -ForegroundColor Gray
    exit
}

# Arreter tous les processus Java/Gradle
Write-Host "1. Arret des processus..." -ForegroundColor Cyan
Get-Process | Where-Object {$_.ProcessName -like "*java*" -or $_.ProcessName -like "*gradle*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Essayer de supprimer avec takeown et icacls (necessite admin)
Write-Host "2. Tentative de prise de controle des fichiers..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "takeown" -ArgumentList "/F `"$gradleCachePath`" /R /D Y" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    Start-Process -FilePath "icacls" -ArgumentList "`"$gradleCachePath`" /grant `"$env:USERNAME:(F)`" /T" -Wait -NoNewWindow -ErrorAction SilentlyContinue
} catch {
    Write-Host "   (Prise de controle non disponible - continuons)" -ForegroundColor Gray
}

# Supprimer recursivement avec retry
Write-Host "3. Suppression des fichiers..." -ForegroundColor Cyan
$maxRetries = 3
$retry = 0
$success = $false

while (-not $success -and $retry -lt $maxRetries) {
    $retry++
    Write-Host "   Tentative $retry/$maxRetries..." -ForegroundColor Gray
    
    try {
        # Supprimer les fichiers individuels d'abord
        Get-ChildItem -Path $gradleCachePath -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -ErrorAction Stop
            } catch {
                # Fichier verrouille - on continue
            }
        }
        
        # Puis les dossiers
        Get-ChildItem -Path $gradleCachePath -Recurse -Directory -Force -ErrorAction SilentlyContinue | 
            Sort-Object -Property FullName -Descending | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -ErrorAction Stop
            } catch {
                # Dossier verrouille - on continue
            }
        }
        
        # Enfin le dossier racine
        Remove-Item -Path $gradleCachePath -Recurse -Force -ErrorAction Stop
        $success = $true
        Write-Host "   SUCCES - Cache supprime" -ForegroundColor Green
    } catch {
        if ($retry -lt $maxRetries) {
            Write-Host "   Echec - Nouvelle tentative dans 2 secondes..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        } else {
            Write-Host "   ERREUR - Impossible de supprimer completement le cache" -ForegroundColor Red
            Write-Host "   Solution recommandee: Redemarrez votre ordinateur et relancez ce script" -ForegroundColor Yellow
        }
    }
}

if (Test-Path $gradleCachePath) {
    Write-Host ""
    Write-Host "Le cache Gradle est partiellement supprime mais certains fichiers restent verrouilles." -ForegroundColor Yellow
    Write-Host "Redemarrez votre ordinateur pour liberer les verrous, puis relancez le script." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Cache Gradle supprime avec succes !" -ForegroundColor Green
}
