import 'package:isar/isar.dart';

part 'reminder_model.g.dart';

@collection
class ReminderModel {
  Id id = Isar.autoIncrement;
  late String title;
  String? note;
  late DateTime reminderAt;
  bool isRecurring = false;
  int? recurringInterval; // minutes
  bool isTriggered = false;
  late DateTime createdAt;
}
