import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';
import '../../../../core/services/alarm_service.dart';

class CreateAlarmUseCase {
  final AlarmRepository _repository;
  final AlarmService _alarmService;
  const CreateAlarmUseCase(this._repository, this._alarmService);

  Future<int> call(AlarmEntity alarm) async {
    final id = await _repository.createAlarm(alarm);
    final created = alarm.copyWith(id: id);
    if (created.isEnabled) {
      await _alarmService.scheduleAlarm(created);
    }
    return id;
  }
}
