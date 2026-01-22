# Guide d'Accessibilité IWantSun - WCAG 2.1 Niveau AA

## 🎯 Objectif

Assurer que l'application **IWantSun** est accessible à tous les utilisateurs, y compris ceux ayant des handicaps visuels, auditifs, moteurs ou cognitifs.

## ✅ Conformité WCAG 2.1 Niveau AA

### 1. PERCEIVABLE (Perceptible)

#### 1.1 Alternatives textuelles
- **Règle**: Fournir des alternatives textuelles pour tout contenu non textuel
- **Implementation**:
  ```dart
  // Bon exemple - Image avec alt text
  AccessibleImage(
    altText: "Carte météo montrant un soleil éclatant",
    child: Image.asset('assets/weather_map.png'),
  )

  // Images décoratives
  AccessibleImage(
    altText: "",
    isDecorative: true,
    child: Image.asset('assets/background.png'),
  )
  ```

#### 1.2 Médias temporels
- Fournir des transcriptions pour le contenu audio
- Sous-titres pour les vidéos

#### 1.3 Adaptable
- **Règle**: Le contenu peut être présenté de différentes manières sans perte d'information
- **Implementation**:
  ```dart
  // Structure sémantique claire
  AccessibleHeader(
    text: "Résultats de recherche",
    level: 1,
    child: Text("Résultats de recherche"),
  )
  ```

#### 1.4 Distinguable

##### Contraste des couleurs (WCAG AA)
- **Texte normal**: Ratio minimum de **4.5:1**
- **Texte large** (18pt+ ou 14pt+ gras): Ratio minimum de **3:1**
- **Éléments d'interface**: Ratio minimum de **3:1**

**Vérification automatique**:
```dart
// Vérifier le contraste
final hasContrast = AccessibilityService.hasEnoughContrast(
  AppColors.textDark,
  AppColors.white,
  isLargeText: false,
);

// Ajuster automatiquement si nécessaire
final adjustedColor = AccessibilityService.adjustColorForContrast(
  AppColors.mediumGray,
  AppColors.white,
);
```

**État des couleurs actuelles**:
| Combinaison | Ratio | Statut | Usage |
|-------------|-------|--------|-------|
| darkGray / white | 12.6:1 | ✅ Excellent | Texte principal |
| white / primaryOrange | 3.4:1 | ✅ Conforme (texte large) | Boutons |
| mediumGray / white | 3.1:1 | ⚠️ Texte large uniquement | Labels secondaires |
| primaryOrange / white | 3.3:1 | ✅ Conforme (texte large) | Liens |

##### Redimensionnement du texte
- Supporter le zoom jusqu'à 200% sans perte de fonctionnalité
- Utiliser des unités relatives (sp, rem) au lieu de px fixes
- Respecter les préférences système de taille de police

```dart
// Bon exemple - Taille responsive
Text(
  'Titre',
  style: Theme.of(context).textTheme.headlineMedium, // Respecte les préférences
)

// Mauvais exemple
Text(
  'Titre',
  style: TextStyle(fontSize: 24), // Taille fixe
)
```

##### Utilisation de la couleur
- **Règle**: Ne pas utiliser UNIQUEMENT la couleur pour transmettre l'information
- **Implementation**:
  ```dart
  // Bon exemple - Icône + Couleur
  Row(
    children: [
      Icon(Icons.error, color: AppColors.errorRed),
      Text('Erreur de connexion', style: TextStyle(color: AppColors.errorRed)),
    ],
  )

  // Mauvais exemple - Couleur seule
  Text('Erreur', style: TextStyle(color: Colors.red)) // ❌
  ```

---

### 2. OPERABLE (Utilisable)

#### 2.1 Accessible au clavier
- **Règle**: Toutes les fonctionnalités doivent être accessibles au clavier
- **Implementation**:
  ```dart
  // Support du focus
  Focus(
    child: InkWell(
      onTap: () {},
      focusColor: AppColors.primaryOrange.withOpacity(0.2),
      child: ListTile(...),
    ),
  )
  ```

#### 2.2 Délai suffisant
- Donner aux utilisateurs suffisamment de temps pour lire et utiliser le contenu
- Éviter les timeouts automatiques sans avertissement
- Permettre de prolonger les délais

