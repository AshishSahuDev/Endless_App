import 'package:isar/isar.dart';
import '../models/reminder_model.dart';
import '../../../../core/errors/app_exceptions.dart';

class ReminderLocalDatasource {
  final Isar _isar;
  ReminderLocalDatasource(this._isar);

  Future<List<ReminderModel>> getAllReminders() async {
    try {
      return _isar.reminderModels.where().sortByReminderAt().findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load reminders', cause: e);
    }
  }

  Future<List<ReminderModel>> getUpcomingReminders() async {
    try {
      return _isar.reminderModels
          .filter()
          .isTriggeredEqualTo(false)
          .reminderAtGreaterThan(DateTime.now())
          .sortByReminderAt()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load upcoming reminders', cause: e);
    }
  }

  Future<ReminderModel?> getReminderById(int id) async {
    try {
      return _isar.reminderModels.get(id);
    } on IsarError catch (e) {
      throw DatabaseException('Failed to get reminder', cause: e);
    }
  }

  Future<int> putReminder(ReminderModel model) async {
    try {
      return _isar.writeTxn(() => _isar.reminderModels.put(model));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to save reminder', cause: e);
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      await _isar.writeTxn(() => _isar.reminderModels.delete(id));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to delete reminder', cause: e);
    }
  }
}
