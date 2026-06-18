import 'transaction.dart';

class MonthlySummary {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final List<MoneyTransaction> transactions;

  const MonthlySummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions,
  });

  double get balance => totalIncome - totalExpense;

  // Spending per category slug for pie chart
  Map<String, double> get expenseByCategory {
    final map = <String, double>{};
    for (final t in transactions) {
      if (t.isExpense) {
        map[t.categorySlug] = (map[t.categorySlug] ?? 0) + t.amount;
      }
    }
    return map;
  }
}
