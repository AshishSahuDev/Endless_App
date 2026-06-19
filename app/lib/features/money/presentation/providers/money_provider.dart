import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/datasources/savings_goal_local_datasource.dart';
import '../../data/datasources/transaction_local_datasource.dart';
import '../../data/repositories/savings_goal_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/monthly_summary.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/use_cases/add_transaction_use_case.dart';
import '../../domain/use_cases/delete_transaction_use_case.dart';
import '../../domain/use_cases/get_monthly_summary_use_case.dart';

// ── Repository providers ──────────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return TransactionRepositoryImpl(TransactionLocalDatasource(isar));
});

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return SavingsGoalRepositoryImpl(SavingsGoalLocalDatasource(isar));
});

// ── Selected month state ──────────────────────────────────────

class SelectedMonth {
  final int year;
  final int month;
  const SelectedMonth(this.year, this.month);
}

final selectedMonthProvider = StateProvider<SelectedMonth>((ref) {
  final now = DateTime.now();
  return SelectedMonth(now.year, now.month);
});

// ── Monthly summary ───────────────────────────────────────────

final monthlySummaryProvider = FutureProvider<MonthlySummary>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final sel = ref.watch(selectedMonthProvider);
  return GetMonthlySummaryUseCase(repo)(sel.year, sel.month);
});

// ── Transactions notifier ─────────────────────────────────────

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<MoneyTransaction>>(
        TransactionsNotifier.new);

class TransactionsNotifier extends AsyncNotifier<List<MoneyTransaction>> {
  late TransactionRepository _repository;

  @override
  Future<List<MoneyTransaction>> build() async {
    _repository = ref.watch(transactionRepositoryProvider);
    final sel = ref.watch(selectedMonthProvider);
    return _repository.getByMonth(sel.year, sel.month);
  }

  Future<void> add(MoneyTransaction tx) async {
    try {
      await AddTransactionUseCase(_repository)(tx);
      AppLogger.I.action('money', 'addTx',
          data: {'type': tx.isExpense ? 'expense' : 'income', 'amount': tx.amount, 'cat': tx.categorySlug});
      ref.invalidateSelf();
      ref.invalidate(monthlySummaryProvider);
    } catch (e, s) {
      AppLogger.I.error('money', 'addTx failed', error: e, stack: s);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await DeleteTransactionUseCase(_repository)(id);
      AppLogger.I.action('money', 'deleteTx', data: {'id': id});
      state = AsyncData(state.valueOrNull?.where((t) => t.id != id).toList() ?? []);
      ref.invalidate(monthlySummaryProvider);
    } catch (e, s) {
      AppLogger.I.error('money', 'deleteTx failed', error: e, stack: s, data: {'id': id});
      rethrow;
    }
  }
}

// ── Savings goals notifier ────────────────────────────────────

final savingsGoalsProvider =
    AsyncNotifierProvider<SavingsGoalsNotifier, List<SavingsGoal>>(
        SavingsGoalsNotifier.new);

class SavingsGoalsNotifier extends AsyncNotifier<List<SavingsGoal>> {
  late SavingsGoalRepository _repository;

  @override
  Future<List<SavingsGoal>> build() async {
    _repository = ref.watch(savingsGoalRepositoryProvider);
    return _repository.getAllGoals();
  }

  Future<void> create(SavingsGoal goal) async {
    try {
      await _repository.createGoal(goal);
      AppLogger.I.action('goals', 'create',
          data: {'target': goal.targetAmount, 'hasDeadline': goal.deadline != null});
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('goals', 'create failed', error: e, stack: s);
      rethrow;
    }
  }

  Future<void> addToSavings(int id, double amount) async {
    try {
      await _repository.addToSavings(id, amount);
      AppLogger.I.action('goals', 'addFunds', data: {'id': id, 'amount': amount});
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('goals', 'addFunds failed', error: e, stack: s, data: {'id': id});
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.deleteGoal(id);
      AppLogger.I.action('goals', 'delete', data: {'id': id});
      state = AsyncData(state.valueOrNull?.where((g) => g.id != id).toList() ?? []);
    } catch (e, s) {
      AppLogger.I.error('goals', 'delete failed', error: e, stack: s, data: {'id': id});
      rethrow;
    }
  }
}
