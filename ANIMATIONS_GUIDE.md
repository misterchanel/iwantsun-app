# Guide des Animations et Effets Visuels

## Vue d'ensemble

Ce guide présente toutes les animations et effets visuels ajoutés à l'application IWantSun pour créer une expérience utilisateur professionnelle et fluide.

---

## 📁 Fichiers Créés

### 1. `lib/core/animations/page_transitions.dart`

Transitions de page personnalisées pour une navigation fluide.

#### Classes Disponibles:

- **`FadePageRoute`**: Transition en fondu
- **`SlidePageRoute`**: Glissement depuis un bord de l'écran
- **`ScalePageRoute`**: Effet de zoom
- **`RotationPageRoute`**: Rotation lors de la transition
- **`SlideFadePageRoute`**: Combinaison de slide et fade
- **`ParallaxPageRoute`**: Effet parallax avec deux couches
- **`FlipPageRoute`**: Retournement 3D (horizontal ou vertical)
- **`BlurPageRoute`**: Transition avec effet de flou

#### Extension pour Navigation Rapide:

```dart
// Utilisation simple
context.pushFade(MyScreen());
context.pushSlide(MyScreen(), beginOffset: Offset(1.0, 0.0));
context.pushScale(MyScreen());
context.pushSlideFade(MyScreen());
context.pushParallax(MyScreen());
```

---

### 2. `lib/core/animations/list_animations.dart`

Animations pour listes et grilles avec effets d'entrée échelonnés.

#### Widgets:

##### `AnimatedListItem`
Animation d'entrée pour un élément de liste individuel.

```dart
AnimatedListItem(
  index: index,
  delay: Duration(milliseconds: 100),
  duration: Duration(milliseconds: 500),
  fadeIn: true,
  slideIn: true,
  scaleIn: false,
  child: MyWidget(),
)
```

##### `StaggeredAnimatedList`
Liste avec animations échelonnées automatiques.

```dart
StaggeredAnimatedList(
  children: [
    Card(...),
    Card(...),
    Card(...),
  ],
  itemDelay: Duration(milliseconds: 80),
  itemDuration: Duration(milliseconds: 400),
)
```

##### `StaggeredAnimatedGrid`
Grille avec animations échelonnées.

```dart
StaggeredAnimatedGrid(
  children: gridItems,
  crossAxisCount: 2,
  itemDelay: Duration(milliseconds: 60),
)
```

##### `SlideOutListItem`
Animation de suppression d'élément.

```dart
SlideOutListItem(
  child: MyWidget(),
  onDismissed: () => print('Removed!'),
  direction: Axis.horizontal,
)
```

##### `ExpandAnimation`
Révélation progressive (expand/collapse).

```dart
ExpandAnimation(
  expand: isExpanded,
  child: MyContent(),
  axis: Axis.vertical,
)
```

##### `BounceAnimation`
Effet de rebond pour interactions.

```dart
BounceAnimation(
  child: Icon(Icons.favorite),
  onTap: () => print('Bounced!'),
  scaleFactor: 0.95,
)
```

---

### 3. `lib/core/animations/micro_interactions.dart`

Micro-interactions pour améliorer le feedback utilisateur.

#### Widgets:

##### `PressableButton`
Bouton avec effet de pression et feedback haptique.

```dart
PressableButton(
  onPressed: () => print('Pressed'),
  child: Text('Press me'),
  pressedScale: 0.95,
  enableHaptic: true,
)
```

##### `LiftCard`
Card avec effet d'élévation au tap.

```dart
LiftCard(
  child: MyContent(),
  onTap: () => print('Tapped'),
  liftHeight: 8.0,
)
```

##### `CustomRipple`
Effet de ripple personnalisé.

```dart
CustomRipple(
  child: Container(...),
  onTap: () => print('Ripple!'),
  rippleColor: Colors.blue,
)
```

##### `ShakeAnimation`
Tremblement pour erreurs/validation.

```dart
ShakeAnimation(
  trigger: hasError,
  child: TextField(...),
  offset: 10.0,
  shakes: 3,
)
```

##### `PulseAnimation`
Animation de pulsation.

```dart
PulseAnimation(
  child: Icon(Icons.favorite, color: Colors.red),
  duration: Duration(milliseconds: 1000),
  repeat: true,
)
```

##### `RotateAnimation`
Rotation continue.

```dart
RotateAnimation(
  child: CircularProgressIndicator(),
  duration: Duration(seconds: 2),
  clockwise: true,
)
```

##### `GlimmerAnimation`
Scintillement pour nouveautés.

```dart
GlimmerAnimation(
  child: Text('NEW!'),
  glimmerColor: Colors.gold,
)
```

##### `AnimatedBadge`
Badge animé pour notifications.

