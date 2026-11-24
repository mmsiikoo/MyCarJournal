import 'package:intl/intl.dart';

final NumberFormat _money = NumberFormat.currency(
  locale: 'uk_UA',
  symbol: '₴',
  decimalDigits: 2,
);

final NumberFormat _moneyWhole = NumberFormat.currency(
  locale: 'uk_UA',
  symbol: '₴',
  decimalDigits: 0,
);

final NumberFormat _decimal = NumberFormat('#,##0.##', 'uk_UA');
final NumberFormat _whole = NumberFormat('#,##0', 'uk_UA');

String formatMoney(num value, {bool whole = false}) =>
    (whole ? _moneyWhole : _money).format(value);

String formatDecimal(num value) => _decimal.format(value);

String formatWhole(num value) => _whole.format(value);

String formatDate(DateTime date) =>
    DateFormat('dd.MM.yyyy', 'uk_UA').format(date);

String formatMonthYear(DateTime date) {
  final raw = DateFormat('LLLL yyyy', 'uk_UA').format(date);
  return _capitalize(raw);
}

String formatMonthShort(DateTime date) {
  final raw = DateFormat('LLL', 'uk_UA').format(date);
  return _capitalize(raw.replaceAll('.', ''));
}

String formatDateTime(DateTime date) =>
    DateFormat('dd.MM.yyyy HH:mm', 'uk_UA').format(date);

String formatOdometer(num value) => '${formatWhole(value)} км';

String formatLiters(num value) => '${formatDecimal(value)} л';

String formatConsumption(num value) => '${formatDecimal(value)} л/100 км';

String formatPricePerLiter(num value) => '${formatMoney(value)}/л';

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'MJ';
  if (parts.length == 1) {
    final part = parts.first;
    return part.substring(0, part.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
