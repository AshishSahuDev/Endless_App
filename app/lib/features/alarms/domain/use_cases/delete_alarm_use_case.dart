import '../repositories/alarm_repository.dart';
import '../../../../core/services/alarm_service.dart';

class DeleteAlarmUseCase {
  final AlarmRepository _repository;
  final AlarmService _alarmService;
  const DeleteAlarmUseCase(this._repository, this._alarmService);

  Future<void> call(int id) async {
    await _alarmService.stopAlarm(id);
    await _repository.deleteAlarm(id);
  }
}
