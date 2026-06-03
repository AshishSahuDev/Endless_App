import 'package:isar/isar.dart';

part 'alarm_model.g.dart';

@collection
class AlarmModel {
  Id id = Isar.autoIncrement;
  late String label;
  late int hour;
  late int minute;
  bool isEnabled = true;
  // repeat days: bitmask (bit 0 = Mon, bit 6 = Sun)
  int repeatDays = 0;
  String soundAsset = 'assets/sounds/alarm_default.mp3';
  late DateTime createdAt;
}
