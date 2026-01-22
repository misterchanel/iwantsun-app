# Script PowerShell pour installer l'APK sur un appareil Android
# Usage: .\install_apk.ps1

Write-Host "🔍 Recherche d'appareils Android connectés..." -ForegroundColor Cyan

# Vérifier si adb est disponible
$adbPath = $null
if ($env:ANDROID_HOME) {
    $adbPath = "$env:ANDROID_HOME\platform-tools\adb.exe"
} elseif (Test-Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe") {
    $adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
}

if (-not $adbPath -or -not (Test-Path $adbPath)) {
    Write-Host "❌ ADB non trouvé. Vérifiez que Android SDK est installé." -ForegroundColor Red
    Write-Host "💡 Le fichier APK est disponible ici :" -ForegroundColor Yellow
    Write-Host "   build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor White
    Write-Host ""
    Write-Host "Vous pouvez :" -ForegroundColor Yellow
    Write-Host "   1. Connecter un appareil Android via USB (mode débogage activé)" -ForegroundColor White
    Write-Host "   2. Utiliser l'émulateur via Android Studio" -ForegroundColor White
    Write-Host "   3. Transférer l'APK manuellement sur votre téléphone" -ForegroundColor White
    exit 1
}

# Lister les appareils
Write-Host "📱 Appareils connectés :" -ForegroundColor Cyan
& $adbPath devices

# Chemin vers l'APK
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"

if (-not (Test-Path $apkPath)) {
    Write-Host "❌ APK non trouvé : $apkPath" -ForegroundColor Red
    Write-Host "💡 Générez d'abord l'APK avec : flutter build apk --debug" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "📦 Installation de l'APK..." -ForegroundColor Cyan
& $adbPath install -r $apkPath

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ APK installé avec succès !" -ForegroundColor Green
    Write-Host "📱 Lancez l'application depuis votre appareil." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Erreur lors de l'installation." -ForegroundColor Red
    Write-Host "💡 Vérifiez qu'un appareil est connecté et que le débogage USB est activé." -ForegroundColor Yellow
}
