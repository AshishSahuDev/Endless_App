import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:endless/features/money/domain/entities/savings_goal.dart';
import 'package:endless/features/money/presentation/widgets/savings_goal_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

SavingsGoal _goal({double target = 100000, double saved = 0, String name = 'MacBook'}) =>
    SavingsGoal(
      id: 1,
      name: name,
      targetAmount: target,
      savedAmount: saved,
      createdAt: DateTime(2024, 1, 1),
    );

void main() {
  setUpAll(() {
    // Disable network fetch for fonts during tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('SavingsGoalCard', () {
    testWidgets('shows goal name', (tester) async {
      await tester.pumpWidget(_wrap(SavingsGoalCard(
        goal: _goal(),
        onAddFunds: () {},
        onDelete: () {},
      )));
      expect(find.text('MacBook'), findsOneWidget);
    });

    testWidgets('shows saved amount', (tester) async {
      await tester.pumpWidget(_wrap(SavingsGoalCard(
        goal: _goal(saved: 30000),
        onAddFunds: () {},
        onDelete: () {},
      )));
      // _fmt(30000) → '30.0K', displayed as '₹30.0K'
      expect(find.textContaining('30.0K'), findsOneWidget);
    });

    testWidgets('shows correct progress percentage', (tester) async {
      await tester.pumpWidget(_wrap(SavingsGoalCard(
        goal: _goal(saved: 25000),
        onAddFunds: () {},
        onDelete: () {},
      )));
      expect(find.textContaining('25%'), findsOneWidget);
    });

    testWidgets('Add Funds button visible when not completed', (tester) async {
      await tester.pumpWidget(_wrap(SavingsGoalCard(
        goal: _goal(saved: 40000),
        onAddFunds: () {},
        onDelete: () {},
      )));
      expect(find.text('Add Funds'), findsOneWidget);
    });

    testWidgets('Add Funds button hidden when completed', (tester) async {
      await tester.pumpWidget(_wrap(SavingsGoalCard(
        goal: _goal(saved: 100000),
        onAddFunds: () {},
        onDelete: () {},
      )));
      expect(find.text('Add Funds'), findsNothing);
    });

    testWidgets('calls onAddFunds callback when tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(SavingsGoalCard(
        goal: _goal(saved: 50000),
        onAddFunds: () => called = true,
        onDelete: () {},
      )));
      await tester.tap(find.text('Add Funds'));
      expect(called, isTrue);
    });

    testWidgets('calls onDelete when delete icon tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(SavingsGoalCard(
        goal: _goal(),
        onAddFunds: () {},
        onDelete: () => called = true,
      )));
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(called, isTrue);
    });
  });
}