```dart
// Bon exemple - Timer visible avec option d'extension
if (widget.failure is RateLimitFailure && _secondsRemaining > 0) {
  Text('Réessayez dans ${_formatTime(_secondsRemaining)}'),
  TextButton(
    onPressed: _extendTimer,
    child: Text('Prolonger'),
  ),
}
```

#### 2.3 Crises et réactions physiques
- Éviter les animations clignotantes (> 3 fois par seconde)
- Respecter `prefers-reduced-motion`

```dart
// Respecter les préférences de mouvement
final reduceMotion = MediaQuery.of(context).disableAnimations;
AnimationController(
  duration: reduceMotion
    ? Duration.zero
    : Duration(milliseconds: 300),
  vsync: this,
);
```

#### 2.4 Navigable

##### Titre de page
```dart
AppBar(
  title: AccessibleHeader(
    text: "Recherche de destinations",
    level: 1,
    child: Text("Recherche de destinations"),
  ),
)
```

##### Focus visible
```dart
// Focus visible avec bordure
Container(
  decoration: BoxDecoration(
    border: focusNode.hasFocus
      ? Border.all(color: AppColors.primaryOrange, width: 2)
      : null,
  ),
  child: TextField(...),
)
```

##### Ordre de tabulation logique
- Structurer les widgets dans un ordre logique de haut en bas, gauche à droite
- Utiliser `FocusTraversalGroup` si nécessaire

---

### 3. UNDERSTANDABLE (Compréhensible)

#### 3.1 Lisible

##### Langue de la page
```dart
MaterialApp(
  locale: Locale('fr', 'FR'),
  localizationsDelegates: [...],
)
```

##### Mots inhabituels
- Expliquer le jargon technique
- Fournir des glossaires pour les termes spécialisés

#### 3.2 Prévisible

##### Au focus / Au survol
- Ne pas changer le contexte automatiquement au focus
- Les changements doivent être déclenchés par l'utilisateur

##### Navigation cohérente
- Même position pour les éléments de navigation sur toutes les pages
- AppBar identique partout

#### 3.3 Assistance à la saisie

##### Identification des erreurs
```dart
// Bon exemple - Message d'erreur clair
TextFormField(
  decoration: InputDecoration(
    errorText: 'L\'adresse email doit contenir un @',
    errorStyle: TextStyle(
      color: AppColors.errorRed,
      fontSize: 13,
    ),
  ),
  validator: (value) {
    if (!value.contains('@')) {
      return 'L\'adresse email doit contenir un @';
    }
    return null;
  },
)
```

##### Étiquettes ou instructions
```dart
AccessibleTextField(
  label: "Adresse email",
  hint: "Entrez votre adresse email pour recevoir les résultats",
  errorText: errors['email'],
  child: TextFormField(...),
)
```

---

### 4. ROBUST (Robuste)

#### 4.1 Compatible

##### Noms, rôles et valeurs
- Utiliser les widgets Semantics correctement
- Fournir des labels explicites

```dart
// Bouton accessible
AccessibleButton(
  label: "Rechercher des destinations",
  hint: "Lance une recherche de destinations selon vos critères",
  onPressed: _search,
  child: ElevatedButton(
    onPressed: _search,
    child: Text('Rechercher'),
  ),
)
```

---

## 🛠️ Outils de développement

### 1. Service d'accessibilité

```dart
import 'package:iwantsun/core/services/accessibility_service.dart';

// Vérifier le contraste
AccessibilityService.hasEnoughContrast(color1, color2);

// Ajuster pour le contraste
AccessibilityService.adjustColorForContrast(color1, color2);

// Calculer le ratio
AccessibilityService.calculateContrastRatio(color1, color2);
```

### 2. Widgets accessibles préconçus

```dart
// Bouton
AccessibleButton(
  label: "Action",
  onPressed: () {},
  child: ElevatedButton(...),
)

// Champ de texte
AccessibleTextField(
  label: "Email",
  hint: "Entrez votre email",
  child: TextField(...),
)

// Image
AccessibleImage(
  altText: "Description de l'image",
  child: Image.asset(...),
)

// En-tête
AccessibleHeader(
  text: "Titre de section",
  level: 2,
  child: Text(...),
)

// Lien
AccessibleLink(
  label: "En savoir plus",
  hint: "Ouvre une page avec plus d'informations",
  onTap: () {},
  child: TextButton(...),
)
```

