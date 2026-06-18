import 'package:isar/isar.dart';
import '../models/transaction_model.dart';
import '../../../../core/errors/app_exceptions.dart';

class TransactionLocalDatasource {
  final Isar _isar;
  TransactionLocalDatasource(this._isar);

  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      return _isar.transactionModels.where().sortByDateDesc().findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load transactions', cause: e);
    }
  }

  Future<List<TransactionModel>> getByMonth(int year, int month) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));
      return _isar.transactionModels
          .filter()
          .dateBetween(start, end)
          .sortByDateDesc()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load monthly transactions', cause: e);
    }
  }

  Future<List<TransactionModel>> getRecent(int limit) async {
    try {
      return _isar.transactionModels.where().sortByDateDesc().limit(limit).findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load recent transactions', cause: e);
    }
  }

  Future<int> putTransaction(TransactionModel model) async {
    try {
      return _isar.writeTxn(() => _isar.transactionModels.put(model));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to save transaction', cause: e);
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _isar.writeTxn(() => _isar.transactionModels.delete(id));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to delete transaction', cause: e);
    }
  }
}
