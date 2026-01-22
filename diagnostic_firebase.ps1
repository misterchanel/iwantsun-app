# Script de diagnostic Firebase
# Usage: .\diagnostic_firebase.ps1

Write-Host "🔍 Diagnostic Firebase - IWantSun" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier les fichiers Firebase
Write-Host "1. Vérification des fichiers de configuration :" -ForegroundColor Yellow
Write-Host ""

$googleServices = Test-Path "android\app\google-services.json"
$firebaseOptions = Test-Path "lib\firebase_options.dart"

if ($googleServices) {
    $gsSize = (Get-Item "android\app\google-services.json").Length
    Write-Host "   [OK] google-services.json : Present ($gsSize bytes)" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] google-services.json : MANQUANT" -ForegroundColor Red
    Write-Host "      → Téléchargez-le depuis Firebase Console > Project Settings" -ForegroundColor Yellow
}

if ($firebaseOptions) {
    Write-Host "   ✅ firebase_options.dart : Présent" -ForegroundColor Green
} else {
    Write-Host "   ❌ firebase_options.dart : MANQUANT" -ForegroundColor Red
    Write-Host "      → Exécutez : flutterfire configure" -ForegroundColor Yellow
}

Write-Host ""

# 2. Vérifier les permissions Android
Write-Host "2. Vérification des permissions Android :" -ForegroundColor Yellow
Write-Host ""

$manifestPath = "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw
    
    if ($manifest -match 'android\.permission\.INTERNET') {
        Write-Host "   ✅ Permission INTERNET : Présente" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Permission INTERNET : MANQUANTE" -ForegroundColor Red
    }
    
    if ($manifest -match 'android\.permission\.ACCESS_NETWORK_STATE') {
        Write-Host "   ✅ Permission ACCESS_NETWORK_STATE : Présente" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Permission ACCESS_NETWORK_STATE : Optionnelle" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ AndroidManifest.xml introuvable" -ForegroundColor Red
}

Write-Host ""

# 3. Vérifier la configuration .env
Write-Host "3. Vérification de la configuration :" -ForegroundColor Yellow
Write-Host ""

if (Test-Path ".env") {
    Write-Host "   ✅ Fichier .env : Présent" -ForegroundColor Green
    $envContent = Get-Content ".env" -Raw
    if ($envContent -match 'ENABLE_LOGGING=true') {
        Write-Host "   ✅ Logging activé : Oui" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Logging activé : Non (recommandé pour le debug)" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  Fichier .env : Optionnel (mais recommandé)" -ForegroundColor Yellow
}

Write-Host ""

# 4. Vérifier les Cloud Functions
Write-Host "4. Vérification des Cloud Functions :" -ForegroundColor Yellow
Write-Host ""

$functionsPath = "functions\src\index.ts"
if (Test-Path $functionsPath) {
    Write-Host "   ✅ Code de la fonction : Présent" -ForegroundColor Green
    $functionsCode = Get-Content $functionsPath -Raw
    if ($functionsCode -match 'searchDestinations') {
        Write-Host "   ✅ Fonction searchDestinations : Définie" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Fonction searchDestinations : NON DÉFINIE" -ForegroundColor Red
    }
} else {
    Write-Host "   ⚠️  Dossier functions : Non trouvé" -ForegroundColor Yellow
}

Write-Host ""

# 5. Résumé
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Résumé :" -ForegroundColor Cyan
Write-Host ""

$issues = 0
if (-not $googleServices) { $issues++ }
if (-not $firebaseOptions) { $issues++ }

if ($issues -eq 0) {
    Write-Host "✅ Configuration Firebase : OK" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Prochaines étapes :" -ForegroundColor Yellow
    Write-Host "   1. Vérifiez que la Cloud Function est déployée :" -ForegroundColor White
    Write-Host "      cd functions" -ForegroundColor Gray
    Write-Host "      firebase deploy --only functions:searchDestinations" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2. Vérifiez les logs dans Firebase Console :" -ForegroundColor White
    Write-Host "      https://console.firebase.google.com/project/iwantsun-b6b46/functions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   3. Testez avec logs pour voir les erreurs :" -ForegroundColor White
    Write-Host "      flutter run" -ForegroundColor Gray
    Write-Host "      (ou) adb logcat | Select-String 'Firebase|searchDestinations'" -ForegroundColor Gray
} else {
    Write-Host "❌ $issues problème(s) détecté(s)" -ForegroundColor Red
    Write-Host ""
    Write-Host "📋 Actions à effectuer :" -ForegroundColor Yellow
    
    if (-not $googleServices) {
        Write-Host "   - Téléchargez google-services.json depuis Firebase Console" -ForegroundColor White
        Write-Host "     Placez-le dans android\app\" -ForegroundColor Gray
    }
    
    if (-not $firebaseOptions) {
        Write-Host "   - Exécutez : flutterfire configure" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "📖 Pour plus d'informations, consultez : DEBUG_FIREBASE.md" -ForegroundColor Cyan

