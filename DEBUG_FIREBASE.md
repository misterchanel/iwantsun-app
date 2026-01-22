# 🔍 Guide de Dépannage - Recherche Firebase

## Problème : La recherche ne fonctionne pas après installation de l'APK

Ce guide vous aidera à diagnostiquer et résoudre les problèmes liés à la recherche Firebase.

## ✅ Checklist de Vérification

### 1. Configuration Firebase côté Client

#### Vérifier `google-services.json`
- Le fichier doit être présent dans `android/app/google-services.json`
- Il doit être configuré pour votre projet Firebase
- **Action** : Vérifiez que le fichier existe et n'est pas vide

#### Vérifier `firebase_options.dart`
- Le fichier doit être présent dans `lib/firebase_options.dart`
- Il doit contenir la configuration Android
- **Action** : Vérifiez que le fichier contient les clés API Firebase

### 2. Cloud Function Firebase

#### Vérifier que la Cloud Function est déployée
- La fonction `searchDestinations` doit être déployée sur Firebase
- **Action** : Vérifiez dans Firebase Console > Functions

#### Vérifier la région
- La fonction est configurée pour `europe-west1`
- **Action** : Vérifiez que votre Cloud Function est dans cette région

### 3. Permissions et Configuration Android

#### Permissions Internet
- ✅ Permission `INTERNET` présente dans `AndroidManifest.xml`

#### Configuration ProGuard (si APK release)
- Si vous utilisez un APK release, vérifiez les règles ProGuard

### 4. Authentification Firebase

#### Authentification anonyme
- L'app doit s'authentifier anonymement au démarrage
- **Vérification** : Regardez les logs au démarrage de l'app

## 🛠️ Diagnostic par Étapes

### Étape 1 : Vérifier les Fichiers de Configuration

```powershell
# Vérifier google-services.json
Test-Path "android\app\google-services.json"

# Vérifier firebase_options.dart
Test-Path "lib\firebase_options.dart"
```

### Étape 2 : Vérifier les Logs

Pour voir les erreurs détaillées :

**Option A : Via `flutter run` (si possible)**
```powershell
flutter run
# Les logs apparaîtront dans la console
```

**Option B : Via Logcat (si appareil connecté)**
```powershell
adb logcat | Select-String "Firebase|searchDestinations|IWantsun"
```

**Option C : Dans l'app**
- Activez les logs dans `.env` : `ENABLE_LOGGING=true`
- Les erreurs apparaîtront dans la console si vous utilisez `flutter run`

### Étape 3 : Vérifier la Cloud Function

1. **Aller dans Firebase Console**
   - https://console.firebase.google.com/
   - Sélectionnez votre projet
   - Allez dans "Functions"

2. **Vérifier que `searchDestinations` existe**
   - La fonction doit être déployée
   - Vérifiez les logs de la fonction pour voir les erreurs

3. **Tester la fonction manuellement**
   - Dans Firebase Console > Functions
   - Cliquez sur `searchDestinations`
   - Testez avec des données d'exemple

### Étape 4 : Vérifier la Connexion Internet

- L'app vérifie automatiquement la connexion
- Si pas de connexion, un message d'erreur apparaît
- **Vérification** : Testez avec WiFi et données mobiles

## 🐛 Problèmes Courants

### Erreur : "Function not found" ou "Permission denied"

**Cause** : La Cloud Function n'est pas déployée ou la configuration Firebase est incorrecte

**Solution** :
1. Vérifiez que la Cloud Function est déployée :
   ```bash
   cd functions
   firebase deploy --only functions
   ```

2. Vérifiez `google-services.json` correspond à votre projet Firebase

### Erreur : "Network error" ou "Connection timeout"

**Cause** : Problème de connexion Internet ou timeout

**Solution** :
- Vérifiez votre connexion Internet
- Essayez avec un autre réseau (WiFi vs données mobiles)
- Vérifiez les pare-feu ou restrictions réseau

### Erreur : "Unauthenticated" ou "Auth error"

**Cause** : Problème d'authentification Firebase anonyme

