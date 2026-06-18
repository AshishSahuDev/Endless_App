import '../entities/task.dart';

abstract interface class TaskRepository {
  Future<List<Task>> getAllTasks();
  Future<List<Task>> getActiveTasks();
  Future<List<Task>> getCompletedTasks();
  Future<Task?> getTaskById(int id);
  Future<int> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(int id);
  Future<void> toggleComplete(int id);
  Future<void> reorder(int fromIndex, int toIndex);
}
