import '../../domain/entities/alarm_entity.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../datasources/alarm_local_datasource.dart';
import '../models/alarm_model.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  final AlarmLocalDatasource _datasource;
  AlarmRepositoryImpl(this._datasource);

  @override
  Future<List<AlarmEntity>> getAllAlarms() async {
    final models = await _datasource.getAllAlarms();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<AlarmEntity?> getAlarmById(int id) async {
    final model = await _datasource.getAlarmById(id);
    return model?.toEntity();
  }

  @override
  Future<int> createAlarm(AlarmEntity alarm) {
    return _datasource.putAlarm(AlarmModel.fromEntity(alarm));
  }

  @override
  Future<void> updateAlarm(AlarmEntity alarm) async {
    await _datasource.putAlarm(AlarmModel.fromEntity(alarm));
  }

  @override
  Future<void> deleteAlarm(int id) => _datasource.deleteAlarm(id);

  @override
  Future<void> toggleEnabled(int id) async {
    final model = await _datasource.getAlarmById(id);
    if (model == null) return;
    model.isEnabled = !model.isEnabled;
    await _datasource.putAlarm(model);
  }
}