```dart
AnimatedBadge(
  count: notificationCount,
  child: Icon(Icons.notifications),
  badgeColor: Colors.red,
)
```

---

### 4. `lib/presentation/widgets/animated_card.dart` (enrichi)

Cards existantes enrichies avec nouveaux types d'animations.

#### Nouveaux Widgets:

##### `GlassCard`
Effet glassmorphism (verre dépoli).

```dart
GlassCard(
  blur: 10.0,
  opacity: 0.2,
  child: MyContent(),
)
```

##### `GradientCard`
Card avec gradient personnalisé.

```dart
GradientCard(
  gradientColors: [Colors.purple, Colors.pink],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  child: MyContent(),
)
```

##### `GlowCard`
Card avec effet de lueur animé.

```dart
GlowCard(
  child: MyContent(),
  glowColor: AppColors.primaryOrange,
  glowIntensity: 10.0,
  animate: true,
)
```

##### `ExpandableCard`
Card expandable avec animation.

```dart
ExpandableCard(
  header: Text('Click to expand'),
  expandedContent: Text('Hidden content'),
  initiallyExpanded: false,
)
```

##### `ParallaxCard`
Card avec image de fond parallax.

```dart
ParallaxCard(
  backgroundImage: Image.network('...'),
  height: 200,
  child: MyOverlayContent(),
)
```

##### `SkeletonCard`
Card skeleton pour loading.

```dart
SkeletonCard(
  height: 100,
  width: double.infinity,
)
```

---

### 5. `lib/core/theme/visual_effects.dart`

Utilitaires pour effets visuels (gradients, ombres, etc.)

#### Ombres (Shadows):

```dart
VisualEffects.softShadow       // Ombre douce
VisualEffects.mediumShadow     // Ombre moyenne
VisualEffects.strongShadow     // Ombre forte
VisualEffects.coloredShadow(Colors.blue, opacity: 0.3)
VisualEffects.innerShadow      // Ombre intérieure
```

#### Gradients:

```dart
VisualEffects.sunsetGradient     // Orange soleil
VisualEffects.skyGradient        // Bleu ciel
VisualEffects.successGradient    // Vert succès
VisualEffects.errorGradient      // Rouge erreur
VisualEffects.coldGradient       // Température froide
VisualEffects.hotGradient        // Température chaude
VisualEffects.perfectGradient    // Température parfaite
VisualEffects.darkOverlay        // Overlay sombre
VisualEffects.lightOverlay       // Overlay clair
```

#### Helpers Température/Score:

```dart
VisualEffects.temperatureGradient(25.0)  // Gradient basé sur température
VisualEffects.temperatureColor(15.0)     // Couleur basée sur température
VisualEffects.scoreGradient(85.0)        // Gradient basé sur score (%)
VisualEffects.scoreColor(70.0)           // Couleur basée sur score (%)
```

#### Border Radius:

```dart
VisualEffects.smallRadius       // 8px
VisualEffects.mediumRadius      // 12px
VisualEffects.largeRadius       // 16px
VisualEffects.xlRadius          // 24px
VisualEffects.circularRadius    // Circulaire
VisualEffects.topRadius         // Haut seulement
VisualEffects.bottomRadius      // Bas seulement
```

#### Décorations Prédéfinies:

```dart
VisualEffects.cardDecoration(
  color: Colors.white,
  boxShadow: VisualEffects.softShadow,
)

VisualEffects.gradientCardDecoration(
  gradient: VisualEffects.sunsetGradient,
)

VisualEffects.glassDecoration(
  color: Colors.white,
)

VisualEffects.badgeDecoration(
  color: AppColors.primaryOrange,
)

VisualEffects.inputDecoration(
  hasFocus: true,
  borderColor: AppColors.primaryBlue,
)
```

#### Extensions Widget:

```dart
myWidget.withShadow(shadow: VisualEffects.mediumShadow)
myWidget.withRadius(radius: VisualEffects.largeRadius)
myWidget.withGradientOverlay(gradient: VisualEffects.darkOverlay)
myWidget.withDecoration(
  decoration: VisualEffects.cardDecoration(),
  padding: EdgeInsets.all(16),
)
```

---

### 6. `lib/core/router/app_router.dart` (mis à jour)

Router avec transitions personnalisées pour chaque route.

```dart
'/' → FadeTransition (écran de bienvenue)
'/onboarding' → SlideTransition (de bas en haut)
'/home' → FadeTransition
'/search/simple' → SlideTransition (de droite à gauche)
'/search/advanced' → SlideTransition (de droite à gauche)
'/search/results' → SlideTransition (de bas en haut)
'/favorites' → ScaleTransition (zoom)
'/settings' → SlideTransition (de droite à gauche)
```

