import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/alarm.dart' as models;
import 'notification_service.dart';

class AlarmService extends ChangeNotifier {
  List<models.Alarm> _alarms = [];
  static const String _storageKey = 'alarms';
  Timer? _checkTimer;
  models.Alarm? _ringingAlarm;
  final Set<String> _triggeredToday = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingSound = false;

  List<models.Alarm> get alarms => List.unmodifiable(_alarms);
  models.Alarm? get ringingAlarm => _ringingAlarm;

  AlarmService() {
    _loadAlarms();
    _startAlarmChecker();
    _configureAudioPlayer();
  }

  void _configureAudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setVolume(1.0);
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

    // Send browser notification if on Web
    if (kIsWeb) {
      NotificationService.showNotification(
        'NextAlarm',
        '${alarm.label} - ${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}',
      );
    }

    notifyListeners();
  }

  Future<void> _playAlarmSound() async {
    if (_isPlayingSound) return;

    try {
      _isPlayingSound = true;

      // Try to play alarm sound from assets
      try {
        await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
        debugPrint('🔔 Alarm sound playing from assets');
      } catch (assetError) {
        // Fallback: Use online alarm sound if asset not available
        debugPrint('⚠️ Asset sound not found, using fallback');
        // For demo, just log the error
        debugPrint('🔔 Alarm triggered (add alarm.mp3 to assets/sounds/ for audio)');
      }
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  void stopRingingAlarm() {
    _ringingAlarm = null;
    _stopAlarmSound();
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

    notifyListeners();
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = _alarms
        .map((alarm) => jsonEncode(alarm.toJson()))
        .toList();

    await prefs.setStringList(_storageKey, alarmsJson);
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
      notifyListeners();
    }
  }

  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((alarm) => alarm.id == id);
    await _saveAlarms();
    notifyListeners();
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alarms[index] = _alarms[index].copyWith(
        isEnabled: !_alarms[index].isEnabled,
      );
      await _saveAlarms();
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
