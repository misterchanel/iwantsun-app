import 'dart:math' as math;

/// Utilitaires pour le calcul des scores de compatibilité
class ScoreCalculator {
  /// Calcule le score de compatibilité météo (0-100)
  static double calculateWeatherScore({
    required double desiredMinTemp,
    required double desiredMaxTemp,
    required double actualMinTemp,
    required double actualMaxTemp,
    required String desiredCondition,
    required String actualCondition,
    required double weatherStability,
  }) {
    final tempScore = _calculateTemperatureScore(
      desiredMinTemp,
      desiredMaxTemp,
      actualMinTemp,
      actualMaxTemp,
    );

    final conditionScore = _calculateConditionScore(
      desiredCondition,
      actualCondition,
    );

    // Pondération : condition météo plus importante que température
    return (tempScore * 0.35) + (conditionScore * 0.50) + (weatherStability * 0.15);
  }
  
  static double _calculateTemperatureScore(
    double desiredMin,
    double desiredMax,
    double actualMin,
    double actualMax,
  ) {
    // Calcul de la compatibilité des températures
    final desiredAvg = (desiredMin + desiredMax) / 2;
    final actualAvg = (actualMin + actualMax) / 2;
    final diff = (actualAvg - desiredAvg).abs();

    // Score progressif avec courbe exponentielle
    // 0°C d'écart = 100%
    // 5°C d'écart = ~60%
    // 10°C d'écart = ~35%
    // 15°C d'écart = ~15%
    // 25°C d'écart = ~0%
    final score = 100 * math.exp(-diff / 10.0);
    return score.clamp(0.0, 100.0);
  }
  
  static double _calculateConditionScore(
    String desired,
    String actual,
  ) {
    // Mapping des conditions météo avec scoring plus nuancé
    if (desired == actual) return 100.0;

    // Conditions très similaires (85%)
    final verySimilar = {
      'clear': ['partly_cloudy'],
      'partly_cloudy': ['clear'],
    };

    if (verySimilar[desired]?.contains(actual) ?? false) {
      return 85.0;
    }

    // Conditions moyennement similaires (65%)
    final moderatelySimilar = {
      'clear': ['cloudy'],
      'partly_cloudy': ['cloudy'],
      'cloudy': ['partly_cloudy', 'overcast'],
      'overcast': ['cloudy'],
    };

    if (moderatelySimilar[desired]?.contains(actual) ?? false) {
      return 65.0;
    }

    // Conditions peu compatibles (35%)
    final poorMatch = {
      'clear': ['overcast'],
      'partly_cloudy': ['overcast', 'rain'],
      'cloudy': ['rain'],
      'overcast': ['rain'],
    };

    if (poorMatch[desired]?.contains(actual) ?? false) {
      return 35.0;
    }

    // Conditions incompatibles (10%)
    return 10.0;
  }
  
  /// Calcule le score d'activités (0-100)
  static double calculateActivityScore({
    required List<String> desiredActivities,
    required List<String> availableActivities,
  }) {
    if (desiredActivities.isEmpty) return 100.0;
    if (availableActivities.isEmpty) return 0.0;

    final matches = desiredActivities
        .where((activity) => availableActivities.contains(activity))
        .length;

    return (matches / desiredActivities.length) * 100;
  }

  /// Calcule la stabilité météo réelle basée sur la variance (0-100)
  /// Plus le score est élevé, plus la météo est stable
  static double calculateWeatherStability({
    required List<double> temperatures,
    required List<String> conditions,
  }) {
    if (temperatures.isEmpty || conditions.isEmpty) return 50.0;

    // 1. Variance de température
    final tempStability = _calculateTemperatureStability(temperatures);

    // 2. Consistance des conditions météo
    final conditionStability = _calculateConditionStability(conditions);

    // Moyenne pondérée (température 60%, conditions 40%)
    return (tempStability * 0.6) + (conditionStability * 0.4);
  }

  /// Calcule la stabilité de température basée sur la variance
  static double _calculateTemperatureStability(List<double> temperatures) {
    if (temperatures.length < 2) return 100.0;

    // Calculer la moyenne
    final mean = temperatures.reduce((a, b) => a + b) / temperatures.length;

    // Calculer la variance
    final variance = temperatures
            .map((temp) => (temp - mean) * (temp - mean))
            .reduce((a, b) => a + b) /
        temperatures.length;

    // Écart-type
    final stdDev = math.sqrt(variance);

    // Convertir en score de stabilité (0-100)
    // Écart-type de 0°C = 100% stable
    // Écart-type de 10°C ou plus = 0% stable
    final stability = (1 - (stdDev / 10.0).clamp(0.0, 1.0)) * 100;

    return stability;
  }

  /// Calcule la stabilité des conditions météo
  static double _calculateConditionStability(List<String> conditions) {
    if (conditions.length < 2) return 100.0;

    // Compter les occurrences de chaque condition
    final conditionCounts = <String, int>{};
    for (final condition in conditions) {
      conditionCounts[condition] = (conditionCounts[condition] ?? 0) + 1;
    }

    // Condition la plus fréquente
    final mostFrequent = conditionCounts.values.reduce((a, b) => a > b ? a : b);

    // Score: pourcentage de jours avec la condition dominante
    final stability = (mostFrequent / conditions.length) * 100;

    return stability;
  }
}
