# Script de deploiement IWantSun
# Deploie les Firebase Functions et construit l'APK

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deploiement IWantSun" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Etape 1: Build des Firebase Functions
Write-Host "[1/3] Compilation des Firebase Functions..." -ForegroundColor Yellow
Set-Location functions
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR: Compilation des fonctions echouee" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..
Write-Host "OK - Functions compilees" -ForegroundColor Green
Write-Host ""

# Etape 2: Deploiement Firebase Functions
Write-Host "[2/3] Deploiement des Firebase Functions..." -ForegroundColor Yellow
Write-Host "Utilisez: npx firebase-tools deploy --only functions" -ForegroundColor Cyan
Write-Host "Ou connectez-vous d'abord: npx firebase-tools login" -ForegroundColor Cyan
Write-Host ""

# Demander confirmation
$deploy = Read-Host "Voulez-vous deployer maintenant? (O/N)"
if ($deploy -eq "O" -or $deploy -eq "o") {
    npx firebase-tools deploy --only functions
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK - Functions deployees avec succes!" -ForegroundColor Green
    } else {
        Write-Host "ATTENTION: Le deploiement a echoue. Verifiez que vous etes connecte a Firebase." -ForegroundColor Yellow
    }
} else {
    Write-Host "Deploiement ignore. Vous pouvez le faire plus tard avec:" -ForegroundColor Yellow
    Write-Host "   npx firebase-tools deploy --only functions" -ForegroundColor White
}
Write-Host ""

# Etape 3: Build APK
Write-Host "[3/3] Construction de l'APK..." -ForegroundColor Yellow
Write-Host "Cela peut prendre plusieurs minutes..." -ForegroundColor Cyan
Write-Host ""

$buildType = Read-Host "Type de build? (1=Debug, 2=Release) [1]"
if ($buildType -eq "" -or $buildType -eq "1") {
    flutter build apk --debug
    $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
} else {
    flutter build apk --release
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "OK - APK genere avec succes!" -ForegroundColor Green
    Write-Host "Emplacement: $apkPath" -ForegroundColor Cyan
    Write-Host ""
    
    # Proposer l'installation
    $install = Read-Host "Voulez-vous installer l'APK sur votre telephone? (O/N)"
    if ($install -eq "O" -or $install -eq "o") {
        .\install_apk.ps1
    } else {
        Write-Host ""
        Write-Host "Pour installer manuellement:" -ForegroundColor Yellow
        Write-Host "   1. Transferez $apkPath sur votre telephone" -ForegroundColor White
        Write-Host "   2. Activez 'Sources inconnues' dans les parametres" -ForegroundColor White
        Write-Host "   3. Ouvrez le fichier APK sur votre telephone" -ForegroundColor White
    }
} else {
    Write-Host ""
    Write-Host "ERREUR: Construction de l'APK echouee" -ForegroundColor Red
    Write-Host "Essayez de nettoyer le cache: .\clean_gradle_and_build.ps1" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deploiement termine" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
