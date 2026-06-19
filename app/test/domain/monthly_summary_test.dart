import 'package:flutter_test/flutter_test.dart';
import 'package:endless/features/money/domain/entities/monthly_summary.dart';
import 'package:endless/features/money/domain/entities/transaction.dart';

MoneyTransaction _tx({
  required double amount,
  required bool isExpense,
  required String slug,
  int day = 1,
}) {
  final date = DateTime(2024, 6, day);
  return MoneyTransaction(
    id: 0,
    amount: amount,
    isExpense: isExpense,
    categorySlug: slug,
    date: date,
    createdAt: date,
  );
}

void main() {
  group('MonthlySummary.balance', () {
    test('balance = income - expense', () {
      const s = MonthlySummary(
        year: 2024,
        month: 6,
        totalIncome: 50000,
        totalExpense: 20000,
        transactions: [],
      );
      expect(s.balance, 30000);
    });

    test('negative balance when expenses exceed income', () {
      const s = MonthlySummary(
        year: 2024,
        month: 6,
        totalIncome: 5000,
        totalExpense: 8000,
        transactions: [],
      );
      expect(s.balance, -3000);
    });

    test('zero balance when equal', () {
      const s = MonthlySummary(
        year: 2024,
        month: 6,
        totalIncome: 10000,
        totalExpense: 10000,
        transactions: [],
      );
      expect(s.balance, 0);
    });
  });

  group('MonthlySummary.expenseByCategory', () {
    test('groups expenses by category slug', () {
      final txs = [
        _tx(amount: 500, isExpense: true, slug: 'food'),
        _tx(amount: 200, isExpense: true, slug: 'food'),
        _tx(amount: 1000, isExpense: true, slug: 'transport'),
        _tx(amount: 5000, isExpense: false, slug: 'salary'),
      ];
      final s = MonthlySummary(
        year: 2024, month: 6,
        totalIncome: 5000, totalExpense: 1700,
        transactions: txs,
      );
      final map = s.expenseByCategory;
      expect(map['food'], 700);
      expect(map['transport'], 1000);
      expect(map.containsKey('salary'), isFalse);
    });

    test('returns empty map when no expenses', () {
      final s = MonthlySummary(
        year: 2024, month: 6,
        totalIncome: 10000, totalExpense: 0,
        transactions: [
          _tx(amount: 10000, isExpense: false, slug: 'salary'),
        ],
      );
      expect(s.expenseByCategory, isEmpty);
    });
  });

  group('MonthlySummary.dailyExpenses', () {
    test('groups expenses by day of month', () {
      final txs = [
        _tx(amount: 300, isExpense: true, slug: 'food', day: 5),
        _tx(amount: 150, isExpense: true, slug: 'transport', day: 5),
        _tx(amount: 800, isExpense: true, slug: 'bills', day: 15),
        _tx(amount: 5000, isExpense: false, slug: 'salary', day: 1),
      ];
      final s = MonthlySummary(
        year: 2024, month: 6,
        totalIncome: 5000, totalExpense: 1250,
        transactions: txs,
      );
      final map = s.dailyExpenses;
      expect(map[5], 450);
      expect(map[15], 800);
      expect(map.containsKey(1), isFalse);
    });

    test('returns empty map when no expenses', () {
      const s = MonthlySummary(
        year: 2024, month: 6,
        totalIncome: 0, totalExpense: 0,
        transactions: [],
      );
      expect(s.dailyExpenses, isEmpty);
    });
  });
}
