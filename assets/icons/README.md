# Icônes de l'application

## Comment ajouter votre icône

1. **Préparez votre icône source** :
   - Format recommandé : PNG avec fond transparent
   - Taille recommandée : 1024x1024 pixels (minimum 512x512)
   - Nom du fichier : `app_icon.png`

2. **Icône adaptative (optionnelle mais recommandée)** :
   - Créez une version adaptative pour Android avec un fond séparé
   - `app_icon_foreground.png` : l'icône elle-même (recommandé : 1024x1024 px)
   - Le fond sera généré automatiquement avec la couleur configurée dans `pubspec.yaml`

3. **Placez les fichiers** :
   - `app_icon.png` → `assets/icons/app_icon.png`
   - `app_icon_foreground.png` → `assets/icons/app_icon_foreground.png` (optionnel)

4. **Générez les icônes** :
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

Les icônes seront automatiquement générées dans tous les formats et tailles nécessaires pour Android.
