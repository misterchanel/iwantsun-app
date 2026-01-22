# Documentation du Calcul du Score Global

**Date** : 2026-01-21  
**Point 24 de l'analyse fonctionnelle**

---

## 📊 Formule du Score Global

Le score global (`overallScore`) est calculé côté Firebase Cloud Function. Cette documentation décrit la formule théorique basée sur l'analyse du code client.

### Formule Générale

```
Score Global = Score Météo × Poids_Météo + Score Activités × Poids_Activités - Pénalité Distance
```

---

## 🌤️ Score Météo (0-100)

Le score météo combine trois composantes :

### Formule
```
Score Météo = (ScoreTempérature × 0.35) + (ScoreCondition × 0.50) + (Stabilité × 0.15)
```

### A. Score de Température (0-100)

**Méthode** : Courbe exponentielle décroissante

```
Écart = |Température_moyenne_réelle - Température_moyenne_souhaitée|
Score = 100 × e^(-Écart / 10.0)
```

**Exemples** :
- 0°C d'écart = 100%
- 5°C d'écart ≈ 60%
- 10°C d'écart ≈ 35%
- 15°C d'écart ≈ 15%
- 25°C d'écart ≈ 0%

**Fichier** : `lib/core/utils/score_calculator.dart` - `_calculateTemperatureScore()`

### B. Score de Condition Météo (0-100)

**Matrice de compatibilité** :

| Souhaité | Obtenu | Score |
|----------|--------|-------|
| clear | clear | 100% |
| clear | partly_cloudy | 85% |
| clear | cloudy | 65% |
| clear | overcast | 35% |
| clear | rain | 10% |
| partly_cloudy | clear | 85% |
| partly_cloudy | cloudy | 65% |
| partly_cloudy | rain | 35% |
| cloudy | partly_cloudy | 65% |
| cloudy | rain | 35% |

**Fichier** : `lib/core/utils/score_calculator.dart` - `_calculateConditionScore()`

### C. Stabilité Météo (0-100)

**Calcul** :
1. **Stabilité température** (60% du poids)
   - Variance = moyenne((temp - moyenne)²)
   - Écart-type = √(variance)
   - Score = (1 - min(écart-type/10, 1)) × 100
   - Écart-type de 0°C = 100% stable
   - Écart-type de 10°C+ = 0% stable

2. **Stabilité conditions** (40% du poids)
   - Condition la plus fréquente
   - Score = (nb_jours_condition_dominante / total_jours) × 100

**Fichier** : `lib/core/utils/score_calculator.dart` - `calculateWeatherStability()`

---

## 🎯 Score d'Activités (0-100)

**Formule** :
```
Score = (activités_trouvées / activités_souhaitées) × 100
```

**Exemple** :
- Activités souhaitées : 3
- Activités trouvées : 2
- Score = 2/3 × 100 = 66.7%

**Note** : Ce score n'est calculé que si des activités sont recherchées (mode avancé).

**Fichier** : `lib/core/utils/score_calculator.dart` - `calculateActivityScore()`

---

## 📍 Pénalité Distance

Si la distance est très importante, une pénalité peut être appliquée au score global.

**Note** : La formule exacte de la pénalité distance est calculée côté Firebase et n'est pas visible dans le code client.

---

## 🔄 Calcul Final

### Mode Recherche Simple (Destination)

```
Score Global = Score Météo
```

### Mode Recherche Avancée (Activité)

```
Score Global = (Score Météo × Poids_Météo) + (Score Activités × Poids_Activités) - Pénalité Distance
```

**Poids estimés** (basés sur l'analyse) :
- Score Météo : ~70-80%
- Score Activités : ~20-30%
- Pénalité Distance : Variable selon la distance

---

## 📝 Notes Importantes

1. **Calcul côté Firebase** : Le score global est calculé dans la Cloud Function `searchDestinations`, pas côté client.

2. **Transparence limitée** : Le code client ne contient que les utilitaires de calcul partiels (`ScoreCalculator`), pas la formule complète du score global.

3. **Recommandation** : Pour une transparence complète, il faudrait :
   - Documenter la formule exacte dans la Cloud Function
   - Ou calculer le score côté client
   - Ou retourner la décomposition du score depuis Firebase

---

## 🎨 Affichage dans l'UI

Le score global est affiché dans les résultats avec un code couleur :
- **≥ 80%** : Vert (excellent)
- **60-79%** : Orange (bon)
- **< 60%** : Rouge (moyen)

**Fichier** : `lib/presentation/screens/search_results_screen.dart` - `_buildScoreBadge()`

---

*Cette documentation a été générée par analyse du code source. Pour la formule exacte, se référer à la Cloud Function Firebase.*
