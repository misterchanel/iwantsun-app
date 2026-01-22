# Script pour recuperer les logs Firebase et Android
# Usage: .\recuperer_logs.ps1

Write-Host 'Recuperation des Logs - IWantSun' -ForegroundColor Cyan
Write-Host '=====================================' -ForegroundColor Cyan
Write-Host ''

$timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$logsDir = "logs_$timestamp"
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

Write-Host '1. Recuperation des logs Android...' -ForegroundColor Yellow

# Verifier si adb est disponible
$adbPath = Get-Command adb -ErrorAction SilentlyContinue
if ($adbPath) {
    Write-Host '   ADB trouve, recuperation des logs...' -ForegroundColor Green
    adb logcat -d > "$logsDir\android_logcat.txt" 2>&1
    Write-Host "   Logs Android sauvegardes dans $logsDir\android_logcat.txt" -ForegroundColor Green
} else {
    Write-Host '   ADB non trouve. Essayez avec flutter logs...' -ForegroundColor Yellow
    
    # Essayer avec flutter logs
    $flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterPath) {
        Write-Host '   Flutter trouve, recuperation des logs...' -ForegroundColor Green
        Write-Host '   Note: flutter logs necessite que l app soit en cours d execution' -ForegroundColor Yellow
        Write-Host '   Conseil: Lancez flutter logs dans un autre terminal pendant que vous testez' -ForegroundColor Cyan
    } else {
        Write-Host '   Flutter non trouve non plus' -ForegroundColor Red
    }
}

Write-Host ''
Write-Host '2. Recuperation des logs Firebase Functions...' -ForegroundColor Yellow

# Verifier si firebase CLI est disponible
$firebasePath = Get-Command firebase -ErrorAction SilentlyContinue
if ($firebasePath) {
    Write-Host '   Firebase CLI trouve, recuperation des logs...' -ForegroundColor Green
    Push-Location functions
    firebase functions:log --limit 100 > "..\$logsDir\firebase_functions.txt" 2>&1
    Pop-Location
    Write-Host "   Logs Firebase sauvegardes dans $logsDir\firebase_functions.txt" -ForegroundColor Green
} else {
    Write-Host '   Firebase CLI non trouve dans le PATH' -ForegroundColor Yellow
    Write-Host '   Alternatives:' -ForegroundColor Cyan
    Write-Host '      1. Installer Firebase CLI: npm install -g firebase-tools' -ForegroundColor White
    Write-Host '      2. Ou consulter les logs dans Firebase Console' -ForegroundColor White
    Write-Host '         https://console.firebase.google.com/project/iwantsun-b6b46/functions/logs' -ForegroundColor Gray
}

Write-Host ''
Write-Host '3. Filtrage des logs pertinents...' -ForegroundColor Yellow

# Filtrer les logs Android pour les erreurs et Firebase
if (Test-Path "$logsDir\android_logcat.txt") {
    $androidLogs = Get-Content "$logsDir\android_logcat.txt" -Raw
    if ($androidLogs) {
        # Extraire les lignes pertinentes
        $filteredAndroid = $androidLogs | Select-String -Pattern 'Firebase|searchDestinations|IWantsun|ERROR|Exception|HiveError|FATAL' -Context 2,2
        if ($filteredAndroid) {
            $filteredAndroid | Out-File "$logsDir\android_filtered.txt" -Encoding UTF8
            Write-Host "   Logs Android filtres sauvegardes dans $logsDir\android_filtered.txt" -ForegroundColor Green
        }
    }
}

# Filtrer les logs Firebase pour les erreurs
if (Test-Path "$logsDir\firebase_functions.txt") {
    $firebaseLogs = Get-Content "$logsDir\firebase_functions.txt" -Raw
    if ($firebaseLogs) {
        # Extraire les lignes pertinentes
        $filteredFirebase = $firebaseLogs | Select-String -Pattern 'error|Error|ERROR|failed|Failed|FAILED|timeout|Timeout|504|500' -Context 1,1
        if ($filteredFirebase) {
            $filteredFirebase | Out-File "$logsDir\firebase_filtered.txt" -Encoding UTF8
            Write-Host "   Logs Firebase filtres sauvegardes dans $logsDir\firebase_filtered.txt" -ForegroundColor Green
        }
    }
}

Write-Host ''
Write-Host '=====================================' -ForegroundColor Cyan
Write-Host 'Recuperation terminee !' -ForegroundColor Green
Write-Host ''
Write-Host "Fichiers sauvegardes dans: $logsDir\" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Prochaines etapes:' -ForegroundColor Yellow
Write-Host "   1. Verifiez les fichiers dans $logsDir\" -ForegroundColor White
Write-Host '   2. Partagez les logs avec l agent pour analyse' -ForegroundColor White
Write-Host '   3. Ou consultez directement Firebase Console pour les logs serveur' -ForegroundColor White
Write-Host ''
