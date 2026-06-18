import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../../../../core/errors/app_exceptions.dart';

class AddTransactionUseCase {
  final TransactionRepository _repository;
  const AddTransactionUseCase(this._repository);

  Future<int> call(MoneyTransaction tx) async {
    if (tx.amount <= 0) throw const ValidationException('Amount must be greater than 0');
    if (tx.categorySlug.isEmpty) throw const ValidationException('Please select a category');
    return _repository.addTransaction(tx);
  }
}
