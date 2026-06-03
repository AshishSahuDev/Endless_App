import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/notes/data/models/note_model.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/reminders/data/models/reminder_model.dart';
import '../../features/alarms/data/models/alarm_model.dart';
import '../../features/money/data/models/transaction_model.dart';
import '../../features/money/data/models/category_model.dart';
import '../../features/money/data/models/savings_goal_model.dart';

class IsarService {
  late final Isar _isar;

  Isar get isar => _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        NoteModelSchema,
        TaskModelSchema,
        ReminderModelSchema,
        AlarmModelSchema,
        TransactionModelSchema,
        CategoryModelSchema,
        SavingsGoalModelSchema,
      ],
      directory: dir.path,
    );
  }

  Future<void> close() async {
    await _isar.close();
  }
}
