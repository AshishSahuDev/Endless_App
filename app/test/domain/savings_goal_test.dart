import 'package:flutter_test/flutter_test.dart';
import 'package:endless/features/money/domain/entities/savings_goal.dart';

SavingsGoal _goal({double target = 100000, double saved = 0}) => SavingsGoal(
      id: 1,
      name: 'Test Goal',
      targetAmount: target,
      savedAmount: saved,
      createdAt: DateTime(2024, 1, 1),
    );

void main() {
  group('SavingsGoal.progress', () {
    test('zero when nothing saved', () {
      expect(_goal().progress, 0.0);
    });

    test('0.5 at half way', () {
      expect(_goal(saved: 50000).progress, closeTo(0.5, 0.001));
    });

    test('1.0 when fully funded', () {
      expect(_goal(saved: 100000).progress, 1.0);
    });

    test('clamped to 1.0 when over-funded', () {
      expect(_goal(saved: 120000).progress, 1.0);
    });

    test('0.0 when target is zero', () {
      expect(_goal(target: 0).progress, 0.0);
    });
  });

  group('SavingsGoal.isCompleted', () {
    test('false when not yet funded', () {
      expect(_goal(saved: 50000).isCompleted, isFalse);
    });

    test('true when exactly at target', () {
      expect(_goal(saved: 100000).isCompleted, isTrue);
    });

    test('true when over target', () {
      expect(_goal(saved: 110000).isCompleted, isTrue);
    });
  });

  group('SavingsGoal.copyWith', () {
    test('changes saved amount', () {
      final g = _goal(saved: 10000);
      final updated = g.copyWith(savedAmount: 25000);
      expect(updated.savedAmount, 25000);
      expect(updated.targetAmount, g.targetAmount);
      expect(updated.name, g.name);
    });

    test('changes name', () {
      final g = _goal();
      expect(g.copyWith(name: 'Car').name, 'Car');
    });
  });
}
