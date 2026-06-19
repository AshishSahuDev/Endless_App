import 'package:flutter_test/flutter_test.dart';
import 'package:endless/features/alarms/domain/entities/alarm_entity.dart';

AlarmEntity _alarm({int hour = 0, int minute = 0, int repeatDays = 0}) =>
    AlarmEntity(
      id: 1,
      hour: hour,
      minute: minute,
      repeatDays: repeatDays,
      createdAt: DateTime(2024, 1, 1),
    );

void main() {
  group('AlarmEntity.timeString', () {
    test('midnight → 12:00 AM', () {
      expect(_alarm(hour: 0, minute: 0).timeString, '12:00 AM');
    });

    test('noon → 12:00 PM', () {
      expect(_alarm(hour: 12, minute: 0).timeString, '12:00 PM');
    });

    test('6:05 AM', () {
      expect(_alarm(hour: 6, minute: 5).timeString, '6:05 AM');
    });

    test('13:30 → 1:30 PM', () {
      expect(_alarm(hour: 13, minute: 30).timeString, '1:30 PM');
    });

    test('23:59 → 11:59 PM', () {
      expect(_alarm(hour: 23, minute: 59).timeString, '11:59 PM');
    });

    test('pads single-digit minutes', () {
      expect(_alarm(hour: 9, minute: 3).timeString, '9:03 AM');
    });
  });

  group('AlarmEntity.repeatLabel', () {
    test('no repeat → Once', () {
      expect(_alarm(repeatDays: 0).repeatLabel, 'Once');
    });

    test('all days (0x7F) → Every day', () {
      expect(_alarm(repeatDays: 0x7F).repeatLabel, 'Every day');
    });

    test('weekdays Mon–Fri (0x1F) → Weekdays', () {
      expect(_alarm(repeatDays: 0x1F).repeatLabel, 'Weekdays');
    });

    test('weekends Sat+Sun (0x60) → Weekends', () {
      expect(_alarm(repeatDays: 0x60).repeatLabel, 'Weekends');
    });

    test('Mon+Wed+Fri (bits 0,2,4 = 0b0010101 = 0x15) → M · W · F', () {
      // bit 0=Mon, bit 2=Wed, bit 4=Fri
      expect(_alarm(repeatDays: 0x15).repeatLabel, 'M · W · F');
    });

    test('single day Tue (bit 1 = 0x02) → T', () {
      expect(_alarm(repeatDays: 0x02).repeatLabel, 'T');
    });
  });

  group('AlarmEntity.copyWith', () {
    test('changes hour and minute', () {
      final a = _alarm(hour: 7, minute: 0);
      final updated = a.copyWith(hour: 8, minute: 30);
      expect(updated.hour, 8);
      expect(updated.minute, 30);
      expect(updated.id, a.id);
    });

    test('toggles isEnabled', () {
      final a = _alarm().copyWith(isEnabled: true);
      expect(a.copyWith(isEnabled: false).isEnabled, isFalse);
    });
  });
}
