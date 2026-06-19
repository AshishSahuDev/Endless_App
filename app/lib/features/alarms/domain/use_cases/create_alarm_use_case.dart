import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/services/app_logger.dart';

class CreateAlarmUseCase {
  final AlarmRepository _repository;
  final AlarmService _alarmService;
  const CreateAlarmUseCase(this._repository, this._alarmService);

  Future<int> call(AlarmEntity alarm) async {
    final id = await _repository.createAlarm(alarm);
    final created = alarm.copyWith(id: id);
    AppLogger.I.action('alarm', 'create',
        data: {'id': id, 'hour': alarm.hour, 'minute': alarm.minute, 'enabled': alarm.isEnabled});
    if (created.isEnabled) {
      try {
        await _alarmService.scheduleAlarm(created);
      } catch (e, s) {
        AppLogger.I.error('alarm', 'scheduleAlarm failed',
            error: e, stack: s, data: {'id': id});
        rethrow;
      }
    }
    return id;
  }
}
