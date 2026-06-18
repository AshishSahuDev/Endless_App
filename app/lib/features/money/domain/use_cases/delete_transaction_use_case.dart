import '../repositories/transaction_repository.dart';

class DeleteTransactionUseCase {
  final TransactionRepository _repository;
  const DeleteTransactionUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteTransaction(id);
}
