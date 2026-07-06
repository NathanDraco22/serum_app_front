import 'package:intl/intl.dart';

class DateTimeTool {
  static String formatyyyyMMdd(DateTime datetime) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(datetime);
  }

  static String formatddMMyy(DateTime datetime) {
    final formatter = DateFormat('dd-MM-yy');
    return formatter.format(datetime);
  }

  static String formatddMMyyEs(DateTime datetime) {
    final formatter = DateFormat('dd-MMM-yy', 'es');
    return formatter.format(datetime);
  }

  static String formatddMM(DateTime datetime) {
    final formatter = DateFormat('dd-MM');
    return formatter.format(datetime);
  }

  static String formatdMMeS(DateTime datetime) {
    final formatter = DateFormat('d-MMM', 'es');
    return formatter.format(datetime);
  }

  static String formatMMyy(DateTime datetime) {
    final formatter = DateFormat('MM-yy');
    return formatter.format(datetime);
  }

  static String formatHHmm(DateTime datetime) {
    final formatter = DateFormat('hh:mm a');
    return formatter.format(datetime);
  }

  static DateTime fromMMYY(String date) => DateFormat('M/yy').parse(date);

  static DateTime getTodayMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

extension DateTimeExtension on DateTime {
  DateTime startOfDay() => DateTime(year, month, day);
  DateTime endOfDay() {
    final tomorrow = DateTime(year, month, day).add(
      const Duration(days: 1),
    );
    return tomorrow.subtract(const Duration(milliseconds: 1));
  }
}
