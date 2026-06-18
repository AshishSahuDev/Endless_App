import 'package:isar/isar.dart';
import '../../domain/entities/alarm_entity.dart';

part 'alarm_model.g.dart';

@collection
class AlarmModel {
  Id id = Isar.autoIncrement;

  late String label;
  late int hour;
  late int minute;
  bool isEnabled = true;
  int repeatDays = 0;
  String soundAsset = 'assets/sounds/alarm_default.mp3';
  late DateTime createdAt;

  AlarmEntity toEntity() => AlarmEntity(
        id: id,
        label: label,
        hour: hour,
        minute: minute,
        isEnabled: isEnabled,
        repeatDays: repeatDays,
        soundAsset: soundAsset,
        createdAt: createdAt,
      );

  static AlarmModel fromEntity(AlarmEntity a) => AlarmModel()
    ..id = a.id
    ..label = a.label
    ..hour = a.hour
    ..minute = a.minute
    ..isEnabled = a.isEnabled
    ..repeatDays = a.repeatDays
    ..soundAsset = a.soundAsset
    ..createdAt = a.createdAt;
}
