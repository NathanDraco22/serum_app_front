import 'package:intl/intl.dart';
import 'package:serum_business/src/tools/constant.dart';

class NumberFormatter {
  static final NumberFormat _instance = NumberFormat.decimalPattern('en_US')
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;

  static String convertToMoneyLike(int valueInCents, {String? symbol}) {
    final valueInCurrency = valueInCents / 100;
    final value = double.parse(valueInCurrency.toStringAsFixed(2));
    return (symbol ?? defaultCoinSymbol) + _instance.format(value);
  }

  static String decimalPattern(num value) => _instance.format(value);

  static int convertFromDoubleToCents(double value) {
    return (value * 100).round();
  }

  static double convertFromCentsToDouble(int value) {
    return value / 100;
  }

  static String convertFromCentsToUnitsCurrency(int valueInCents) {
    final valueInCurrency = valueInCents / 100;
    final value = double.parse(valueInCurrency.toStringAsFixed(2));
    return _instance.format(value);
  }

  static String formatDisplayStock(int stock, int factor) {
    final safeFactor = factor < 1 ? 1 : factor;
    final val = stock / safeFactor;
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}
