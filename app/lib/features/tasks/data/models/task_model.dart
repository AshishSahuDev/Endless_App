import 'package:isar/isar.dart';

part 'task_model.g.dart';

@collection
class TaskModel {
  Id id = Isar.autoIncrement;
  late String title;
  bool isCompleted = false;
  int priority = 0; // 0=low, 1=medium, 2=high
  DateTime? dueDate;
  late DateTime createdAt;
  late DateTime updatedAt;
}
