import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm.dart' as models;
import 'android_alarm_platform_service.dart';
import 'app_navigation_service.dart';
import 'notification_service.dart';

class AlarmService extends ChangeNotifier {
  List<models.Alarm> _alarms = [];
  static const String _storageKey = 'alarms';
  Timer? _checkTimer;
  Timer? _volumeTimer;
  models.Alarm? _ringingAlarm;
  final Set<String> _triggeredToday = {};
  bool _isPlayingSound = false;
  bool _isPollingPlatformAlarm = false;
  double _currentVolume = 1.0;

  List<models.Alarm> get alarms => List.unmodifiable(_alarms);
  models.Alarm? get ringingAlarm => _ringingAlarm;

  bool get _useAndroidPlatformScheduler =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  AlarmService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAlarms();
    if (_useAndroidPlatformScheduler) {
      await _syncPlatformAlarms();
      await _consumePendingPlatformAlarm();
    }
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
      if (_useAndroidPlatformScheduler) {
        _consumePendingPlatformAlarm();
      } else {
        _checkAlarms();
      }
    });
  }

  Future<void> _consumePendingPlatformAlarm() async {
    if (_isPollingPlatformAlarm || _ringingAlarm != null) return;
    _isPollingPlatformAlarm = true;
    try {
      final alarmId =
          await AndroidAlarmPlatformService.consumePendingRingingAlarmId();
      if (alarmId == null) return;
      triggerAlarmById(alarmId);
    } finally {
      _isPollingPlatformAlarm = false;
    }
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
        if (alarm.repeatDays.isEmpty ||
            alarm.repeatDays.contains(now.weekday)) {
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
    AppNavigationService.popToRoot();
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
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
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
    } else if (_useAndroidPlatformScheduler) {
      AndroidAlarmPlatformService.stopAlarmRinging();
    }
  }

  Future<void> _playAlarmSound() async {
    if (_isPlayingSound) return;

    try {
      _isPlayingSound = true;

      // Get the sound type from the ringing alarm
      final sound = _ringingAlarm?.sound ?? models.AlarmSound.defaultAlarm;
      final useGradualVolume = _ringingAlarm?.gradualVolume ?? false;

      // Set initial volume based on gradual volume setting
      if (useGradualVolume) {
        _currentVolume = 0.1;
        _startGradualVolumeIncrease();
      } else {
        _currentVolume = 1.0;
      }

      // Map AlarmSound to AndroidSounds
      AndroidSound androidSound;
      IosSound iosSound;
      switch (sound) {
        case models.AlarmSound.gentle:
          androidSound = AndroidSounds.notification;
          iosSound = const IosSound(1007);
          break;
        case models.AlarmSound.digital:
          androidSound = AndroidSounds.alarm;
          iosSound = const IosSound(1005);
          break;
        case models.AlarmSound.classic:
          androidSound = AndroidSounds.ringtone;
          iosSound = const IosSound(1000);
          break;
        case models.AlarmSound.nature:
          androidSound = AndroidSounds.notification;
          iosSound = const IosSound(1013);
          break;
        case models.AlarmSound.defaultAlarm:
          androidSound = AndroidSounds.alarm;
          iosSound = const IosSound(1023);
          break;
      }

      // Play the selected alarm sound using STREAM_ALARM volume
      await FlutterRingtonePlayer().play(
        android: androidSound,
        ios: iosSound,
        looping: true,
        volume: _currentVolume,
        asAlarm: true,
      );
      debugPrint(
        '🔔 Playing alarm sound: ${sound.name} (volume: $_currentVolume)',
      );
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  void _startGradualVolumeIncrease() {
    _volumeTimer?.cancel();
    // Increase volume every 5 seconds until max
    _volumeTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_currentVolume < 1.0 && _isPlayingSound) {
        _currentVolume = (_currentVolume + 0.15).clamp(0.0, 1.0);

        // Restart with new volume
        await FlutterRingtonePlayer().stop();
        await FlutterRingtonePlayer().play(
          android: AndroidSounds.alarm,
          ios: const IosSound(1023),
          looping: true,
          volume: _currentVolume,
          asAlarm: true,
        );
        debugPrint('🔊 Volume increased to: $_currentVolume');
      } else {
        timer.cancel();
      }
    });
  }

  void stopRingingAlarm() {
    _ringingAlarm = null;
    _stopAlarmSound();
    _stopVibration();
    _volumeTimer?.cancel();
    _volumeTimer = null;
    if (_useAndroidPlatformScheduler) {
      AndroidAlarmPlatformService.stopAlarmRinging();
    }
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

    notifyListeners();
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = _alarms
        .map((alarm) => jsonEncode(alarm.toJson()))
        .toList();

    await prefs.setStringList(_storageKey, alarmsJson);
  }

  Future<void> _syncPlatformAlarms() async {
    if (!_useAndroidPlatformScheduler) return;
    final enabledAlarms = _alarms.where((alarm) => alarm.isEnabled).toList();
    await AndroidAlarmPlatformService.syncAlarms(enabledAlarms);
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
    await _syncPlatformAlarms();

    notifyListeners();
  }

  Future<void> updateAlarm(models.Alarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;

      // Re-sort after update
      _alarms.sort((a, b) {
        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });

      await _saveAlarms();
      await _syncPlatformAlarms();

      notifyListeners();
    }
  }

  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((alarm) => alarm.id == id);
    await _saveAlarms();
    await _syncPlatformAlarms();
    notifyListeners();
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alarms[index] = _alarms[index].copyWith(
        isEnabled: !_alarms[index].isEnabled,
      );
      await _saveAlarms();
      await _syncPlatformAlarms();

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
