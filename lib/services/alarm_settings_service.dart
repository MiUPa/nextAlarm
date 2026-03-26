import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart' as models;
import 'android_alarm_platform_service.dart';

enum AlarmWeekStart { monday, sunday }

class AlarmSettingsService extends ChangeNotifier {
  static const String _keySilenceAfterMinutes =
      'alarm_settings_silence_after_minutes';
  static const String _keyWeekStart = 'alarm_settings_week_start';
  static const String _keyDefaultSound = 'alarm_settings_default_sound';
  static const String _keyDefaultVibrate = 'alarm_settings_default_vibrate';
  static const String _keyDefaultVibrationIntensity =
      'alarm_settings_default_vibration_intensity';
  static const String _keyDefaultGradualVolume =
      'alarm_settings_default_gradual_volume';

  int? _silenceAfterMinutes;
  AlarmWeekStart _weekStart = AlarmWeekStart.monday;
  models.AlarmSound _defaultSound = models.AlarmSound.defaultAlarm;
  bool _defaultVibrate = true;
  models.VibrationIntensity _defaultVibrationIntensity =
      models.VibrationIntensity.standard;
  bool _defaultGradualVolume = false;
  bool _isLoaded = false;

  AlarmSettingsService() {
    _load();
  }

  bool get isLoaded => _isLoaded;
  int? get silenceAfterMinutes => _silenceAfterMinutes;
  AlarmWeekStart get weekStart => _weekStart;
  models.AlarmSound get defaultSound => _defaultSound;
  bool get defaultVibrate => _defaultVibrate;
  models.VibrationIntensity get defaultVibrationIntensity =>
      _defaultVibrationIntensity;
  bool get defaultGradualVolume => _defaultGradualVolume;

  Duration? get silenceAfterDuration {
    final minutes = _silenceAfterMinutes;
    if (minutes == null || minutes <= 0) return null;
    return Duration(minutes: minutes);
  }

  List<int> get weekdayOrder {
    return switch (_weekStart) {
      AlarmWeekStart.sunday => const [7, 1, 2, 3, 4, 5, 6],
      AlarmWeekStart.monday => const [1, 2, 3, 4, 5, 6, 7],
    };
  }

  List<int> orderedWeekdays(Iterable<int> days) {
    final selected = Set<int>.from(days);
    return weekdayOrder.where(selected.contains).toList(growable: false);
  }

  Future<void> setSilenceAfterMinutes(int? minutes) async {
    if (_silenceAfterMinutes == minutes) return;
    _silenceAfterMinutes = minutes;
    await _save();
  }

  Future<void> setWeekStart(AlarmWeekStart weekStart) async {
    if (_weekStart == weekStart) return;
    _weekStart = weekStart;
    await _save();
  }

  Future<void> setDefaultSound(models.AlarmSound sound) async {
    if (_defaultSound == sound) return;
    _defaultSound = sound;
    await _save();
  }

  Future<void> setDefaultVibrate(bool vibrate) async {
    if (_defaultVibrate == vibrate) return;
    _defaultVibrate = vibrate;
    await _save();
  }

  Future<void> setDefaultVibrationIntensity(
    models.VibrationIntensity intensity,
  ) async {
    if (_defaultVibrationIntensity == intensity) return;
    _defaultVibrationIntensity = intensity;
    await _save();
  }

  Future<void> setDefaultGradualVolume(bool gradualVolume) async {
    if (_defaultGradualVolume == gradualVolume) return;
    _defaultGradualVolume = gradualVolume;
    await _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final storedSilenceAfterMinutes = prefs.getInt(_keySilenceAfterMinutes);
    final storedWeekStart = prefs.getString(_keyWeekStart);
    final storedDefaultSound = prefs.getInt(_keyDefaultSound);
    final storedDefaultVibrate = prefs.getBool(_keyDefaultVibrate);
    final storedDefaultVibrationIntensity = prefs.getInt(
      _keyDefaultVibrationIntensity,
    );
    final storedDefaultGradualVolume = prefs.getBool(_keyDefaultGradualVolume);

    _silenceAfterMinutes = storedSilenceAfterMinutes;
    _weekStart = switch (storedWeekStart) {
      'sunday' => AlarmWeekStart.sunday,
      _ => AlarmWeekStart.monday,
    };
    if (storedDefaultSound != null &&
        storedDefaultSound >= 0 &&
        storedDefaultSound < models.AlarmSound.values.length) {
      _defaultSound = models.AlarmSound.values[storedDefaultSound];
    }
    if (storedDefaultVibrate != null) {
      _defaultVibrate = storedDefaultVibrate;
    }
    if (storedDefaultVibrationIntensity != null &&
        storedDefaultVibrationIntensity >= 0 &&
        storedDefaultVibrationIntensity <
            models.VibrationIntensity.values.length) {
      _defaultVibrationIntensity =
          models.VibrationIntensity.values[storedDefaultVibrationIntensity];
    }
    if (storedDefaultGradualVolume != null) {
      _defaultGradualVolume = storedDefaultGradualVolume;
    }

    _isLoaded = true;
    notifyListeners();
    await _syncPlatformSettings();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyWeekStart,
      _weekStart == AlarmWeekStart.sunday ? 'sunday' : 'monday',
    );

    final silenceAfterMinutes = _silenceAfterMinutes;
    if (silenceAfterMinutes == null || silenceAfterMinutes <= 0) {
      await prefs.remove(_keySilenceAfterMinutes);
    } else {
      await prefs.setInt(_keySilenceAfterMinutes, silenceAfterMinutes);
    }

    await prefs.setInt(_keyDefaultSound, _defaultSound.index);
    await prefs.setBool(_keyDefaultVibrate, _defaultVibrate);
    await prefs.setInt(
      _keyDefaultVibrationIntensity,
      _defaultVibrationIntensity.index,
    );
    await prefs.setBool(_keyDefaultGradualVolume, _defaultGradualVolume);

    notifyListeners();
    await _syncPlatformSettings();
  }

  Future<void> _syncPlatformSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await AndroidAlarmPlatformService.syncAlarmSettings(
      silenceAfterMinutes: _silenceAfterMinutes,
    );
  }
}
