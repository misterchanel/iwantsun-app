# 📋 Guide de Récupération des Logs pour Analyse

## 🔥 Logs Firebase Functions (Serveur)

### Option 1 : Via Firebase Console (Recommandé)
1. Allez sur : https://console.firebase.google.com/project/iwantsun-b6b46/functions/logs
2. Filtrez par fonction : `searchDestinations`
3. Sélectionnez les dernières 50-100 entrées
4. Copiez les logs et collez-les dans un fichier texte

### Option 2 : Via Firebase CLI
```powershell
cd functions
firebase functions:log --limit 100
```

## 📱 Logs Android (Téléphone)

### Option 1 : Via Flutter (Si l'app est en cours d'exécution)
```powershell
flutter logs
```
Lancez cette commande dans un terminal pendant que vous testez l'application.

### Option 2 : Via ADB (Si le téléphone est connecté)
```powershell
adb logcat -d | Select-String -Pattern "Firebase|searchDestinations|IWantsun|ERROR|Exception"
```

### Option 3 : Depuis l'application
Si vous avez activé le logging dans `.env` (`ENABLE_LOGGING=true`), les logs apparaissent dans la console Flutter.

## 📊 Informations à Noter

Lorsque vous récupérez les logs, notez aussi :
- **Heure de l'erreur** : Quand avez-vous lancé la recherche ?
- **Paramètres de recherche** : Température, rayon, dates, conditions météo
- **Message d'erreur affiché** : Quel message voyez-vous sur l'écran ?
- **Comportement** : L'app crash-t-elle ou affiche-t-elle juste une erreur ?

## 🔍 Ce que je vais analyser

Une fois que vous m'avez fourni les logs, je vais :
1. ✅ Identifier l'erreur exacte (code, message, stack trace)
2. ✅ Localiser où l'erreur se produit (client ou serveur)
3. ✅ Analyser les logs Firebase pour voir si la Cloud Function a échoué
4. ✅ Vérifier les logs Android pour voir les erreurs côté IHM
5. ✅ Proposer des solutions correctives

---

**💡 Astuce** : Si vous ne pouvez pas récupérer les logs, décrivez simplement :
- Le message d'erreur exact que vous voyez
- À quel moment l'erreur se produit (pendant la recherche, au démarrage, etc.)
- Les paramètres de recherche que vous avez utilisés
