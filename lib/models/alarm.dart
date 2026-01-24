import 'package:uuid/uuid.dart';

enum WakeUpChallenge {
  none,
  math,
  voiceRecognition,
  shake,
  steps,
}

class Alarm {
  final String id;
  final TimeOfDay time;
  final String label;
  final bool isEnabled;
  final Set<int> repeatDays; // 1-7 (Monday-Sunday)
  final WakeUpChallenge challenge;
  final int challengeDifficulty; // 1-5
  final String? challengeData; // QR code data, phrase for voice, etc.
  final bool vibrate;
  final bool gradualVolume; // Gradually increase volume
  final String? soundPath;
  final int snoozeMinutes;
  final DateTime? nextAlarmTime;

  Alarm({
    String? id,
    required this.time,
    this.label = '',
    this.isEnabled = true,
    this.repeatDays = const {},
    this.challenge = WakeUpChallenge.none,
    this.challengeDifficulty = 3,
    this.challengeData,
    this.vibrate = true,
    this.gradualVolume = false,
    this.soundPath,
    this.snoozeMinutes = 5,
    this.nextAlarmTime,
  }) : id = id ?? const Uuid().v4();

  Alarm copyWith({
    TimeOfDay? time,
    String? label,
    bool? isEnabled,
    Set<int>? repeatDays,
    WakeUpChallenge? challenge,
    int? challengeDifficulty,
    String? challengeData,
    bool? vibrate,
    bool? gradualVolume,
    String? soundPath,
    int? snoozeMinutes,
    DateTime? nextAlarmTime,
  }) {
    return Alarm(
      id: id,
      time: time ?? this.time,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      challenge: challenge ?? this.challenge,
      challengeDifficulty: challengeDifficulty ?? this.challengeDifficulty,
      challengeData: challengeData ?? this.challengeData,
      vibrate: vibrate ?? this.vibrate,
      gradualVolume: gradualVolume ?? this.gradualVolume,
      soundPath: soundPath ?? this.soundPath,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      nextAlarmTime: nextAlarmTime ?? this.nextAlarmTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'label': label,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays.toList(),
      'challenge': challenge.index,
      'challengeDifficulty': challengeDifficulty,
      'challengeData': challengeData,
      'vibrate': vibrate,
      'gradualVolume': gradualVolume,
      'soundPath': soundPath,
      'snoozeMinutes': snoozeMinutes,
      'nextAlarmTime': nextAlarmTime?.toIso8601String(),
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      label: json['label'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
      repeatDays: Set<int>.from(json['repeatDays'] ?? []),
      challenge: WakeUpChallenge.values[json['challenge'] ?? 0],
      challengeDifficulty: json['challengeDifficulty'] ?? 3,
      challengeData: json['challengeData'],
      vibrate: json['vibrate'] ?? true,
      gradualVolume: json['gradualVolume'] ?? false,
      soundPath: json['soundPath'],
      snoozeMinutes: json['snoozeMinutes'] ?? 5,
      nextAlarmTime: json['nextAlarmTime'] != null
          ? DateTime.parse(json['nextAlarmTime'])
          : null,
    );
  }

  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get repeatText {
    if (repeatDays.isEmpty) {
      return 'One time';
    }

    if (repeatDays.length == 7) {
      return 'Every day';
    }

    if (repeatDays.length == 5 &&
        !repeatDays.contains(6) &&
        !repeatDays.contains(7)) {
      return 'Weekdays';
    }

    if (repeatDays.length == 2 &&
        repeatDays.contains(6) &&
        repeatDays.contains(7)) {
      return 'Weekends';
    }

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => days[d - 1]).join(', ');
  }

  String get challengeText {
    switch (challenge) {
      case WakeUpChallenge.none:
        return 'No challenge';
      case WakeUpChallenge.math:
        return 'Math problem';
      case WakeUpChallenge.voiceRecognition:
        return 'Voice recognition';
      case WakeUpChallenge.shake:
        return 'Shake phone';
      case WakeUpChallenge.steps:
        return 'Walk steps';
    }
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() => '$hour:$minute';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay &&
      other.hour == hour &&
      other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}
