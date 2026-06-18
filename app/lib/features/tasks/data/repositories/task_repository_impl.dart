import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDatasource _datasource;
  TaskRepositoryImpl(this._datasource);

  @override
  Future<List<Task>> getAllTasks() async {
    final models = await _datasource.getAllTasks();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Task>> getActiveTasks() async {
    final models = await _datasource.getActiveTasks();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    final models = await _datasource.getCompletedTasks();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Task?> getTaskById(int id) async {
    final model = await _datasource.getTaskById(id);
    return model?.toEntity();
  }

  @override
  Future<int> createTask(Task task) {
    final model = TaskModel.fromEntity(task);
    return _datasource.putTask(model);
  }

  @override
  Future<void> updateTask(Task task) async {
    final model = TaskModel.fromEntity(task);
    await _datasource.putTask(model);
  }

  @override
  Future<void> deleteTask(int id) => _datasource.deleteTask(id);

  @override
  Future<void> toggleComplete(int id) async {
    final model = await _datasource.getTaskById(id);
    if (model == null) return;
    model.isCompleted = !model.isCompleted;
    model.updatedAt = DateTime.now();
    await _datasource.putTask(model);
  }

  @override
  Future<void> reorder(int fromIndex, int toIndex) async {
    final models = await _datasource.getActiveTasks();
    if (fromIndex < 0 || toIndex < 0 ||
        fromIndex >= models.length || toIndex >= models.length) {
      return;
    }

    final item = models.removeAt(fromIndex);
    models.insert(toIndex, item);

    final now = DateTime.now();
    for (int i = 0; i < models.length; i++) {
      models[i].sortOrder = i;
      models[i].updatedAt = now;
    }
    await _datasource.reorderTasks(models);
  }
}
