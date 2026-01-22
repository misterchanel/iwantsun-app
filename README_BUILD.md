# Guide de génération de l'APK

## Problème de cache Gradle corrompu

Si vous rencontrez des erreurs de cache Gradle corrompu lors de la génération de l'APK, suivez ces étapes :

## Solution rapide

1. **Redémarrez votre ordinateur** (recommandé pour libérer tous les verrous de fichiers)

2. **Après redémarrage**, ouvrez PowerShell dans le dossier du projet et exécutez :
   ```powershell
   .\clean_gradle_and_build.ps1
   ```

   Ou si PowerShell bloque l'exécution, utilisez :
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\clean_gradle_and_build.ps1
   ```

## Solution manuelle

Si le script ne fonctionne pas, suivez ces étapes manuellement :

### 1. Arrêter les processus
```powershell
Get-Process | Where-Object {$_.ProcessName -like "*java*" -or $_.ProcessName -like "*gradle*"} | Stop-Process -Force
```

### 2. Supprimer le cache Gradle
```powershell
Remove-Item -Path "$env:USERPROFILE\.gradle" -Recurse -Force
```

### 3. Nettoyer le projet
```powershell
flutter clean
```

### 4. Générer l'APK
```powershell
flutter pub get
flutter build apk --release
```

## Fichier APK généré

Une fois la génération réussie, l'APK se trouve dans :
```
build\app\outputs\flutter-apk\app-release.apk
```

## Icônes

Les icônes ont été configurées et générées. Pour les modifier :

1. Remplacez le fichier `assets/icons/app_icon.png` par votre nouvelle icône
2. Exécutez : `flutter pub run flutter_launcher_icons`
3. Régénérez l'APK

## Dépannage

### Erreur "Espace disque insuffisant"
- Libérez de l'espace sur le disque système
- Supprimez les anciennes versions de Gradle dans `C:\Users\<user>\.gradle\wrapper\dists`

### Erreur "Timeout waiting for exclusive access"
- Redémarrez l'ordinateur
- Fermez Android Studio s'il est ouvert
- Vérifiez qu'aucun processus Java/Gradle n'est en cours

### Erreur "CorruptedCacheException"
- Supprimez complètement `C:\Users\<user>\.gradle`
- Redémarrez l'ordinateur
- Relancez le script de nettoyage
