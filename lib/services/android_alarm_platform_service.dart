import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/alarm.dart' as models;

class AndroidAlarmDebugInfo {
  const AndroidAlarmDebugInfo({
    required this.manufacturer,
    required this.lastLaunchSource,
    required this.lastLaunchAt,
    required this.lastLaunchAlarmId,
  });

  final String manufacturer;
  final String? lastLaunchSource;
  final DateTime? lastLaunchAt;
  final String? lastLaunchAlarmId;
}

class AndroidAlarmPlatformService {
  static const MethodChannel _channel = MethodChannel(
    'next_alarm/android_alarm',
  );
  static const String sourceServiceDirect = 'service_direct';
  static const String sourceAppForeground = 'app_foreground';
  static const String sourceNotificationFullscreen = 'notification_fullscreen';
  static const String sourceNotificationTap = 'notification_tap';
  static const String sourceNotificationAction = 'notification_action';
  static const String sourceNotificationOnly = 'notification_only';

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

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

  static Future<void> syncAlarmSettings({int? silenceAfterMinutes}) async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('syncAlarmSettings', {
      'silenceAfterMinutes': silenceAfterMinutes,
    });
  }

  static Future<String?> consumePendingRingingAlarmId() async {
    if (!_isAndroid) return null;
    final alarmId = await _channel.invokeMethod<String>(
      'consumePendingRingingAlarmId',
    );
    if (alarmId == null || alarmId.isEmpty) return null;
    return alarmId;
  }

  static Future<AndroidAlarmDebugInfo?> getAlarmDebugInfo() async {
    if (!_isAndroid) return null;
    final info = await _channel.invokeMapMethod<String, dynamic>(
      'getAlarmDebugInfo',
    );
    if (info == null) return null;

    final lastLaunchAtMs = info['lastLaunchAtMs'];
    return AndroidAlarmDebugInfo(
      manufacturer: (info['manufacturer'] as String?) ?? 'Android',
      lastLaunchSource: info['lastLaunchSource'] as String?,
      lastLaunchAt: lastLaunchAtMs is int
          ? DateTime.fromMillisecondsSinceEpoch(lastLaunchAtMs)
          : null,
      lastLaunchAlarmId: info['lastLaunchAlarmId'] as String?,
    );
  }

  static Future<void> markAlarmLaunchSource(
    String source, {
    String? alarmId,
  }) async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('markAlarmLaunchSource', {
      'source': source,
      'alarmId': alarmId,
    });
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

  static Future<bool> canUseFullScreenIntent() async {
    if (!_isAndroid) return true;
    return (await _channel.invokeMethod<bool>('canUseFullScreenIntent')) ??
        false;
  }

  static Future<bool> openFullScreenIntentSettings() async {
    if (!_isAndroid) return false;
    return (await _channel.invokeMethod<bool>(
          'openFullScreenIntentSettings',
        )) ??
        false;
  }

  static Future<bool> areNotificationsEnabled() async {
    if (!_isAndroid) return true;
    return (await _channel.invokeMethod<bool>('areNotificationsEnabled')) ??
        false;
  }

  static Future<bool> openNotificationSettings() async {
    if (!_isAndroid) return false;
    return (await _channel.invokeMethod<bool>('openNotificationSettings')) ??
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
}
