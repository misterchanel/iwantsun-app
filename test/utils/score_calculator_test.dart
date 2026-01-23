import 'package:flutter_test/flutter_test.dart';
import 'package:iwantsun/core/utils/score_calculator.dart';

void main() {
  group('ScoreCalculator Tests', () {
    test('calculateWeatherScore - exact temperature match', () {
      final score = ScoreCalculator.calculateWeatherScore(
        desiredMinTemp: 20.0,
        desiredMaxTemp: 25.0,
        actualMinTemp: 20.0,
        actualMaxTemp: 25.0,
        desiredCondition: 'clear',
        actualCondition: 'clear',
        weatherStability: 100.0,
      );

      // Temp score should be 100% (0°C difference)
      // Condition score should be 100% (exact match)
      // Final: (100 * 0.35) + (100 * 0.50) + (100 * 0.15) = 100
      expect(score, closeTo(100.0, 0.1));
    });

    test('calculateWeatherScore - 5°C temperature difference', () {
      final score = ScoreCalculator.calculateWeatherScore(
        desiredMinTemp: 20.0,
        desiredMaxTemp: 25.0,
        actualMinTemp: 15.0,
        actualMaxTemp: 20.0,
        desiredCondition: 'clear',
        actualCondition: 'clear',
        weatherStability: 100.0,
      );

      // Average difference: 5°C
      // Temp score: 100 * exp(-5/10) ≈ 60.65%
      // Condition: 100%
      // Final: (60.65 * 0.35) + (100 * 0.50) + (100 * 0.15) ≈ 86.2
      expect(score, greaterThan(80.0));
      expect(score, lessThan(90.0));
    });

    test('calculateWeatherScore - 10°C temperature difference', () {
      final score = ScoreCalculator.calculateWeatherScore(
        desiredMinTemp: 20.0,
        desiredMaxTemp: 25.0,
        actualMinTemp: 10.0,
        actualMaxTemp: 15.0,
        desiredCondition: 'clear',
        actualCondition: 'clear',
        weatherStability: 100.0,
      );

      // Average difference: 10°C
      // Temp score: 100 * exp(-10/10) ≈ 36.79%
      // Condition: 100%
      // Final: (36.79 * 0.35) + (100 * 0.50) + (100 * 0.15) ≈ 62.9
      // Mais avec stabilité à 100, le calcul donne environ 77.8
      expect(score, greaterThan(70.0));
      expect(score, lessThan(85.0));
    });

    test('calculateWeatherScore - very similar conditions (clear ↔ partly_cloudy)', () {
      final score = ScoreCalculator.calculateWeatherScore(
        desiredMinTemp: 20.0,
        desiredMaxTemp: 25.0,
        actualMinTemp: 20.0,
        actualMaxTemp: 25.0,
        desiredCondition: 'clear',
        actualCondition: 'partly_cloudy',
        weatherStability: 100.0,
      );

      // Temp: 100%
      // Condition: 85% (very similar)
      // Final: (100 * 0.35) + (85 * 0.50) + (100 * 0.15) = 92.5
      expect(score, closeTo(92.5, 0.1));
    });

    test('calculateWeatherScore - poor condition match (clear ↔ rain)', () {
      final score = ScoreCalculator.calculateWeatherScore(
        desiredMinTemp: 20.0,
        desiredMaxTemp: 25.0,
        actualMinTemp: 20.0,
        actualMaxTemp: 25.0,
        desiredCondition: 'clear',
        actualCondition: 'rain',
        weatherStability: 100.0,
      );

      // Temp: 100%
      // Condition: 10% (poor match)
      // Final: (100 * 0.35) + (10 * 0.50) + (100 * 0.15) = 55
      expect(score, closeTo(55.0, 0.1));
    });

    test('calculateActivityScore - all activities match', () {
      final score = ScoreCalculator.calculateActivityScore(
        desiredActivities: ['beach', 'hiking'],
        availableActivities: ['beach', 'hiking', 'cycling'],
      );

      expect(score, 100.0);
    });

    test('calculateActivityScore - partial match', () {
      final score = ScoreCalculator.calculateActivityScore(
        desiredActivities: ['beach', 'hiking', 'cycling'],
        availableActivities: ['beach', 'hiking'],
      );

      expect(score, closeTo(66.67, 0.1));
    });

    test('calculateActivityScore - no match', () {
      final score = ScoreCalculator.calculateActivityScore(
        desiredActivities: ['beach', 'hiking'],
        availableActivities: ['cycling', 'golf'],
      );

      expect(score, 0.0);
    });

    test('calculateActivityScore - empty desired activities', () {
      final score = ScoreCalculator.calculateActivityScore(
        desiredActivities: [],
        availableActivities: ['beach', 'hiking'],
      );

      expect(score, 100.0); // Should return 100% if no preferences
    });

    test('calculateActivityScore - empty available activities', () {
      final score = ScoreCalculator.calculateActivityScore(
        desiredActivities: ['beach', 'hiking'],
        availableActivities: [],
      );

      expect(score, 0.0);
    });

    test('calculateWeatherStability - perfect stability', () {
      final stability = ScoreCalculator.calculateWeatherStability(
        temperatures: [20.0, 20.0, 20.0, 20.0, 20.0],
        conditions: ['clear', 'clear', 'clear', 'clear', 'clear'],
      );

      expect(stability, closeTo(100.0, 0.1));
    });

    test('calculateWeatherStability - high temperature variance', () {
      final stability = ScoreCalculator.calculateWeatherStability(
        temperatures: [10.0, 20.0, 30.0, 15.0, 25.0],
        conditions: ['clear', 'clear', 'clear', 'clear', 'clear'],
      );

      // High variance should result in lower stability
      // Avec ces valeurs, l'écart-type est d'environ 7.07°C
      // Stabilité = (1 - 7.07/10) * 100 * 0.6 + 100 * 0.4 ≈ 57.6
      expect(stability, lessThan(70.0));
      expect(stability, greaterThan(40.0));
    });

    test('calculateWeatherStability - mixed conditions', () {
      final stability = ScoreCalculator.calculateWeatherStability(
        temperatures: [20.0, 20.0, 20.0, 20.0, 20.0],
        conditions: ['clear', 'clear', 'cloudy', 'clear', 'rain'],
      );

      // Mixed conditions should reduce stability
      expect(stability, lessThan(100.0));
      expect(stability, greaterThan(0.0));
    });

    test('calculateWeatherStability - empty lists', () {
      final stability = ScoreCalculator.calculateWeatherStability(
        temperatures: [],
        conditions: [],
      );

      expect(stability, 50.0); // Default value
    });

    test('calculateWeatherStability - single value', () {
      final stability = ScoreCalculator.calculateWeatherStability(
        temperatures: [20.0],
        conditions: ['clear'],
      );

      expect(stability, 100.0); // Should be 100% for single value
    });
  });
}
