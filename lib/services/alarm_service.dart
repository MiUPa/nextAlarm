import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm.dart' as models;
import 'notification_service.dart';

/// Global notification plugin instance (shared with main.dart)
final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Static callback for AndroidAlarmManager - triggers the alarm
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  debugPrint('🔔 Alarm callback triggered for ID: $id');

  // Show full-screen notification to wake up the device
  await _showFullScreenAlarmNotification(id);
}

/// Show a full-screen notification that wakes the device
Future<void> _showFullScreenAlarmNotification(int alarmId) async {
  const androidDetails = AndroidNotificationDetails(
    'alarm_channel',
    'Alarm Notifications',
    channelDescription: 'Notifications for alarms',
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    playSound: false, // We handle sound separately
    enableVibration: true,
    ongoing: true,
    autoCancel: false,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);

  await _notificationsPlugin.show(
    alarmId,
    'Alarm',
    'Wake up!',
    notificationDetails,
    payload: alarmId.toString(),
  );
}

class AlarmService extends ChangeNotifier {
  List<models.Alarm> _alarms = [];
  static const String _storageKey = 'alarms';
  Timer? _checkTimer;
  Timer? _volumeTimer;
  models.Alarm? _ringingAlarm;
  final Set<String> _triggeredToday = {};
  bool _isPlayingSound = false;
  double _currentVolume = 1.0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<models.Alarm> get alarms => List.unmodifiable(_alarms);
  models.Alarm? get ringingAlarm => _ringingAlarm;

  AlarmService() {
    _loadAlarms();
    _startAlarmChecker();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startAlarmChecker() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    final now = DateTime.now();
    final currentMinute = '${now.hour}:${now.minute}';

    for (final alarm in _alarms) {
      if (!alarm.isEnabled) continue;
      if (_ringingAlarm != null) continue; // Only one alarm at a time

      final alarmMinute = '${alarm.time.hour}:${alarm.time.minute}';
      final alarmKey = '${alarm.id}_$currentMinute';

      // Check if this is the right time and not triggered yet today
      if (alarmMinute == currentMinute && !_triggeredToday.contains(alarmKey)) {
        // Check if today matches repeat days
        if (alarm.repeatDays.isEmpty || alarm.repeatDays.contains(now.weekday)) {
          _triggerAlarm(alarm);
          _triggeredToday.add(alarmKey);

          // Clean up old entries
          if (_triggeredToday.length > 100) {
            _triggeredToday.clear();
          }
        }
      }
    }
  }

  void _triggerAlarm(models.Alarm alarm) {
    _ringingAlarm = alarm;
    _playAlarmSound();
    _startVibration(alarm);

    // Send browser notification if on Web
    if (kIsWeb) {
      NotificationService.showNotification(
        'NextAlarm',
        '${alarm.label} - ${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}',
      );
    }

    notifyListeners();
  }

  Timer? _vibrationTimer;

