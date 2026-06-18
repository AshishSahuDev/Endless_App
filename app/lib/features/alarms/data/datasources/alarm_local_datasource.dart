import 'package:isar/isar.dart';
import '../models/alarm_model.dart';
import '../../../../core/errors/app_exceptions.dart';

class AlarmLocalDatasource {
  final Isar _isar;
  AlarmLocalDatasource(this._isar);

  Future<List<AlarmModel>> getAllAlarms() async {
    try {
      return _isar.alarmModels.where().sortByCreatedAt().findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load alarms', cause: e);
    }
  }

  Future<AlarmModel?> getAlarmById(int id) async {
    try {
      return _isar.alarmModels.get(id);
    } on IsarError catch (e) {
      throw DatabaseException('Failed to get alarm', cause: e);
    }
  }

  Future<int> putAlarm(AlarmModel model) async {
    try {
      return _isar.writeTxn(() => _isar.alarmModels.put(model));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to save alarm', cause: e);
    }
  }

  Future<void> deleteAlarm(int id) async {
    try {
      await _isar.writeTxn(() => _isar.alarmModels.delete(id));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to delete alarm', cause: e);
    }
  }
}