**Solution** :
1. Vérifiez que l'authentification anonyme est activée dans Firebase Console
   - Firebase Console > Authentication > Sign-in method
   - Activez "Anonymous"

2. Vérifiez les logs au démarrage de l'app pour voir si l'auth réussit

### Erreur : Pas d'erreur visible, mais pas de résultats

**Cause** : La fonction s'exécute mais retourne une erreur silencieuse

**Solution** :
1. Vérifiez les logs de la Cloud Function dans Firebase Console
2. Vérifiez les logs de l'app (si `ENABLE_LOGGING=true`)
3. Testez avec des paramètres différents (dates valides, localisation correcte)

### L'app crash au démarrage

**Cause** : Configuration Firebase manquante ou incorrecte

**Solution** :
1. Vérifiez que `firebase_options.dart` existe et est correct
2. Vérifiez que `google-services.json` est présent dans `android/app/`
3. Reconstruisez l'APK :
   ```powershell
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

## 📋 Vérification Rapide

Exécutez ces commandes pour un diagnostic rapide :

```powershell
# 1. Vérifier les fichiers Firebase
Write-Host "1. Fichiers Firebase:" -ForegroundColor Cyan
Write-Host "   google-services.json: $(if (Test-Path 'android\app\google-services.json') { '✅ Présent' } else { '❌ Manquant' })"
Write-Host "   firebase_options.dart: $(if (Test-Path 'lib\firebase_options.dart') { '✅ Présent' } else { '❌ Manquant' })"

# 2. Vérifier les permissions
Write-Host "`n2. Permissions Android:" -ForegroundColor Cyan
$manifest = Get-Content "android\app\src\main\AndroidManifest.xml" -Raw
if ($manifest -match 'android.permission.INTERNET') {
    Write-Host "   INTERNET: ✅"
} else {
    Write-Host "   INTERNET: ❌"
}

# 3. Vérifier la configuration
Write-Host "`n3. Configuration:" -ForegroundColor Cyan
if (Test-Path '.env') {
    Write-Host "   .env: ✅ Présent"
} else {
    Write-Host "   .env: ⚠️  Optionnel (mais recommandé)"
}
```

## 🔧 Actions Correctives

### Si `google-services.json` est manquant :

1. **Téléchargez depuis Firebase Console** :
   - Allez dans Firebase Console > Project Settings
   - Onglet "Your apps"
   - Cliquez sur votre app Android
   - Téléchargez `google-services.json`
   - Placez-le dans `android/app/`

2. **Ou régénérez avec FlutterFire CLI** :
   ```bash
   flutterfire configure
   ```

### Si `firebase_options.dart` est manquant ou incorrect :

```bash
# Installer FlutterFire CLI (si pas déjà fait)
dart pub global activate flutterfire_cli

# Configurer Firebase pour Flutter
flutterfire configure
```

### Si la Cloud Function n'est pas déployée :

```bash
cd functions
npm install
firebase deploy --only functions:searchDestinations
```

## 📱 Tester avec Logs

Pour voir les logs en temps réel :

1. **Connectez votre appareil ou émulateur**
2. **Lancez l'app avec logs** :
   ```powershell
   flutter run
   ```

3. **Ou si l'APK est déjà installé, utilisez logcat** :
   ```powershell
   adb logcat | Select-String "Firebase|IWantsun|searchDestinations"
   ```

## 💡 Conseils

- **Toujours vérifier les logs** : Les erreurs Firebase sont généralement bien détaillées dans les logs
- **Tester étape par étape** : Vérifiez d'abord que Firebase s'initialise, puis testez l'auth, puis la Cloud Function
- **Vérifier Firebase Console** : Les logs de la Cloud Function donnent beaucoup d'informations
- **Tester en debug d'abord** : L'APK debug contient plus d'informations d'erreur

## 📞 Besoin d'Aide ?

Si le problème persiste :
1. Notez le message d'erreur exact
2. Vérifiez les logs Firebase Console
3. Vérifiez les logs de l'app (si disponibles)
4. Vérifiez que tous les fichiers de configuration sont présents
