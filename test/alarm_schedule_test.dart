import 'package:flutter_test/flutter_test.dart';
import 'package:next_alarm/models/alarm.dart';

void main() {
  group('nextAlarmDateTime', () {
    test('keeps the same day when the alarm time is still ahead', () {
      final alarm = Alarm(
        time: const TimeOfDay(hour: 7, minute: 30),
        repeatDays: const {1, 2, 3, 4, 5},
      );

      final next = nextAlarmDateTime(alarm, DateTime(2026, 3, 26, 6, 45));

      expect(next, DateTime(2026, 3, 26, 7, 30));
    });

    test('skips paused dates for recurring alarms', () {
      final alarm = Alarm(
        time: const TimeOfDay(hour: 7, minute: 30),
        repeatDays: const {1, 2, 3, 4, 5},
        pausedDates: const {'2026-03-27'},
      );

      final next = nextAlarmDateTime(alarm, DateTime(2026, 3, 26, 8, 0));

      expect(next, DateTime(2026, 3, 30, 7, 30));
    });
  });

  group('pause date helpers', () {
    test('alarmShouldTriggerOnDate returns false for paused dates', () {
      final alarm = Alarm(
        time: const TimeOfDay(hour: 7, minute: 30),
        repeatDays: const {5},
        pausedDates: const {'2026-03-27'},
      );

      expect(
        alarmShouldTriggerOnDate(alarm, DateTime(2026, 3, 27, 7, 30)),
        isFalse,
      );
      expect(
        alarmShouldTriggerOnDate(alarm, DateTime(2026, 4, 3, 7, 30)),
        isTrue,
      );
    });

    test('prunePastPausedDates removes dates before today', () {
      final alarm = Alarm(
        time: const TimeOfDay(hour: 7, minute: 30),
        pausedDates: const {'2026-03-24', '2026-03-26', '2026-03-27'},
      );

      final pruned = alarm.prunePastPausedDates(DateTime(2026, 3, 26, 10, 0));

      expect(pruned.pausedDates, {'2026-03-26', '2026-03-27'});
    });
  });
}
