import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VolumeButtonBehavior {
  stop,
  adjustVolume,
  nothing,
}

enum StartWeekOn {
  sunday,
  monday,
  saturday,
}

class AlarmSettingsService extends ChangeNotifier {
  static const _keySilenceAfter = 'settings_silence_after_minutes';
  static const _keyAlarmVolume = 'settings_alarm_volume';
  static const _keyGraduallyIncreaseVolume =
      'settings_gradually_increase_volume_seconds';
  static const _keyVolumeButtonBehavior = 'settings_volume_button_behavior';
  static const _keyStartWeekOn = 'settings_start_week_on';

  int _silenceAfterMinutes = 5;
  double _alarmVolume = 0.8;
  int _graduallyIncreaseVolumeSeconds = 30;
  VolumeButtonBehavior _volumeButtonBehavior = VolumeButtonBehavior.stop;
  StartWeekOn _startWeekOn = StartWeekOn.monday;

  int get silenceAfterMinutes => _silenceAfterMinutes;
  double get alarmVolume => _alarmVolume;
  int get graduallyIncreaseVolumeSeconds => _graduallyIncreaseVolumeSeconds;
  VolumeButtonBehavior get volumeButtonBehavior => _volumeButtonBehavior;
  StartWeekOn get startWeekOn => _startWeekOn;

  AlarmSettingsService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _silenceAfterMinutes = prefs.getInt(_keySilenceAfter) ?? 5;
    _alarmVolume = prefs.getDouble(_keyAlarmVolume) ?? 0.8;
    _graduallyIncreaseVolumeSeconds =
        prefs.getInt(_keyGraduallyIncreaseVolume) ?? 30;
    _volumeButtonBehavior = VolumeButtonBehavior.values[
        prefs.getInt(_keyVolumeButtonBehavior) ?? VolumeButtonBehavior.stop.index];
    _startWeekOn = StartWeekOn
        .values[prefs.getInt(_keyStartWeekOn) ?? StartWeekOn.monday.index];
    notifyListeners();
  }

  Future<void> setSilenceAfterMinutes(int value) async {
    _silenceAfterMinutes = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySilenceAfter, value);
  }

  Future<void> setAlarmVolume(double value) async {
    _alarmVolume = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyAlarmVolume, value);
  }

  Future<void> setGraduallyIncreaseVolumeSeconds(int value) async {
    _graduallyIncreaseVolumeSeconds = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGraduallyIncreaseVolume, value);
  }

  Future<void> setVolumeButtonBehavior(VolumeButtonBehavior value) async {
    _volumeButtonBehavior = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyVolumeButtonBehavior, value.index);
  }

  Future<void> setStartWeekOn(StartWeekOn value) async {
    _startWeekOn = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStartWeekOn, value.index);
  }

  /// Whether the stop volume button should work for the given alarm.
  /// When a wake-up challenge is set, stop via volume button is disabled.
  bool canStopWithVolumeButton(dynamic alarm) {
    if (_volumeButtonBehavior != VolumeButtonBehavior.stop) return false;
    // If the alarm has a challenge set (not 'none'), stop is disabled
    if (alarm.challenge != null && alarm.challenge.toString().contains('none') == false) {
      return false;
    }
    return true;
  }
}
