import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  models.Alarm? _ringingAlarm;
  final Set<String> _triggeredToday = {};
  bool _isPlayingSound = false;

  List<models.Alarm> get alarms => List.unmodifiable(_alarms);
  models.Alarm? get ringingAlarm => _ringingAlarm;

  AlarmService() {
    _loadAlarms();
    _startAlarmChecker();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
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

    // Send browser notification if on Web
    if (kIsWeb) {
      NotificationService.showNotification(
        'NextAlarm',
        '${alarm.label} - ${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}',
      );
    }

    notifyListeners();
  }

  /// Trigger alarm externally (e.g., from notification callback)
  void triggerAlarmById(String alarmId) {
    final alarm = getAlarm(alarmId);
    if (alarm != null) {
      _triggerAlarm(alarm);
    }
  }

  Future<void> _playAlarmSound() async {
    if (_isPlayingSound) return;

    try {
      _isPlayingSound = true;

      // Play system alarm sound using STREAM_ALARM volume
      await FlutterRingtonePlayer().play(
        android: AndroidSounds.alarm,
        ios: const IosSound(1023), // iOS Alert sound
        looping: true,
        volume: 1.0,
        asAlarm: true, // Use alarm volume stream instead of media volume
      );
      debugPrint('🔔 Playing system alarm sound');
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  void stopRingingAlarm() {
    // Cancel the notification
    if (_ringingAlarm != null) {
      final notificationId = _ringingAlarm!.id.hashCode.abs() % 2147483647;
      _notificationsPlugin.cancel(notificationId);
    }

    _ringingAlarm = null;
    _stopAlarmSound();
    notifyListeners();
  }

  Future<void> _stopAlarmSound() async {
    if (_isPlayingSound) {
      await FlutterRingtonePlayer().stop();
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
