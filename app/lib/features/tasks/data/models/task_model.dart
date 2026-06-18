import 'package:isar/isar.dart';
import '../../domain/entities/task.dart';

part 'task_model.g.dart';

@collection
class TaskModel {
  Id id = Isar.autoIncrement;

  late String title;
  String? note;
  bool isCompleted = false;

  // 0=low, 1=medium, 2=high — stored as int for Isar compatibility
  int priorityIndex = 1;

  @Index()
  DateTime? dueDate;

  @Index()
  int sortOrder = 0;

  late DateTime createdAt;
  late DateTime updatedAt;

  Task toEntity() => Task(
        id: id,
        title: title,
        note: note,
        isCompleted: isCompleted,
        priority: Priority.values[priorityIndex.clamp(0, 2)],
        dueDate: dueDate,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static TaskModel fromEntity(Task task) => TaskModel()
    ..id = task.id
    ..title = task.title
    ..note = task.note
    ..isCompleted = task.isCompleted
    ..priorityIndex = task.priority.index
    ..dueDate = task.dueDate
    ..sortOrder = task.sortOrder
    ..createdAt = task.createdAt
    ..updatedAt = task.updatedAt;
}
