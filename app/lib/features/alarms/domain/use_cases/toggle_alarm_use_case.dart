import '../repositories/alarm_repository.dart';
import '../../../../core/services/alarm_service.dart';

class ToggleAlarmUseCase {
  final AlarmRepository _repository;
  final AlarmService _alarmService;
  const ToggleAlarmUseCase(this._repository, this._alarmService);

  Future<void> call(int id) async {
    await _repository.toggleEnabled(id);
    final alarm = await _repository.getAlarmById(id);
    if (alarm == null) return;
    if (alarm.isEnabled) {
      await _alarmService.scheduleAlarm(alarm);
    } else {
      await _alarmService.stopAlarm(id);
    }
  }
}
