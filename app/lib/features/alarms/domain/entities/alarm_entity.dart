class AlarmEntity {
  final int id;
  final String label;
  final int hour;
  final int minute;
  final bool isEnabled;
  // Repeat bitmask: bit 0 = Mon, bit 1 = Tue ... bit 6 = Sun. 0 = once only.
  final int repeatDays;
  final String soundAsset;
  final DateTime createdAt;

  const AlarmEntity({
    required this.id,
    this.label = '',
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.repeatDays = 0,
    this.soundAsset = 'assets/sounds/alarm_default.mp3',
    required this.createdAt,
  });

  AlarmEntity copyWith({
    int? id,
    String? label,
    int? hour,
    int? minute,
    bool? isEnabled,
    int? repeatDays,
    String? soundAsset,
    DateTime? createdAt,
  }) {
    return AlarmEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      soundAsset: soundAsset ?? this.soundAsset,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeString {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String get repeatLabel {
    if (repeatDays == 0) return 'Once';
    if (repeatDays == 0x7F) return 'Every day';
    if (repeatDays == 0x1F) return 'Weekdays';
    if (repeatDays == 0x60) return 'Weekends';
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final active = <String>[];
    for (int i = 0; i < 7; i++) {
      if (repeatDays & (1 << i) != 0) active.add(days[i]);
    }
    return active.join(' · ');
  }
}