  void _startVibration(models.Alarm alarm) {
    if (!alarm.vibrate) return;

    // Vibrate in a pattern: 500ms on, 1000ms off
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_ringingAlarm != null && _ringingAlarm!.vibrate) {
        Vibration.vibrate(duration: 500);
      } else {
        timer.cancel();
      }
    });
    // Initial vibration
    Vibration.vibrate(duration: 500);
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    Vibration.cancel();
  }

  /// Trigger alarm externally (e.g., from notification callback)
  void triggerAlarmById(String alarmId) {
    final alarm = getAlarm(alarmId);
    if (alarm != null) {
      _triggerAlarm(alarm);
    }
  }

  /// Map AlarmSound enum to asset file name
  String? _getSoundAsset(models.AlarmSound sound) {
    switch (sound) {
      case models.AlarmSound.defaultAlarm:
        return 'alarm_default.wav';
      case models.AlarmSound.gentle:
        return 'alarm_gentle.wav';
      case models.AlarmSound.digital:
        return 'alarm_digital.wav';
      case models.AlarmSound.classic:
        return 'alarm_classic.wav';
      case models.AlarmSound.nature:
        return 'alarm_nature.wav';
      case models.AlarmSound.silent:
        return null;
    }
  }

  Future<void> _playAlarmSound() async {
    if (_isPlayingSound) return;

    try {
      final sound = _ringingAlarm?.sound ?? models.AlarmSound.defaultAlarm;

      // Silent mode: no sound playback
      if (sound == models.AlarmSound.silent) {
        debugPrint('🔇 Alarm sound: silent mode');
        return;
      }

      _isPlayingSound = true;
      final useGradualVolume = _ringingAlarm?.gradualVolume ?? false;

      // Set initial volume based on gradual volume setting
      if (useGradualVolume) {
        _currentVolume = 0.1;
        _startGradualVolumeIncrease();
      } else {
        _currentVolume = 1.0;
      }

      // Configure AudioPlayer for continuous looping
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_currentVolume);

      // Play the alarm sound asset
      final asset = _getSoundAsset(sound);
      if (asset != null) {
        await _audioPlayer.play(AssetSource('sounds/$asset'));
      }

      debugPrint('🔔 Playing alarm sound: ${sound.name} (volume: $_currentVolume)');
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  void _startGradualVolumeIncrease() {
    _volumeTimer?.cancel();
    // Increase volume every 5 seconds until max (no stop/restart needed)
    _volumeTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_currentVolume < 1.0 && _isPlayingSound) {
        _currentVolume = (_currentVolume + 0.15).clamp(0.0, 1.0);
        await _audioPlayer.setVolume(_currentVolume);
        debugPrint('🔊 Volume increased to: $_currentVolume');
      } else {
        timer.cancel();
      }
    });
  }

  void stopRingingAlarm() {
    // Cancel the notification
    if (_ringingAlarm != null) {
      final notificationId = _ringingAlarm!.id.hashCode.abs() % 2147483647;
      _notificationsPlugin.cancel(notificationId);
    }

    _ringingAlarm = null;
    _stopAlarmSound();
    _stopVibration();
    _volumeTimer?.cancel();
    _volumeTimer = null;
    notifyListeners();
  }

  Future<void> _stopAlarmSound() async {
    if (_isPlayingSound) {
      await _audioPlayer.stop();
      _isPlayingSound = false;
      debugPrint('🔇 Alarm sound stopped');
    }
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList(_storageKey) ?? [];

    _alarms = alarmsJson
        .map((json) => models.Alarm.fromJson(jsonDecode(json)))
        .toList();

    // Sort by time
    _alarms.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });

    // Re-schedule all enabled alarms
    for (final alarm in _alarms) {
      if (alarm.isEnabled) {
        await _scheduleBackgroundAlarm(alarm);
      }
    }

    notifyListeners();
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = _alarms
        .map((alarm) => jsonEncode(alarm.toJson()))
        .toList();

    await prefs.setStringList(_storageKey, alarmsJson);
  }

  /// Schedule a background alarm using AndroidAlarmManager
  Future<void> _scheduleBackgroundAlarm(models.Alarm alarm) async {
    if (kIsWeb) return;

    final nextTime = calculateNextAlarmTime(alarm);
    final alarmId = alarm.id.hashCode.abs() % 2147483647; // Ensure positive int

    try {
      // Cancel existing alarm first
      await AndroidAlarmManager.cancel(alarmId);

      // Schedule new alarm
      await AndroidAlarmManager.oneShotAt(
        nextTime,
        alarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true,
      );

      debugPrint('⏰ Scheduled alarm ${alarm.id} for $nextTime (ID: $alarmId)');
    } catch (e) {
      debugPrint('Error scheduling background alarm: $e');
    }
  }

  /// Cancel a background alarm
  Future<void> _cancelBackgroundAlarm(models.Alarm alarm) async {
    if (kIsWeb) return;

    final alarmId = alarm.id.hashCode.abs() % 2147483647;
    try {
      await AndroidAlarmManager.cancel(alarmId);
      debugPrint('⏰ Cancelled alarm ${alarm.id} (ID: $alarmId)');
    } catch (e) {
      debugPrint('Error cancelling background alarm: $e');
    }
  }

  Future<void> addAlarm(models.Alarm alarm) async {
    _alarms.add(alarm);

    // Sort by time
    _alarms.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });

    await _saveAlarms();

    // Schedule background alarm if enabled
    if (alarm.isEnabled) {
      await _scheduleBackgroundAlarm(alarm);
    }

    notifyListeners();
  }

  Future<void> updateAlarm(models.Alarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      final oldAlarm = _alarms[index];
      _alarms[index] = alarm;

      // Re-sort after update
      _alarms.sort((a, b) {
        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });

      await _saveAlarms();

      // Update background alarm
      await _cancelBackgroundAlarm(oldAlarm);
      if (alarm.isEnabled) {
        await _scheduleBackgroundAlarm(alarm);
      }

      notifyListeners();
    }
  }

  Future<void> deleteAlarm(String id) async {
    final alarm = getAlarm(id);
    if (alarm != null) {
      await _cancelBackgroundAlarm(alarm);
    }

    _alarms.removeWhere((alarm) => alarm.id == id);
    await _saveAlarms();
    notifyListeners();
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final oldAlarm = _alarms[index];
      _alarms[index] = _alarms[index].copyWith(
        isEnabled: !_alarms[index].isEnabled,
      );
      await _saveAlarms();

      // Update background alarm
      if (_alarms[index].isEnabled) {
        await _scheduleBackgroundAlarm(_alarms[index]);
      } else {
        await _cancelBackgroundAlarm(oldAlarm);
      }

      notifyListeners();
    }
  }

  models.Alarm? getAlarm(String id) {
    try {
      return _alarms.firstWhere((alarm) => alarm.id == id);
    } catch (e) {
      return null;
    }
  }

  DateTime calculateNextAlarmTime(models.Alarm alarm) {
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // If alarm time has passed today, move to tomorrow
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    // If alarm has repeat days, find next occurrence
    if (alarm.repeatDays.isNotEmpty) {
      while (!alarm.repeatDays.contains(next.weekday)) {
        next = next.add(const Duration(days: 1));
      }
    }

    return next;
  }

  String getTimeUntilAlarm(models.Alarm alarm) {
    if (!alarm.isEnabled) {
      return '';
    }

    final next = calculateNextAlarmTime(alarm);
    final diff = next.difference(DateTime.now());

    if (diff.inHours > 24) {
      final days = diff.inDays;
      return 'in $days ${days == 1 ? 'day' : 'days'}';
    }

    if (diff.inHours > 0) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (minutes > 0) {
        return 'in ${hours}h ${minutes}m';
      }
      return 'in $hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    final minutes = diff.inMinutes;
    return 'in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
  }
}
