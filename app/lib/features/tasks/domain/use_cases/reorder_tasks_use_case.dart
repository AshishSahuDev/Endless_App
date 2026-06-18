import '../repositories/task_repository.dart';

class ReorderTasksUseCase {
  final TaskRepository _repository;
  const ReorderTasksUseCase(this._repository);

  Future<void> call(int fromIndex, int toIndex) =>
      _repository.reorder(fromIndex, toIndex);
}
