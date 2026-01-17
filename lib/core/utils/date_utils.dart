import 'package:intl/intl.dart';

/// Utilitaires pour la gestion des dates
class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  static String formatDateRange(DateTime start, DateTime end) {
    return '${formatDate(start)} - ${formatDate(end)}';
  }
  
  static String formatDateWithWeekday(DateTime date) {
    return DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
  }
  
  static int daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }
  
  static bool isDateRangeValid(DateTime start, DateTime end) {
    return end.isAfter(start);
  }
}
