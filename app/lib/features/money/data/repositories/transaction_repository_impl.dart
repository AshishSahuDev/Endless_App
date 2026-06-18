import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDatasource _datasource;
  TransactionRepositoryImpl(this._datasource);

  @override
  Future<List<MoneyTransaction>> getAllTransactions() async {
    final models = await _datasource.getAllTransactions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<MoneyTransaction>> getByMonth(int year, int month) async {
    final models = await _datasource.getByMonth(year, month);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<MoneyTransaction>> getRecent(int limit) async {
    final models = await _datasource.getRecent(limit);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> addTransaction(MoneyTransaction tx) {
    return _datasource.putTransaction(TransactionModel.fromEntity(tx));
  }

  @override
  Future<void> deleteTransaction(int id) => _datasource.deleteTransaction(id);
}
