import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../data/datasources/alarm_local_datasource.dart';
import '../../data/repositories/alarm_repository_impl.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../../domain/use_cases/create_alarm_use_case.dart';
import '../../domain/use_cases/delete_alarm_use_case.dart';
import '../../domain/use_cases/toggle_alarm_use_case.dart';

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return AlarmRepositoryImpl(AlarmLocalDatasource(isar));
});

final alarmsProvider =
    AsyncNotifierProvider<AlarmsNotifier, List<AlarmEntity>>(AlarmsNotifier.new);

class AlarmsNotifier extends AsyncNotifier<List<AlarmEntity>> {
  late AlarmRepository _repository;
  late AlarmService _alarmService;

  @override
  Future<List<AlarmEntity>> build() async {
    _repository = ref.watch(alarmRepositoryProvider);
    _alarmService = ref.watch(alarmServiceProvider);
    return _repository.getAllAlarms();
  }

  Future<void> create(AlarmEntity alarm) async {
    await CreateAlarmUseCase(_repository, _alarmService)(alarm);
    ref.invalidateSelf();
  }

  Future<void> save(AlarmEntity alarm) async {
    await _alarmService.stopAlarm(alarm.id);
    await _repository.updateAlarm(alarm);
    if (alarm.isEnabled) {
      await _alarmService.scheduleAlarm(alarm);
    }
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await DeleteAlarmUseCase(_repository, _alarmService)(id);
    state = AsyncData(state.valueOrNull?.where((a) => a.id != id).toList() ?? []);
  }

  Future<void> toggle(int id) async {
    await ToggleAlarmUseCase(_repository, _alarmService)(id);
    ref.invalidateSelf();
  }
}
