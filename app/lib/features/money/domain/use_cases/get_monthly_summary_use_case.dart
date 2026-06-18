import '../entities/monthly_summary.dart';
import '../repositories/transaction_repository.dart';

class GetMonthlySummaryUseCase {
  final TransactionRepository _repository;
  const GetMonthlySummaryUseCase(this._repository);

  Future<MonthlySummary> call(int year, int month) async {
    final txns = await _repository.getByMonth(year, month);
    double income = 0;
    double expense = 0;
    for (final t in txns) {
      if (t.isExpense) {
        expense += t.amount;
      } else {
        income += t.amount;
      }
    }
    return MonthlySummary(
      year: year,
      month: month,
      totalIncome: income,
      totalExpense: expense,
      transactions: txns,
    );
  }
}
