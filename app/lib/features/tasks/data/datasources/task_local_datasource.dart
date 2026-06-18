import 'package:isar/isar.dart';
import '../models/task_model.dart';
import '../../../../core/errors/app_exceptions.dart';

class TaskLocalDatasource {
  final Isar _isar;
  TaskLocalDatasource(this._isar);

  Future<List<TaskModel>> getAllTasks() async {
    try {
      return _isar.taskModels.where().sortBySortOrder().findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load tasks', cause: e);
    }
  }

  Future<List<TaskModel>> getActiveTasks() async {
    try {
      return _isar.taskModels
          .filter()
          .isCompletedEqualTo(false)
          .sortBySortOrder()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load active tasks', cause: e);
    }
  }

  Future<List<TaskModel>> getCompletedTasks() async {
    try {
      return _isar.taskModels
          .filter()
          .isCompletedEqualTo(true)
          .sortByUpdatedAtDesc()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load completed tasks', cause: e);
    }
  }

  Future<TaskModel?> getTaskById(int id) async {
    try {
      return _isar.taskModels.get(id);
    } on IsarError catch (e) {
      throw DatabaseException('Failed to get task', cause: e);
    }
  }

  Future<int> putTask(TaskModel model) async {
    try {
      return _isar.writeTxn(() => _isar.taskModels.put(model));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to save task', cause: e);
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _isar.writeTxn(() => _isar.taskModels.delete(id));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to delete task', cause: e);
    }
  }

  Future<void> reorderTasks(List<TaskModel> tasks) async {
    try {
      await _isar.writeTxn(() => _isar.taskModels.putAll(tasks));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to reorder tasks', cause: e);
    }
  }
}
