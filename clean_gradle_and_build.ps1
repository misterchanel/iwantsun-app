# Script PowerShell pour nettoyer Gradle et generer l'APK
# Utilisation : Executez ce script dans PowerShell apres avoir redemarre votre ordinateur

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Nettoyage Gradle et generation APK" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Etape 1 : Arreter tous les processus Java/Gradle qui pourraient bloquer
Write-Host "[1/5] Arret des processus Java/Gradle..." -ForegroundColor Yellow
try {
    Get-Process | Where-Object {$_.ProcessName -like "*java*" -or $_.ProcessName -like "*gradle*"} | ForEach-Object {
        Write-Host "   Arret du processus: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Gray
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 3
    Write-Host "   OK - Processus arretes" -ForegroundColor Green
} catch {
    Write-Host "   INFO - Aucun processus a arreter" -ForegroundColor Gray
}
Write-Host ""

# Etape 2 : Supprimer le cache Gradle utilisateur (methode forcee)
Write-Host "[2/5] Suppression du cache Gradle utilisateur..." -ForegroundColor Yellow
$gradleCachePath = "$env:USERPROFILE\.gradle"
if (Test-Path $gradleCachePath) {
    Write-Host "   Suppression en cours..." -ForegroundColor Gray
    
    # Methode 1 : Suppression normale
    try {
        Remove-Item -Path $gradleCachePath -Recurse -Force -ErrorAction Stop
        Write-Host "   OK - Cache Gradle supprime" -ForegroundColor Green
    } catch {
        Write-Host "   Tentative de suppression forcee..." -ForegroundColor Yellow
        
        # Methode 2 : Supprimer dossier par dossier avec retry
        try {
            $items = Get-ChildItem -Path $gradleCachePath -Recurse -Force -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                try {
                    Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction Stop
                } catch {
                    # Ignorer les fichiers verrouilles
                }
            }
            # Supprimer les dossiers vides
            Remove-Item -Path $gradleCachePath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   OK - Cache Gradle supprime (avec retry)" -ForegroundColor Green
        } catch {
            Write-Host "   ATTENTION - Certains fichiers sont peut-etre verrouilles" -ForegroundColor Yellow
            Write-Host "   Essayez de redemarrer votre ordinateur et relancez ce script" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "   INFO - Cache Gradle deja absent" -ForegroundColor Gray
}
Write-Host ""

# Etape 3 : Supprimer les caches Gradle locaux du projet
Write-Host "[3/5] Nettoyage des caches Gradle du projet..." -ForegroundColor Yellow
if (Test-Path "android\.gradle") {
    Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path "android\app\.gradle") {
    Remove-Item -Path "android\app\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "   OK - Caches locaux nettoyes" -ForegroundColor Green
Write-Host ""

# Etape 4 : Nettoyer le projet Flutter
Write-Host "[4/5] Nettoyage du projet Flutter..." -ForegroundColor Yellow
flutter clean
Write-Host "   OK - Projet nettoye" -ForegroundColor Green
Write-Host ""

# Etape 5 : Recuperer les dependances et generer l'APK
Write-Host "[5/5] Generation de l'APK..." -ForegroundColor Yellow
Write-Host ""
flutter pub get
Write-Host ""
flutter build apk --release
Write-Host ""

# Verifier si l'APK a ete genere
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "SUCCES - APK genere avec succes !" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Fichier APK : $apkPath" -ForegroundColor Cyan
    $fileInfo = Get-Item $apkPath
    Write-Host "Taille : $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Les icones ont ete integrees dans l'APK." -ForegroundColor Gray
} else {
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host "ERREUR - Erreur lors de la generation de l'APK" -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Verifiez les erreurs ci-dessus." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Appuyez sur une touche pour fermer..." -ForegroundColor Gray
try {
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
} catch {
    # Ignorer si ReadKey n'est pas disponible
}
