# Guide de Déploiement IWantSun

## 🚀 Déploiement Rapide

### Option 1: Script Automatique (Recommandé)

```powershell
.\deploy.ps1
```

Ce script effectue automatiquement :
1. ✅ Compilation des Firebase Functions
2. ✅ Déploiement sur Firebase (optionnel)
3. ✅ Construction de l'APK Android
4. ✅ Installation sur votre téléphone (optionnel)

### Option 2: Déploiement Manuel

#### 1. Déployer les Firebase Functions

```powershell
# Se connecter à Firebase (première fois uniquement)
npx firebase-tools login

# Compiler les fonctions
cd functions
npm run build
cd ..

# Déployer
npx firebase-tools deploy --only functions
```

#### 2. Construire l'APK Android

**Version Debug (pour tests) :**
```powershell
flutter build apk --debug
```
APK généré : `build\app\outputs\flutter-apk\app-debug.apk`

**Version Release (pour production) :**
```powershell
flutter build apk --release
```
APK généré : `build\app\outputs\flutter-apk\app-release.apk`

#### 3. Installer sur votre téléphone

**Option A: Via USB (débogage activé)**
```powershell
.\install_apk.ps1
```

**Option B: Transfert manuel**
1. Transférez l'APK sur votre téléphone (USB, email, cloud, etc.)
2. Activez "Sources inconnues" dans les paramètres Android
3. Ouvrez le fichier APK sur votre téléphone
4. Suivez les instructions d'installation

## 📋 Prérequis

- ✅ Node.js installé (v22+)
- ✅ Flutter installé (v3.0+)
- ✅ Android SDK configuré
- ✅ Téléphone Android avec débogage USB activé (pour installation automatique)

## 🔧 Dépannage

### Erreur Gradle/Kotlin
```powershell
.\clean_gradle_and_build.ps1
```

### Erreur Firebase CLI
```powershell
npm install -g firebase-tools
# ou
npx firebase-tools --version
```

### Erreur de build Flutter
```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

## 📱 Installation sur Téléphone

### Activer le débogage USB

1. Allez dans **Paramètres** > **À propos du téléphone**
2. Appuyez 7 fois sur **Numéro de build**
3. Retournez dans **Paramètres** > **Options développeur**
4. Activez **Débogage USB**

### Vérifier la connexion

```powershell
adb devices
```

Vous devriez voir votre appareil listé.

## ✅ Vérification du Déploiement

### Firebase Functions
- Console Firebase : https://console.firebase.google.com/project/iwantsun-b6b46/functions
- Vérifiez que les fonctions sont actives

### APK
- Vérifiez que l'APK est généré dans `build\app\outputs\flutter-apk\`
- Taille typique : 30-50 MB

## 🎯 Prochaines Étapes

Après le déploiement :
1. Testez l'application sur votre téléphone
2. Vérifiez que les Firebase Functions répondent correctement
3. Testez une recherche complète
4. Vérifiez les logs Firebase en cas d'erreur

---

*Dernière mise à jour : 2026-01-22*
