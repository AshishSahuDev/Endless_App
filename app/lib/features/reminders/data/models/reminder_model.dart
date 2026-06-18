import 'package:isar/isar.dart';
import '../../domain/entities/reminder.dart';

part 'reminder_model.g.dart';

@collection
class ReminderModel {
  Id id = Isar.autoIncrement;

  late String title;
  String? note;

  @Index()
  late DateTime reminderAt;

  // 0=none, 1=daily, 2=weekly, 3=monthly
  int recurringIndex = 0;

  bool isTriggered = false;
  late DateTime createdAt;

  Reminder toEntity() => Reminder(
        id: id,
        title: title,
        note: note,
        reminderAt: reminderAt,
        recurring: RecurringInterval.values[recurringIndex.clamp(0, 3)],
        isTriggered: isTriggered,
        createdAt: createdAt,
      );

  static ReminderModel fromEntity(Reminder r) => ReminderModel()
    ..id = r.id
    ..title = r.title
    ..note = r.note
    ..reminderAt = r.reminderAt
    ..recurringIndex = r.recurring.index
    ..isTriggered = r.isTriggered
    ..createdAt = r.createdAt;
}