---

## 🎨 Exemples d'Utilisation

### Exemple 1: Liste de résultats animée

```dart
StaggeredAnimatedList(
  children: results.map((result) =>
    LiftCard(
      onTap: () => navigateToDetail(result),
      child: ResultCard(result: result),
    )
  ).toList(),
  itemDelay: Duration(milliseconds: 80),
)
```

### Exemple 2: Card avec température

```dart
GradientCard(
  gradientColors: [
    VisualEffects.temperatureColor(temperature),
    VisualEffects.temperatureColor(temperature).withOpacity(0.7),
  ],
  child: Column(
    children: [
      Text('${temperature}°C'),
      Text(location),
    ],
  ),
)
```

### Exemple 3: Bouton avec animations

```dart
PressableButton(
  onPressed: () => search(),
  enableHaptic: true,
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    decoration: VisualEffects.gradientCardDecoration(
      gradient: VisualEffects.sunsetGradient,
    ),
    child: Text('Rechercher'),
  ),
)
```

### Exemple 4: Card skeleton loading

```dart
if (isLoading)
  Column(
    children: List.generate(5, (index) =>
      SkeletonCard(
        height: 120,
        margin: EdgeInsets.only(bottom: 16),
      )
    ),
  )
else
  // Contenu réel
```

---

## ⚡ Performance

### Optimisations Appliquées:

1. **Réutilisation des AnimationControllers**: Dispose() correctement appelé
2. **Animations conditionnelles**: Pas d'animations si widget.animate == false
3. **Curves optimisées**: Utilisation de courbes Material Design
4. **Minimal rebuilds**: AnimatedBuilder utilisé correctement
5. **Lazy loading**: Animations démarrées uniquement quand nécessaire

### Bonnes Pratiques:

```dart
// ✅ BON: Animation réutilisable
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ❌ MAUVAIS: AnimationController créé dans build()
Widget build(BuildContext context) {
  final controller = AnimationController(...); // Memory leak!
  return ...;
}
```

---

## 🎯 Guide de Sélection

### Quand utiliser quelle animation?

| Contexte | Animation Recommandée |
|----------|----------------------|
| Navigation entre écrans | `SlidePageRoute`, `FadePageRoute` |
| Affichage modal/dialogue | `ScalePageRoute`, `SlideFadePageRoute` |
| Liste de résultats | `StaggeredAnimatedList` |
| Card cliquable | `LiftCard`, `AnimatedCard` |
| Bouton d'action | `PressableButton`, `BounceAnimation` |
| Chargement | `SkeletonCard`, `PulseAnimation` |
| Erreur de validation | `ShakeAnimation` |
| Notification nouvelle | `GlimmerAnimation`, `PulseAnimation` |
| Badge compteur | `AnimatedBadge` |
| Contenu expandable | `ExpandableCard`, `ExpandAnimation` |
| Effet premium | `GlassCard`, `GradientCard`, `GlowCard` |

---

## 📱 Compatibilité

- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

Tous les widgets utilisent uniquement des APIs Flutter standard et sont compatibles avec toutes les plateformes.

---

## 🔧 Configuration

### Durées d'animation (déjà configurées dans `AppAnimations`):

```dart
AppAnimations.ultraFast  // 100ms - Micro-interactions
AppAnimations.veryFast   // 200ms - Feedback rapide
AppAnimations.fast       // 300ms - Transitions standard
AppAnimations.normal     // 400ms - Animations normales
AppAnimations.slow       // 600ms - Animations importantes
AppAnimations.verySlow   // 800ms - Animations complexes
```

### Curves (déjà configurées):

```dart
AppAnimations.standardCurve    // easeInOut
AppAnimations.enterCurve       // easeOut
AppAnimations.exitCurve        // easeIn
AppAnimations.bounceCurve      // elasticOut
AppAnimations.accelerateCurve  // easeInCubic
AppAnimations.decelerateCurve  // easeOutCubic
```

---

## 🚀 Prochaines Améliorations Possibles

1. **Animations basées sur le scroll** (parallax avancé)
2. **Physics-based animations** (spring animations)
3. **Animated graphs** pour statistiques
4. **Rive animations** pour animations complexes
5. **Lottie animations** pour animations vectorielles
6. **Hero animations** avancées entre écrans
7. **Morphing animations** pour transitions de forme

---

## 📚 Ressources

- [Flutter Animations Documentation](https://docs.flutter.dev/development/ui/animations)
- [Material Motion Guidelines](https://material.io/design/motion)
- [Animation Best Practices](https://docs.flutter.dev/development/ui/animations/tutorial)

---

*Guide créé pour IWantSun - Phase 2: Design Visuel et Animations*
