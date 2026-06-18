import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../../../../core/errors/app_exceptions.dart';

class CreateTaskUseCase {
  final TaskRepository _repository;
  const CreateTaskUseCase(this._repository);

  Future<int> call(Task task) async {
    if (task.title.trim().isEmpty) {
      throw const ValidationException('Task title cannot be empty');
    }
    return _repository.createTask(task);
  }
}
