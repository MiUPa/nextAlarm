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
