import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/monthly_summary.dart';
import '../../domain/entities/savings_goal.dart';
import '../providers/money_provider.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/expense_bar_chart.dart';
import '../widgets/savings_goal_card.dart';
import '../widgets/savings_goal_sheet.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_card.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            const SizedBox(height: 4),
            const SummaryCard(),
            const SizedBox(height: 12),
            _TabBar(controller: _tabCtrl),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _TransactionsTab(),
                  _SavingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabCtrl.index == 0
            ? showAddTransactionSheet(context)
            : showCreateGoalSheet(context),
        backgroundColor: kAccentPurple,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          const Text('Money',
              style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.savings_rounded,
                color: kAccentPurple, size: 20),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 40,
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: kAccentPurple,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: kTextSecondary,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Transactions'),
          Tab(text: 'Goals'),
        ],
      ),
    );
  }
}

class _TransactionsTab extends ConsumerWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return txAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: kAccentPurple)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: kTextSecondary))),
      data: (txList) {
        if (txList.isEmpty) {
          return const _EmptyState(
            icon: Icons.receipt_long_rounded,
            message: 'No transactions this month',
            sub: 'Tap + to add income or an expense',
          );
        }

        final MonthlySummary? summary = summaryAsync.valueOrNull;
        final hasExpenses = summary != null && summary.totalExpense > 0;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 100),
          // +1 for charts header when there are expenses
          itemCount: txList.length + (hasExpenses ? 1 : 0),
          itemBuilder: (_, i) {
            if (hasExpenses && i == 0) {
              return _ChartsSection(summary: summary);
            }
            final tx = txList[hasExpenses ? i - 1 : i];
            return TransactionCard(
              transaction: tx,
              onDelete: () =>
                  ref.read(transactionsProvider.notifier).delete(tx.id),
            );
          },
        );
      },
    );
  }
}

class _ChartsSection extends StatelessWidget {
  final MonthlySummary summary;
  const _ChartsSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpenseBarChart(summary: summary),
        CategoryPieChart(
          expenseByCategory: summary.expenseByCategory,
          totalExpense: summary.totalExpense,
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Divider(color: kGlassBorder),
        ),
      ],
    );
  }
}

class _SavingsTab extends ConsumerWidget {
  const _SavingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return goalsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: kAccentPurple)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: kTextSecondary))),
      data: (goals) {
        if (goals.isEmpty) {
          return const _EmptyState(
            icon: Icons.savings_rounded,
            message: 'No savings goals yet',
            sub: 'Tap + to create your first goal',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 100),
          itemCount: goals.length,
          itemBuilder: (_, i) {
            final goal = goals[i];
            return SavingsGoalCard(
              goal: goal,
              onAddFunds: () => showAddFundsSheet(context, goal),
              onDelete: () => _confirmDelete(context, ref, goal),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, SavingsGoal goal) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgSecondary,
        title: const Text('Delete goal?',
            style: TextStyle(color: kTextPrimary)),
        content: Text('Delete "${goal.name}"? This cannot be undone.',
            style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(savingsGoalsProvider.notifier).delete(goal.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState(
      {required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: kTextHint),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(color: kTextHint, fontSize: 13)),
        ],
      ),
    );
  }
}
