import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/alarm.dart' as models;

class AndroidAlarmPlatformService {
  static const MethodChannel _channel = MethodChannel(
    'next_alarm/android_alarm',
  );

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> syncAlarms(List<models.Alarm> alarms) async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('syncAlarms', {
      'alarms': alarms.map((alarm) => alarm.toJson()).toList(growable: false),
    });
  }

  static Future<void> rescheduleFromStorage() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('rescheduleFromStorage');
  }

  static Future<String?> consumePendingRingingAlarmId() async {
    if (!_isAndroid) return null;
    final alarmId = await _channel.invokeMethod<String>(
      'consumePendingRingingAlarmId',
    );
    if (alarmId == null || alarmId.isEmpty) return null;
    return alarmId;
  }

  static Future<bool> canScheduleExactAlarms() async {
    if (!_isAndroid) return true;
    return (await _channel.invokeMethod<bool>('canScheduleExactAlarms')) ??
        false;
  }

  static Future<bool> openExactAlarmSettings() async {
    if (!_isAndroid) return false;
    return (await _channel.invokeMethod<bool>('openExactAlarmSettings')) ??
        false;
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!_isAndroid) return true;
    return (await _channel.invokeMethod<bool>(
          'isIgnoringBatteryOptimizations',
        )) ??
        false;
  }

  static Future<bool> openBatteryOptimizationSettings() async {
    if (!_isAndroid) return false;
    return (await _channel.invokeMethod<bool>(
          'openBatteryOptimizationSettings',
        )) ??
        false;
  }

  static Future<void> stopAlarmRinging() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('stopAlarmRinging');
  }

  /// Returns the device ringer mode: "normal", "vibrate", or "silent".
  /// Returns "normal" on non-Android platforms.
  static Future<String> getRingerMode() async {
    if (!_isAndroid) return 'normal';
    return (await _channel.invokeMethod<String>('getRingerMode')) ?? 'normal';
  }
}
