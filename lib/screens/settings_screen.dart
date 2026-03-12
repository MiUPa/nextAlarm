import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/android_alarm_platform_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeService = context.watch<LocaleService>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            l10n.language,
            _LanguageSelector(
              currentLocale: localeService.locale,
              onChanged: (locale) {
                localeService.setLocale(locale);
              },
            ),
          ),
          const _AndroidAlarmReliabilitySection(),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.onSurfaceSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AndroidAlarmReliabilitySection extends StatefulWidget {
  const _AndroidAlarmReliabilitySection();

  @override
  State<_AndroidAlarmReliabilitySection> createState() =>
      _AndroidAlarmReliabilitySectionState();
}

class _AndroidAlarmReliabilitySectionState
    extends State<_AndroidAlarmReliabilitySection> {
  bool? _canScheduleExactAlarms;
  bool? _notificationsEnabled;
  bool? _canUseFullScreenIntent;
  bool? _ignoringBatteryOptimization;
  AndroidAlarmDebugInfo? _debugInfo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      AndroidAlarmPlatformService.canScheduleExactAlarms(),
      AndroidAlarmPlatformService.areNotificationsEnabled(),
      AndroidAlarmPlatformService.canUseFullScreenIntent(),
      AndroidAlarmPlatformService.isIgnoringBatteryOptimizations(),
      AndroidAlarmPlatformService.getAlarmDebugInfo(),
    ]);
    if (!mounted) return;
    setState(() {
      _canScheduleExactAlarms = results[0] as bool;
      _notificationsEnabled = results[1] as bool;
      _canUseFullScreenIntent = results[2] as bool;
      _ignoringBatteryOptimization = results[3] as bool;
      _debugInfo = results[4] as AndroidAlarmDebugInfo?;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final oemGuide = _buildOemGuide(_debugInfo?.manufacturer);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Alarm Reliability (Android)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.onSurfaceSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (_loading)
          const ListTile(title: Text('Checking alarm settings...'))
        else ...[
          ListTile(
            title: const Text(
              'Exact alarm permission',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            subtitle: Text(
              (_canScheduleExactAlarms ?? false)
                  ? 'Allowed'
                  : 'Not allowed. Alarms may be delayed.',
              style: TextStyle(
                color: (_canScheduleExactAlarms ?? false)
                    ? AppTheme.onSurfaceSecondary
                    : AppTheme.warning,
              ),
            ),
            trailing: TextButton(
              onPressed: () async {
                await AndroidAlarmPlatformService.openExactAlarmSettings();
                await _refreshStatus();
              },
              child: const Text('Open'),
            ),
          ),
          ListTile(
            title: const Text(
              'Battery optimization',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            subtitle: Text(
              (_ignoringBatteryOptimization ?? false)
                  ? 'Excluded'
                  : 'Optimized by system. Alarm reliability can drop.',
              style: TextStyle(
                color: (_ignoringBatteryOptimization ?? false)
                    ? AppTheme.onSurfaceSecondary
                    : AppTheme.warning,
              ),
            ),
            trailing: TextButton(
              onPressed: () async {
                await AndroidAlarmPlatformService.openBatteryOptimizationSettings();
                await _refreshStatus();
              },
              child: const Text('Open'),
            ),
          ),
          ListTile(
            title: const Text(
              'Notification permission',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            subtitle: Text(
              (_notificationsEnabled ?? false)
                  ? 'Allowed'
                  : 'Not allowed. Alarm notifications may not appear.',
              style: TextStyle(
                color: (_notificationsEnabled ?? false)
                    ? AppTheme.onSurfaceSecondary
                    : AppTheme.warning,
              ),
            ),
            trailing: TextButton(
              onPressed: () async {
                await AndroidAlarmPlatformService.openNotificationSettings();
                await _refreshStatus();
              },
              child: const Text('Open'),
            ),
          ),
          ListTile(
            title: const Text(
              'Full-screen alarm display',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            subtitle: Text(
              (_canUseFullScreenIntent ?? false)
                  ? 'Allowed'
                  : 'Not allowed. Lock-screen takeover may be blocked; use the alarm notification to open the screen.',
              style: TextStyle(
                color: (_canUseFullScreenIntent ?? false)
                    ? AppTheme.onSurfaceSecondary
                    : AppTheme.warning,
              ),
            ),
            trailing: TextButton(
              onPressed: () async {
                await AndroidAlarmPlatformService.openFullScreenIntentSettings();
                await _refreshStatus();
              },
              child: const Text('Open'),
            ),
          ),
          const ListTile(
            title: Text(
              'Android 13+ behavior',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            subtitle: Text(
              'While you are actively using the device, Android may show a heads-up alarm notification instead of switching to full screen.',
              style: TextStyle(color: AppTheme.onSurfaceSecondary),
            ),
          ),
          ListTile(
            title: const Text(
              'Last alarm display path',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            subtitle: Text(
              _formatLaunchSummary(_debugInfo),
              style: const TextStyle(color: AppTheme.onSurfaceSecondary),
            ),
          ),
          if (oemGuide != null) ...[
            ListTile(
              title: Text(
                'Recommended checks for ${oemGuide.deviceLabel}',
                style: const TextStyle(color: AppTheme.onSurface),
              ),
              subtitle: Text(
                oemGuide.summary,
                style: const TextStyle(color: AppTheme.onSurfaceSecondary),
              ),
            ),
            ...oemGuide.steps.map(
              (step) => ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -3),
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.primary,
                  size: 18,
                ),
                title: Text(
                  step,
                  style: const TextStyle(color: AppTheme.onSurfaceSecondary),
                ),
              ),
            ),
          ],
          const ListTile(
            title: Text(
              'Force stop limitation',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            subtitle: Text(
              'If the app is force-stopped from Android settings, alarms can be '
              'canceled by the OS until the app is opened again.',
              style: TextStyle(color: AppTheme.onSurfaceSecondary),
            ),
          ),
        ],
      ],
    );
  }

  String _formatLaunchSummary(AndroidAlarmDebugInfo? info) {
    if (info == null || info.lastLaunchSource == null) {
      return 'No alarm display attempt recorded yet on this device.';
    }

    final sourceLabel = switch (info.lastLaunchSource) {
      'service_direct' => 'Direct launch while screen was off or locked',
      'app_foreground' => 'App was already open in the foreground',
      'notification_fullscreen' => 'Full-screen notification launch',
      'notification_tap' => 'Notification body tap',
      'notification_action' => 'Open alarm notification action',
      'notification_only' => 'Heads-up / notification fallback only',
      _ => info.lastLaunchSource!,
    };

    final parts = <String>[sourceLabel];
    if (info.lastLaunchAt != null) {
      parts.add('Last seen: ${_formatTimestamp(info.lastLaunchAt!)}');
    }
    if (info.lastLaunchAlarmId?.isNotEmpty ?? false) {
      parts.add('Alarm ID: ${info.lastLaunchAlarmId}');
    }
    return parts.join('\n');
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}:${twoDigits(local.second)}';
  }

  _OemGuide? _buildOemGuide(String? manufacturer) {
    final normalized = manufacturer?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;

    if (normalized.contains('samsung')) {
      return const _OemGuide(
        deviceLabel: 'Samsung',
        summary:
            'Samsung often needs battery and notification allow-lists aligned for reliable alarm takeover.',
        steps: [
          'Set Battery to Unrestricted for WakeShock.',
          'Add WakeShock to Never sleeping apps if that option exists.',
          'Confirm lock-screen notifications and full-screen alarms are allowed.',
        ],
      );
    }

    if (normalized.contains('xiaomi') ||
        normalized.contains('redmi') ||
        normalized.contains('poco')) {
      return const _OemGuide(
        deviceLabel: 'Xiaomi / Redmi / POCO',
        summary:
            'MIUI and HyperOS commonly block alarm takeovers unless background launch is explicitly allowed.',
        steps: [
          'Set Battery saver to No restrictions for WakeShock.',
          'Enable Auto-start for WakeShock if your device exposes that toggle.',
          'Allow lock-screen notifications and full-screen alarm display.',
        ],
      );
    }

    if (normalized.contains('oppo') ||
        normalized.contains('oneplus') ||
        normalized.contains('realme')) {
      return const _OemGuide(
        deviceLabel: 'OPPO / OnePlus / realme',
        summary:
            'These devices often need background activity permissions in addition to battery exclusions.',
        steps: [
          'Set Battery to Don\'t optimize or Unrestricted for WakeShock.',
          'Allow auto launch, background launch, or startup management for WakeShock.',
          'Keep notifications, floating alerts, and lock-screen alerts enabled.',
        ],
      );
    }

    if (normalized.contains('vivo') || normalized.contains('iqoo')) {
      return const _OemGuide(
        deviceLabel: 'vivo / iQOO',
        summary:
            'FuntouchOS can suppress alarm UI unless autostart and background permissions are both enabled.',
        steps: [
          'Enable Auto start for WakeShock.',
          'Disable battery optimization for WakeShock.',
          'Keep pop-up notifications and lock-screen notifications enabled.',
        ],
      );
    }

    if (normalized.contains('google')) {
      return const _OemGuide(
        deviceLabel: 'Google / Pixel',
        summary:
            'Pixels usually follow Android defaults closely, so exact alarms, notifications, and full-screen permission are the key checks.',
        steps: [
          'Keep notification permission enabled.',
          'Allow full-screen alarm display on Android 14+.',
          'Use Unrestricted battery only if alarms still miss while idle.',
        ],
      );
    }

    return const _OemGuide(
      deviceLabel: 'this Android device',
      summary:
          'If alarm UI does not appear reliably, align battery, notification, and startup permissions first.',
      steps: [
        'Disable battery optimization for WakeShock if available.',
        'Confirm notifications and full-screen alarms are allowed.',
        'Look for auto-start, background launch, or popup display settings from your device maker.',
      ],
    );
  }
}

class _OemGuide {
  const _OemGuide({
    required this.deviceLabel,
    required this.summary,
    required this.steps,
  });

  final String deviceLabel;
  final String summary;
  final List<String> steps;
}

class _LanguageSelector extends StatelessWidget {
  final Locale? currentLocale;
  final ValueChanged<Locale?> onChanged;

  const _LanguageSelector({
    required this.currentLocale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = [
      (null, l10n.languageSystem),
      (const Locale('en'), l10n.languageEnglish),
      (const Locale('ja'), l10n.languageJapanese),
    ];

    return Column(
      children: options.map((option) {
        final (locale, label) = option;
        final isSelected = currentLocale?.languageCode == locale?.languageCode;

        return ListTile(
          title: Text(
            label,
            style: TextStyle(
              color: AppTheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: AppTheme.primary)
              : null,
          onTap: () => onChanged(locale),
        );
      }).toList(),
    );
  }
}
