import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm.dart' as models;
import 'android_alarm_platform_service.dart';
import 'app_navigation_service.dart';

class _PlatformAlarmSound {
  const _PlatformAlarmSound({required this.android, required this.ios});

  final AndroidSound android;
  final IosSound ios;
}

enum AlarmRingingUiStage {
  entry,
  challenge,
}

class AlarmService extends ChangeNotifier {
  List<models.Alarm> _alarms = [];
  static const String _storageKey = 'alarms';
  Timer? _checkTimer;
  Timer? _volumeTimer;
  models.Alarm? _ringingAlarm;
  AlarmRingingUiStage _ringingUiStage = AlarmRingingUiStage.entry;
  final Set<String> _triggeredToday = {};
  bool _isPlayingSound = false;
  bool _isPollingPlatformAlarm = false;
  double _currentVolume = 1.0;
  _PlatformAlarmSound? _activePlatformSound;

  List<models.Alarm> get alarms => List.unmodifiable(_alarms);
  models.Alarm? get ringingAlarm => _ringingAlarm;
  AlarmRingingUiStage get ringingUiStage => _ringingUiStage;

  bool get _useAndroidPlatformScheduler =>
      defaultTargetPlatform == TargetPlatform.android;

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
    _ringingUiStage = AlarmRingingUiStage.entry;
    AppNavigationService.popToRoot();

    if (_useAndroidPlatformScheduler) {
      // On Android, AlarmRingingService already handles sound and vibration
      // natively with proper AudioAttributes.USAGE_ALARM.
      // Do NOT start Flutter-side sound/vibration to avoid cancelling the
      // native vibrator and losing USAGE_ALARM attribution.
    } else {
      _playAlarmSound();
      _startVibration(alarm);
    }

