import '../entities/alarm_entity.dart';

abstract interface class AlarmRepository {
  Future<List<AlarmEntity>> getAllAlarms();
  Future<AlarmEntity?> getAlarmById(int id);
  Future<int> createAlarm(AlarmEntity alarm);
  Future<void> updateAlarm(AlarmEntity alarm);
  Future<void> deleteAlarm(int id);
  Future<void> toggleEnabled(int id);
}
