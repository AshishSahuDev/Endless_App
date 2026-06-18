import '../repositories/task_repository.dart';

class ToggleCompleteUseCase {
  final TaskRepository _repository;
  const ToggleCompleteUseCase(this._repository);

  Future<void> call(int id) => _repository.toggleComplete(id);
}
