# Guide pour Tester l'APK

## 📦 Fichier APK disponible

L'APK de debug est disponible ici :
```
build\app\outputs\flutter-apk\app-debug.apk
```

## 🚀 Options pour Tester l'APK

### Option 1 : Via un Appareil Android Physique (Recommandé)

1. **Activer le débogage USB sur votre téléphone :**
   - Allez dans Paramètres > À propos du téléphone
   - Tapez 7 fois sur "Numéro de build" pour activer les options développeur
   - Retournez aux Paramètres > Options pour les développeurs
   - Activez "Débogage USB"

2. **Connecter votre téléphone via USB**

3. **Installer l'APK :**
   ```powershell
   .\install_apk.ps1
   ```
   
   Ou manuellement avec adb :
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```

### Option 2 : Via l'Émulateur Android (Android Studio)

1. **Ouvrir Android Studio**

2. **Lancer l'AVD Manager :**
   - Tools > Device Manager
   - Ou cliquez sur l'icône d'émulateur dans la barre d'outils

3. **Démarrer un émulateur :**
   - Cliquez sur le bouton Play (▶) à côté d'un appareil virtuel
   - Attendez que l'émulateur démarre complètement (~30-60 secondes)

4. **Installer l'APK :**
   ```powershell
   .\install_apk.ps1
   ```
   
   Ou via Flutter :
   ```powershell
   flutter install
   ```

### Option 3 : Transfert Manuel de l'APK

1. **Transférer l'APK sur votre téléphone :**
   - Copiez `build\app\outputs\flutter-apk\app-debug.apk` sur votre téléphone
   - Via USB, email, ou cloud (Google Drive, etc.)

2. **Installer depuis le téléphone :**
   - Ouvrez le gestionnaire de fichiers
   - Trouvez l'APK
   - Tapez dessus pour installer
   - Autorisez l'installation depuis des sources inconnues si demandé

## 🧪 Tester la Recherche Firebase

Une fois l'APK installé et l'app lancée :

1. **Vérifier la connexion Firebase :**
   - L'app doit se connecter automatiquement à Firebase
   - L'authentification anonyme se fait au démarrage

2. **Effectuer une recherche :**
   - Cliquez sur "Recherche Simple" ou "Recherche Avancée"
   - Remplissez les critères (température, localisation, dates)
   - Cliquez sur "Rechercher"

3. **Vérifier l'appel Firebase :**
   - La recherche doit appeler la Cloud Function `searchDestinations`
   - Les résultats doivent s'afficher avec les destinations trouvées
   - Vérifiez les logs dans la console si besoin

## 🔍 Vérifications à Faire

- [ ] L'app démarre sans erreur
- [ ] La connexion Firebase fonctionne (auth anonyme)
- [ ] La recherche appelle la Cloud Function `searchDestinations`
- [ ] Les résultats s'affichent correctement
- [ ] Les informations météo sont présentes
- [ ] La carte interactive fonctionne
- [ ] Les favoris fonctionnent

## 🛠️ Dépannage

### L'app ne démarre pas
```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

### L'émulateur ne démarre pas
- Vérifiez qu'Android Studio est installé
- Vérifiez les licences : `flutter doctor --android-licenses`
- Essayez de redémarrer l'émulateur depuis Android Studio

### Erreur Firebase
- Vérifiez que `google-services.json` est présent dans `android/app/`
- Vérifiez que Firebase est bien configuré dans le projet
- Consultez les logs : `flutter run` pour voir les erreurs détaillées

### ADB non trouvé
- Installez Android SDK Platform Tools
- Ou ajoutez `C:\Users\<user>\AppData\Local\Android\Sdk\platform-tools` au PATH
- Ou utilisez Android Studio pour installer l'APK via l'interface

## 📝 Commandes Utiles

```powershell
# Vérifier les appareils connectés
flutter devices

# Lister les émulateurs
flutter emulators

# Lancer un émulateur
flutter emulators --launch <emulator_id>

# Construire l'APK debug
flutter build apk --debug

# Construire l'APK release
flutter build apk --release

# Installer l'APK (si appareil connecté)
flutter install

# Lancer l'app directement
flutter run
```
