import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
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
    final tasks = state.valueOrNull ?? [];
    final taskWithOrder = task.copyWith(sortOrder: tasks.length);
    await CreateTaskUseCase(_repository)(taskWithOrder);
    ref.invalidateSelf();
  }

  Future<void> save(Task task) async {
    await UpdateTaskUseCase(_repository)(task);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await DeleteTaskUseCase(_repository)(id);
    state = AsyncData(state.valueOrNull?.where((t) => t.id != id).toList() ?? []);
  }

  Future<void> toggleComplete(int id) async {
    await ToggleCompleteUseCase(_repository)(id);
    ref.invalidateSelf();
  }

  Future<void> reorder(int from, int to) async {
    // Optimistic update for smooth drag animation
    final tasks = List<Task>.from(state.valueOrNull ?? []);
    if (from < 0 || to < 0 || from >= tasks.length || to >= tasks.length) return;
    final item = tasks.removeAt(from);
    tasks.insert(to, item);
    state = AsyncData(tasks);
    await ReorderTasksUseCase(_repository)(from, to);
  }
}
