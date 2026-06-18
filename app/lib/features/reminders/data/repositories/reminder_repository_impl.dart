import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_local_datasource.dart';
import '../models/reminder_model.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderLocalDatasource _datasource;
  ReminderRepositoryImpl(this._datasource);

  @override
  Future<List<Reminder>> getAllReminders() async {
    final models = await _datasource.getAllReminders();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Reminder>> getUpcomingReminders() async {
    final models = await _datasource.getUpcomingReminders();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Reminder?> getReminderById(int id) async {
    final model = await _datasource.getReminderById(id);
    return model?.toEntity();
  }

  @override
  Future<int> createReminder(Reminder reminder) {
    return _datasource.putReminder(ReminderModel.fromEntity(reminder));
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    await _datasource.putReminder(ReminderModel.fromEntity(reminder));
  }

  @override
  Future<void> deleteReminder(int id) => _datasource.deleteReminder(id);

  @override
  Future<void> markTriggered(int id) async {
    final model = await _datasource.getReminderById(id);
    if (model == null) return;
    model.isTriggered = true;
    await _datasource.putReminder(model);
  }

  @override
  Future<void> snooze(int id, Duration duration) async {
    final model = await _datasource.getReminderById(id);
    if (model == null) return;
    model.reminderAt = DateTime.now().add(duration);
    model.isTriggered = false;
    await _datasource.putReminder(model);
  }
}
