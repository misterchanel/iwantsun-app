// Fichier principal pour exécuter tous les tests
// Usage: flutter test test/all_tests.dart

// Tests unitaires (ne nécessitent pas d'environnement Flutter complet)
import 'utils/score_calculator_test.dart' as score_calculator_test;
import 'utils/date_utils_test.dart' as date_utils_test;

void main() {
  // Exécuter tous les tests unitaires
  score_calculator_test.main();
  date_utils_test.main();
}
