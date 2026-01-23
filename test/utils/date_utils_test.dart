import 'package:flutter_test/flutter_test.dart';
import 'package:iwantsun/core/utils/date_utils.dart';

void main() {
  group('DateUtils Tests', () {
    test('isDateRangeValid - valid range', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 10);
      
      expect(DateUtils.isDateRangeValid(start, end), isTrue);
    });

    test('isDateRangeValid - invalid range (end before start)', () {
      final start = DateTime(2026, 1, 10);
      final end = DateTime(2026, 1, 1);
      
      expect(DateUtils.isDateRangeValid(start, end), isFalse);
    });

    test('isDateRangeValid - same date (invalid)', () {
      final date = DateTime(2026, 1, 1);
      
      expect(DateUtils.isDateRangeValid(date, date), isFalse);
    });

    test('daysBetween - calculates correct difference', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 10);
      
      expect(DateUtils.daysBetween(start, end), 9);
    });

    test('daysBetween - same day returns 0', () {
      final date = DateTime(2026, 1, 1);
      
      expect(DateUtils.daysBetween(date, date), 0);
    });

    test('formatDate - formats correctly', () {
      final date = DateTime(2026, 1, 22);
      final formatted = DateUtils.formatDate(date);
      
      expect(formatted, '22/01/2026');
    });

    test('formatDateRange - formats range correctly', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 10);
      final formatted = DateUtils.formatDateRange(start, end);
      
      expect(formatted, '01/01/2026 - 10/01/2026');
    });
  });
}
