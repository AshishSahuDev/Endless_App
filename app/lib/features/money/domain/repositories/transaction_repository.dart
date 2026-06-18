import '../entities/transaction.dart';

abstract interface class TransactionRepository {
  Future<List<MoneyTransaction>> getAllTransactions();
  Future<List<MoneyTransaction>> getByMonth(int year, int month);
  Future<List<MoneyTransaction>> getRecent(int limit);
  Future<int> addTransaction(MoneyTransaction tx);
  Future<void> deleteTransaction(int id);
}
