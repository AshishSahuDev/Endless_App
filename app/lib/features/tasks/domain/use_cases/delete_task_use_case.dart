import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  final TaskRepository _repository;
  const DeleteTaskUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteTask(id);
}