### 3. Vérification des contrastes

```dart
import 'package:iwantsun/core/theme/accessibility_colors.dart';

// Générer un rapport de conformité
final report = AccessibilityColors.generateAccessibilityReport();
print(report);

// Vérifier toutes les combinaisons
final checks = AccessibilityColors.verifyAllContrasts();
```

### 4. Annonces au lecteur d'écran

```dart
// Annoncer un message important
ScreenReaderAnnouncer.announce(
  context,
  "Recherche terminée. 12 destinations trouvées.",
);
```

---

## ✅ Checklist de conformité

### Pour chaque nouvel écran

- [ ] Tous les éléments interactifs ont un label Semantics
- [ ] Les images ont un texte alternatif (ou sont marquées décoratives)
- [ ] Les en-têtes sont marqués comme headers avec niveau approprié
- [ ] Tous les contrastes respectent le ratio 4.5:1 (ou 3:1 pour texte large)
- [ ] La navigation au clavier fonctionne dans un ordre logique
- [ ] Les états de focus sont visuellement visibles
- [ ] Les erreurs de formulaire sont annoncées clairement
- [ ] Aucune information n'est transmise uniquement par la couleur
- [ ] Le zoom texte jusqu'à 200% ne casse pas la mise en page
- [ ] Les animations respectent `prefers-reduced-motion`
- [ ] Testé avec VoiceOver (iOS) ou TalkBack (Android)
- [ ] Testé avec navigation au clavier (Windows/Web)

### Pour chaque nouveau composant

- [ ] Wrapper avec Semantics approprié
- [ ] Label descriptif fourni
- [ ] Hint d'utilisation si nécessaire
- [ ] Role correct (button, link, textField, etc.)
- [ ] États enabled/disabled gérés
- [ ] onTap fourni si interactif
- [ ] Contraste vérifié avec AccessibilityService

---

## 🧪 Tests d'accessibilité

### Tests manuels requis

1. **Lecteur d'écran**
   - iOS: Activer VoiceOver (Settings > Accessibility > VoiceOver)
   - Android: Activer TalkBack (Settings > Accessibility > TalkBack)
   - Naviguer dans toute l'application sans regarder l'écran

2. **Navigation au clavier** (Windows/Web)
   - Tab pour naviguer entre les éléments
   - Enter/Space pour activer
   - Flèches pour naviguer dans les listes

3. **Zoom texte**
   - Augmenter la taille du texte système à 200%
   - Vérifier que tout reste lisible et fonctionnel

4. **Contraste**
   - Utiliser un outil comme [Contrast Checker](https://webaim.org/resources/contrastchecker/)
   - Vérifier les captures d'écran

5. **Daltonisme**
   - Tester avec les filtres de daltonisme du système
   - Vérifier que l'information reste compréhensible

### Tests automatisés

```dart
// Test de contraste
testWidgets('Button has enough contrast', (tester) async {
  await tester.pumpWidget(MyApp());

  final hasContrast = AccessibilityService.hasEnoughContrast(
    AppColors.white,
    AppColors.primaryOrange,
    isLargeText: true,
  );

  expect(hasContrast, true);
});
```

---

## 📚 Ressources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Accessible Colors](https://accessible-colors.com/)

---

## 🚀 Roadmap d'accessibilité

### ✅ Phase 1 - Complétée
- Infrastructure d'accessibilité
- Service de vérification des contrastes
- Widgets accessibles réutilisables
- Guide et documentation

### 🔄 Phase 2 - En cours
- Ajout de Semantics sur tous les écrans
- Tests avec lecteurs d'écran
- Corrections des contrastes insuffisants

### 📋 Phase 3 - À venir
- Tests utilisateurs avec personnes en situation de handicap
- Support complet de la navigation au clavier
- Modes adaptatifs (dyslexie, daltonisme)
- Certifications WCAG officielles

---

**Note**: L'accessibilité est un processus continu. Ce guide doit être consulté pour chaque nouveau développement et mis à jour régulièrement.
