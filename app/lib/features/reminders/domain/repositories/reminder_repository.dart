import '../entities/reminder.dart';

abstract interface class ReminderRepository {
  Future<List<Reminder>> getAllReminders();
  Future<List<Reminder>> getUpcomingReminders();
  Future<Reminder?> getReminderById(int id);
  Future<int> createReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(int id);
  Future<void> markTriggered(int id);
  Future<void> snooze(int id, Duration duration);
}
