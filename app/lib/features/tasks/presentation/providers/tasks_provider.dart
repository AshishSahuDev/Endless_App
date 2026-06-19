import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/use_cases/create_task_use_case.dart';
import '../../domain/use_cases/delete_task_use_case.dart';
import '../../domain/use_cases/reorder_tasks_use_case.dart';
import '../../domain/use_cases/toggle_complete_use_case.dart';
import '../../domain/use_cases/update_task_use_case.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final datasource = TaskLocalDatasource(isar);
  return TaskRepositoryImpl(datasource);
});

// Tab state: 0 = active, 1 = completed
final taskTabProvider = StateProvider<int>((ref) => 0);

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

class TasksNotifier extends AsyncNotifier<List<Task>> {
  late TaskRepository _repository;

  @override
  Future<List<Task>> build() async {
    _repository = ref.watch(taskRepositoryProvider);
    final tab = ref.watch(taskTabProvider);
    return tab == 0 ? _repository.getActiveTasks() : _repository.getCompletedTasks();
  }

  Future<void> create(Task task) async {
    try {
      final tasks = state.valueOrNull ?? [];
      final taskWithOrder = task.copyWith(sortOrder: tasks.length);
      await CreateTaskUseCase(_repository)(taskWithOrder);
      AppLogger.I.action('tasks', 'create',
          data: {'priority': task.priority.name, 'hasDue': task.dueDate != null});
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('tasks', 'create failed', error: e, stack: s);
      rethrow;
    }
  }

  Future<void> save(Task task) async {
    try {
      await UpdateTaskUseCase(_repository)(task);
      AppLogger.I.action('tasks', 'save', data: {'id': task.id});
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('tasks', 'save failed', error: e, stack: s, data: {'id': task.id});
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await DeleteTaskUseCase(_repository)(id);
      AppLogger.I.action('tasks', 'delete', data: {'id': id});
      state = AsyncData(state.valueOrNull?.where((t) => t.id != id).toList() ?? []);
    } catch (e, s) {
      AppLogger.I.error('tasks', 'delete failed', error: e, stack: s, data: {'id': id});
      rethrow;
    }
  }

  Future<void> toggleComplete(int id) async {
    try {
      await ToggleCompleteUseCase(_repository)(id);
      AppLogger.I.action('tasks', 'toggleComplete', data: {'id': id});
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('tasks', 'toggleComplete failed',
          error: e, stack: s, data: {'id': id});
      rethrow;
    }
  }

  Future<void> reorder(int from, int to) async {
    final tasks = List<Task>.from(state.valueOrNull ?? []);
    if (from < 0 || to < 0 || from >= tasks.length || to >= tasks.length) return;
    final item = tasks.removeAt(from);
    tasks.insert(to, item);
    state = AsyncData(tasks);
    try {
      await ReorderTasksUseCase(_repository)(from, to);
      AppLogger.I.action('tasks', 'reorder', data: {'from': from, 'to': to});
    } catch (e, s) {
      AppLogger.I.error('tasks', 'reorder failed',
          error: e, stack: s, data: {'from': from, 'to': to});
      ref.invalidateSelf();
      rethrow;
    }
  }
}
