import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/alarm_settings_service.dart';
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
            l10n.alarmSettings,
            const _AlarmSettingsSection(),
          ),
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

class _AlarmSettingsSection extends StatelessWidget {
  const _AlarmSettingsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<AlarmSettingsService>();

    return Column(
      children: [
        // Silence after
        _SettingsTile(
          title: l10n.silenceAfter,
          value: settings.silenceAfterMinutes == 0
              ? l10n.silenceAfterNever
              : l10n.silenceAfterValue(settings.silenceAfterMinutes),
          onTap: () => _showSilenceAfterDialog(context, settings, l10n),
        ),
        // Alarm volume
        _VolumeSliderTile(
          title: l10n.alarmVolume,
          value: settings.alarmVolume,
          onChanged: (v) => settings.setAlarmVolume(v),
        ),
        // Gradually increase volume
        _SettingsTile(
          title: l10n.graduallyIncreaseVolume,
          value: settings.graduallyIncreaseVolumeSeconds == 0
              ? l10n.graduallyIncreaseVolumeOff
              : l10n.graduallyIncreaseVolumeSeconds(
                  settings.graduallyIncreaseVolumeSeconds),
          onTap: () =>
              _showGraduallyIncreaseDialog(context, settings, l10n),
        ),
        // Volume buttons
        _SettingsTile(
          title: l10n.volumeButtons,
          value: _volumeButtonLabel(settings.volumeButtonBehavior, l10n),
          onTap: () => _showVolumeButtonsDialog(context, settings, l10n),
        ),
        // Start week on
        _SettingsTile(
          title: l10n.startWeekOn,
          value: _startWeekOnLabel(settings.startWeekOn, l10n),
          onTap: () => _showStartWeekOnDialog(context, settings, l10n),
        ),
      ],
    );
  }

  String _volumeButtonLabel(VolumeButtonBehavior behavior, AppLocalizations l10n) {
    switch (behavior) {
      case VolumeButtonBehavior.stop:
        return l10n.volumeButtonStop;
      case VolumeButtonBehavior.adjustVolume:
        return l10n.volumeButtonAdjustVolume;
      case VolumeButtonBehavior.nothing:
        return l10n.volumeButtonNothing;
    }
  }

  String _startWeekOnLabel(StartWeekOn startWeekOn, AppLocalizations l10n) {
    switch (startWeekOn) {
      case StartWeekOn.sunday:
        return l10n.startWeekOnSunday;
      case StartWeekOn.monday:
        return l10n.startWeekOnMonday;
      case StartWeekOn.saturday:
        return l10n.startWeekOnSaturday;
    }
  }

  void _showSilenceAfterDialog(
      BuildContext context, AlarmSettingsService settings, AppLocalizations l10n) {
    final options = [1, 5, 10, 15, 20, 25, 0]; // 0 = never
    _showSelectionDialog<int>(
      context: context,
      title: l10n.silenceAfter,
      options: options,
      currentValue: settings.silenceAfterMinutes,
      labelBuilder: (v) =>
          v == 0 ? l10n.silenceAfterNever : l10n.silenceAfterValue(v),
      onSelected: (v) => settings.setSilenceAfterMinutes(v),
    );
  }

  void _showGraduallyIncreaseDialog(
      BuildContext context, AlarmSettingsService settings, AppLocalizations l10n) {
    final options = [0, 15, 30, 60]; // 0 = off
    _showSelectionDialog<int>(
      context: context,
      title: l10n.graduallyIncreaseVolume,
      options: options,
      currentValue: settings.graduallyIncreaseVolumeSeconds,
      labelBuilder: (v) => v == 0
          ? l10n.graduallyIncreaseVolumeOff
          : l10n.graduallyIncreaseVolumeSeconds(v),
      onSelected: (v) => settings.setGraduallyIncreaseVolumeSeconds(v),
    );
  }

  void _showVolumeButtonsDialog(
      BuildContext context, AlarmSettingsService settings, AppLocalizations l10n) {
    final options = VolumeButtonBehavior.values;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.volumeButtons,
          style: const TextStyle(color: AppTheme.onSurface, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final isSelected = option == settings.volumeButtonBehavior;
            final label = _volumeButtonLabel(option, l10n);
            final subtitle = option == VolumeButtonBehavior.stop
                ? l10n.volumeButtonStopChallengeNote
                : null;
            return ListTile(
              title: Text(
                label,
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.onSurfaceSecondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    )
                  : null,
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                settings.setVolumeButtonBehavior(option);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showStartWeekOnDialog(
      BuildContext context, AlarmSettingsService settings, AppLocalizations l10n) {
    final options = StartWeekOn.values;
    _showSelectionDialog<StartWeekOn>(
      context: context,
      title: l10n.startWeekOn,
      options: options,
      currentValue: settings.startWeekOn,
      labelBuilder: (v) => _startWeekOnLabel(v, l10n),
      onSelected: (v) => settings.setStartWeekOn(v),
    );
  }

  void _showSelectionDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required T currentValue,
    required String Function(T) labelBuilder,
    required void Function(T) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: AppTheme.onSurface, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final isSelected = option == currentValue;
            return ListTile(
              title: Text(
                labelBuilder(option),
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                onSelected(option);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.onSurface),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: AppTheme.onSurfaceSecondary),
      ),
      onTap: onTap,
    );
  }
}

class _VolumeSliderTile extends StatelessWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSliderTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title,
              style: const TextStyle(color: AppTheme.onSurface, fontSize: 16),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.volume_mute, color: AppTheme.onSurfaceSecondary, size: 20),
              Expanded(
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppTheme.primary,
                  inactiveColor: AppTheme.onSurfaceSecondary.withOpacity(0.3),
                  onChanged: onChanged,
                ),
              ),
              const Icon(Icons.volume_up, color: AppTheme.onSurfaceSecondary, size: 20),
            ],
          ),
        ],
      ),
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
  bool? _ignoringBatteryOptimization;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    final canSchedule =
        await AndroidAlarmPlatformService.canScheduleExactAlarms();
    final ignoringBattery =
        await AndroidAlarmPlatformService.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() {
      _canScheduleExactAlarms = canSchedule;
      _ignoringBatteryOptimization = ignoringBattery;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
