import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat('EEEE').format(date);
  if (date.year == now.year) return DateFormat('d MMM').format(date);
  return DateFormat('d MMM yyyy').format(date);
}

bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

Map<String, List<T>> groupByDate<T>(List<T> items, DateTime Function(T) getDate) {
  final result = <String, List<T>>{};
  for (final item in items) {
    final key = formatDate(getDate(item));
    result.putIfAbsent(key, () => []).add(item);
  }
  return result;
}
