import 'package:intl/intl.dart';

class CurrencyUtils {
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'Ksh ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