    notifyListeners();
  }

  Timer? _vibrationTimer;

  // Maximally unpleasant ~12s vibration pattern.
  // Combines rapid bursts, irregular rhythm, fake pauses, and sudden slams.
  // Format: [wait, vibrate, wait, vibrate, ...] in milliseconds.
  static const List<int> _aggressivePattern = [
    // Phase 1: Insect-crawl opener (rapid micro-bursts) ~530ms
    0, 50, 30, 50, 30, 80, 20, 50, 30, 120, 40, 30,
    // Phase 2: Arrhythmic heartbeat ~980ms
    100, 150, 60, 100, 200, 250, 40, 80,
    // Phase 3: Fake calm — "is it over?" ~1200ms
    800, 60, 340,
    // Phase 4: SURPRISE slam out of silence ~1080ms
    0, 500, 80, 200, 100, 200,
    // Phase 5: Machine-gun staccato ~840ms
    30, 40, 30, 40, 30, 40, 30, 40, 30, 40, 30, 40, 30, 40, 30, 40, 30, 40, 30, 40,
    // Phase 6: Heavy slam + aftershock tremor ~1330ms
    80, 400, 50, 60, 30, 60, 30, 40, 30, 40, 150, 360,
    // Phase 7: Second fake calm — longer this time ~1600ms
    1200, 40, 360,
    // Phase 8: Erratic panic crescendo ~2300ms
    0, 80, 60, 120, 40, 200, 30, 300, 20, 400, 50, 500, 20, 80, 20, 80, 20, 80, 20, 80,
    // Phase 9: Final desperation — sustained max buzz ~1800ms
    100, 800, 50, 300, 50, 500,
  ];

  static const List<int> _aggressiveIntensities = [
    // Phase 1: Flickering low-high
    0, 120, 0, 200, 0, 255, 0, 100, 0, 255, 0, 180,
    // Phase 2: Pulsing strong-weak
    0, 255, 0, 128, 0, 255, 0, 200,
    // Phase 3: Fake calm — faint tickle
    0, 80, 0,
    // Phase 4: SURPRISE — full power from silence
    0, 255, 0, 255, 0, 255,
    // Phase 5: Full intensity rapid fire
    0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
    // Phase 6: Slam max, aftershock decay
    0, 255, 0, 200, 0, 160, 0, 120, 0, 100, 0, 255,
    // Phase 7: Barely there — false hope
    0, 60, 0,
    // Phase 8: Building panic — intensity ramps up
    0, 100, 0, 140, 0, 180, 0, 210, 0, 240, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
    // Phase 9: Sustained max — no escape
    0, 255, 0, 255, 0, 255,
  ];


  void _startVibration(models.Alarm alarm) {
    if (!alarm.vibrate) return;

    _vibrationTimer?.cancel();
    _fireVibrationPattern(alarm.vibrationIntensity);

    final patternDuration = _vibrationPatternDuration;
    _vibrationTimer = Timer.periodic(patternDuration, (timer) {
      if (_ringingAlarm != null && _ringingAlarm!.vibrate) {
        _fireVibrationPattern(_ringingAlarm!.vibrationIntensity);
      } else {
        timer.cancel();
      }
    });
  }

  void _fireVibrationPattern(models.VibrationIntensity vibrationIntensity) {
    final intensityScale = switch (vibrationIntensity) {
      models.VibrationIntensity.gentle => 0.4,
      models.VibrationIntensity.standard => 0.7,
      models.VibrationIntensity.aggressive => 1.0,
    };

    Vibration.vibrate(
      pattern: _aggressivePattern,
      intensities: _scaleIntensities(intensityScale),
    );
  }

  Duration get _vibrationPatternDuration => Duration(
    milliseconds: _aggressivePattern.fold(0, (sum, value) => sum + value),
  );

  List<int> _scaleIntensities(double intensityScale) {
    final base = _normalizedAggressiveIntensities;
    if (intensityScale >= 1.0) return base;

    return base.map((value) {
      if (value == 0) return 0;
      return (value * intensityScale).round().clamp(1, 255);
    }).toList(growable: false);
  }

  List<int> get _normalizedAggressiveIntensities {
    if (_aggressiveIntensities.length == _aggressivePattern.length) {
      return _aggressiveIntensities;
    }

    final normalized = List<int>.from(_aggressiveIntensities, growable: true);
    while (normalized.length < _aggressivePattern.length) {
      normalized.add(normalized.length.isEven ? 0 : 255);
    }

    if (normalized.length > _aggressivePattern.length) {
      return normalized.sublist(0, _aggressivePattern.length);
    }

    return normalized;
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

  _PlatformAlarmSound? _resolvePlatformSound(models.AlarmSound sound) {
    switch (sound) {
      case models.AlarmSound.defaultAlarm:
        return const _PlatformAlarmSound(
          android: AndroidSounds.alarm,
          ios: IosSound(1023),
        );
      case models.AlarmSound.gentle:
        return const _PlatformAlarmSound(
          android: AndroidSounds.notification,
          ios: IosSound(1007),
        );
      case models.AlarmSound.digital:
        return const _PlatformAlarmSound(
          android: AndroidSounds.alarm,
          ios: IosSound(1005),
        );
      case models.AlarmSound.classic:
        return const _PlatformAlarmSound(
          android: AndroidSounds.ringtone,
          ios: IosSound(1000),
        );
      case models.AlarmSound.nature:
        return const _PlatformAlarmSound(
          android: AndroidSounds.notification,
          ios: IosSound(1013),
        );
      case models.AlarmSound.silent:
        return null;
    }
  }

  Future<void> _playPlatformSound(
    _PlatformAlarmSound platformSound, {
    required double volume,
  }) async {
    // asAlarm=true routes through alarm audio usage so it can ring even if media is muted.
    await FlutterRingtonePlayer().play(
      android: platformSound.android,
      ios: platformSound.ios,
      looping: true,
      volume: volume,
      asAlarm: true,
    );
  }

  Future<void> _playAlarmSound() async {
    if (_isPlayingSound) return;

    try {
      final sound = _ringingAlarm?.sound ?? models.AlarmSound.defaultAlarm;
      final platformSound = _resolvePlatformSound(sound);

      // Silent mode: no sound playback
      if (platformSound == null) {
        debugPrint('🔇 Alarm sound: silent mode');
        _activePlatformSound = null;
        return;
      }

      _isPlayingSound = true;
      _activePlatformSound = platformSound;
      final useGradualVolume = _ringingAlarm?.gradualVolume ?? false;

      // Set initial volume based on gradual volume setting
      if (useGradualVolume) {
        _currentVolume = 0.1;
        _startGradualVolumeIncrease();
      } else {
        _currentVolume = 1.0;
      }

      await _playPlatformSound(platformSound, volume: _currentVolume);

      debugPrint(
        '🔔 Playing alarm sound: ${sound.name} (volume: $_currentVolume)',
      );
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
      _isPlayingSound = false;
      _activePlatformSound = null;
    }
  }

  void _startGradualVolumeIncrease() {
    _volumeTimer?.cancel();
    // Increase volume every 5 seconds until max.
    _volumeTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_currentVolume < 1.0 && _isPlayingSound) {
        final platformSound = _activePlatformSound;
        if (platformSound == null) {
          timer.cancel();
          return;
        }

        _currentVolume = (_currentVolume + 0.15).clamp(0.0, 1.0);
        // Call play() directly without stop() first to avoid audible gap.
        // FlutterRingtonePlayer replaces the current playback internally.
        await _playPlatformSound(platformSound, volume: _currentVolume);
        debugPrint('🔊 Volume increased to: $_currentVolume');
      } else {
        timer.cancel();
      }
    });
  }

  void stopRingingAlarm() {
    _ringingAlarm = null;
    _ringingUiStage = AlarmRingingUiStage.entry;
    _stopAlarmSound();
    _stopVibration();
    _volumeTimer?.cancel();
    _volumeTimer = null;
    if (_useAndroidPlatformScheduler) {
      AndroidAlarmPlatformService.stopAlarmRinging();
    }
    notifyListeners();
  }

  void beginAlarmChallenge() {
    if (_ringingAlarm == null) return;
    if (_ringingUiStage == AlarmRingingUiStage.challenge) return;
    _ringingUiStage = AlarmRingingUiStage.challenge;
    notifyListeners();
  }

  Future<void> _stopAlarmSound() async {
    if (_isPlayingSound) {
      await FlutterRingtonePlayer().stop();
      _isPlayingSound = false;
      _activePlatformSound = null;
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
