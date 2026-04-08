import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../l10n/app_localizations.dart';
import '../models/alarm.dart' as models;
import '../services/alarm_service.dart';
import '../services/android_alarm_platform_service.dart';
import '../services/alarm_settings_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class AlarmEditScreen extends StatefulWidget {
  final models.Alarm? alarm;

  const AlarmEditScreen({super.key, this.alarm});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late int _hour;
  late int _minute;
  late TextEditingController _labelController;
  late Set<int> _repeatDays;
  late Set<String> _pausedDates;
  late models.WakeUpChallenge _challenge;
  late int _challengeDifficulty;
  late models.AlarmSound _sound;
  late bool _vibrate;
  late models.VibrationIntensity _vibrationIntensity;
  late bool _gradualVolume;

  @override
  void initState() {
    super.initState();
    final alarmSettings = context.read<AlarmSettingsService>();
    _hour = widget.alarm?.time.hour ?? DateTime.now().hour;
    _minute = widget.alarm?.time.minute ?? DateTime.now().minute;
    _labelController = TextEditingController(text: widget.alarm?.label ?? '');
    _repeatDays = Set.from(widget.alarm?.repeatDays ?? {});
    _pausedDates = Set.from(
      widget.alarm?.prunePastPausedDates().pausedDates ?? const <String>{},
    );
    _challenge = widget.alarm?.challenge ?? models.WakeUpChallenge.none;
    _challengeDifficulty = widget.alarm?.challengeDifficulty ?? 2;
    _sound = widget.alarm?.sound ?? alarmSettings.defaultSound;
    _vibrate = widget.alarm?.vibrate ?? alarmSettings.defaultVibrate;
    _vibrationIntensity =
        widget.alarm?.vibrationIntensity ??
        alarmSettings.defaultVibrationIntensity;
    _gradualVolume =
        widget.alarm?.gradualVolume ?? alarmSettings.defaultGradualVolume;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.alarm != null ? l10n.editAlarm : l10n.addAlarm),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(context, l10n),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          children: [_buildAlarmCard(context, l10n)],
        ),
      ),
    );
  }

  Widget _buildAlarmCard(BuildContext context, AppLocalizations l10n) {
    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelField(context, l10n),
          const SizedBox(height: 20),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _showTimePicker(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildTimeDisplay(context),
                  const SizedBox(height: 8),
                  Text(
                    _buildRepeatSummary(context, l10n),
                    style: const TextStyle(
                      color: AppTheme.onSurfaceSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _RepeatDaysSelector(
            selectedDays: _repeatDays,
            compact: false,
            onChanged: (days) {
              setState(() => _repeatDays = days);
            },
          ),
          if (_repeatDays.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildDivider(),
            _buildPauseDatesTile(context, l10n, inPanel: true),
          ],
          const SizedBox(height: 18),
          _buildDivider(),
          _buildOptionTile(
            context,
            icon: Icons.notifications_active_outlined,
            title: l10n.alarmSound,
            value: _getSoundName(l10n, _sound),
            onTap: () => _showSoundPicker(context),
          ),
          _buildDivider(),
          _buildSwitchTile(
            context,
            icon: Icons.vibration_rounded,
            title: l10n.vibration,
            value: _vibrate,
            onChanged: (value) => setState(() => _vibrate = value),
          ),
          if (_vibrate) ...[
            _buildDivider(),
            _buildOptionTile(
              context,
              icon: Icons.graphic_eq_rounded,
              title: l10n.vibrationIntensity,
              value: _getVibrationIntensityName(l10n, _vibrationIntensity),
              onTap: () => _showVibrationIntensityPicker(context),
            ),
          ],
          _buildDivider(),
          _buildSwitchTile(
            context,
            icon: Icons.trending_up_rounded,
            title: l10n.gradualVolume,
            subtitle: l10n.gradualVolumeDescription,
            value: _gradualVolume,
            onChanged: (value) => setState(() => _gradualVolume = value),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel(context, l10n.wakeUpChallenge),
          const SizedBox(height: 14),
          _ChallengeSelector(
            selected: _challenge,
            compact: false,
            onChanged: _handleChallengeSelected,
          ),
          if (_challenge != models.WakeUpChallenge.none) ...[
            const SizedBox(height: 20),
            _buildDivider(),
            const SizedBox(height: 18),
            _buildSectionLabel(context, l10n.difficulty),
            const SizedBox(height: 8),
            _DifficultySelector(
              difficulty: _challengeDifficulty,
              compact: false,
              onChanged: (value) {
                setState(() => _challengeDifficulty = value);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, AppLocalizations l10n) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              if (widget.alarm != null)
                TextButton(
                  onPressed: _deleteAlarm,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 14,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.delete),
                ),
              const Spacer(),
              SizedBox(
                width: 148,
                child: FilledButton(
                  onPressed: _saveAlarm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelField(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(
          Icons.label_outline_rounded,
          color: AppTheme.onSurfaceSecondary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _labelController,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: l10n.labelHint,
              hintStyle: TextStyle(
                color: AppTheme.onSurfaceSecondary.withValues(alpha: 0.75),
              ),
              filled: false,
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDisplay(BuildContext context) {
    final parts = _formatAlarmTime(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          parts[0],
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w300,
            color: AppTheme.onSurface,
            letterSpacing: -3,
          ),
        ),
        if (parts.length > 1) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              parts[1],
              style: const TextStyle(
                color: AppTheme.onSurfaceSecondary,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF242428), Color(0xFF1C1C1E)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: child,
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppTheme.onSurfaceSecondary,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 24,
      horizontalTitleGap: 16,
      visualDensity: const VisualDensity(vertical: -1),
      leading: Icon(icon, color: AppTheme.onSurfaceSecondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.onSurfaceSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: AppTheme.onSurfaceSecondary),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 24,
      horizontalTitleGap: 16,
      visualDensity: const VisualDensity(vertical: -1),
      leading: Icon(icon, color: AppTheme.onSurfaceSecondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.onSurfaceSecondary,
                  fontSize: 13,
                ),
              ),
            ),
      trailing: Switch(
        value: value,
        activeTrackColor: AppTheme.primary,
        activeThumbColor: Colors.white,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }

  String _buildRepeatSummary(BuildContext context, AppLocalizations l10n) {
    if (_repeatDays.isEmpty) {
      return l10n.repeatOnce;
    }

    if (_repeatDays.length == 7) {
      return l10n.repeatEveryDay;
    }

    if (_repeatDays.length == 5 &&
        !_repeatDays.contains(6) &&
        !_repeatDays.contains(7)) {
      return l10n.repeatWeekdays;
    }

    if (_repeatDays.length == 2 &&
        _repeatDays.contains(6) &&
        _repeatDays.contains(7)) {
      return l10n.repeatWeekends;
    }

    final alarmSettings = context.read<AlarmSettingsService>();
    final labels = <int, String>{
      1: l10n.dayMonday,
      2: l10n.dayTuesday,
      3: l10n.dayWednesday,
      4: l10n.dayThursday,
      5: l10n.dayFriday,
      6: l10n.daySaturday,
      7: l10n.daySunday,
    };

    return alarmSettings.weekdayOrder
        .where(_repeatDays.contains)
        .map((day) => labels[day]!)
        .join(', ');
  }

  List<String> _formatAlarmTime(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final alwaysUse24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    final formatted = localizations.formatTimeOfDay(
      TimeOfDay(hour: _hour, minute: _minute),
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );

    if (alwaysUse24HourFormat) {
      return [formatted];
    }

    final parts = formatted.split(' ');
    if (parts.length < 2) {
      return [formatted];
    }

    return [parts.sublist(0, parts.length - 1).join(' '), parts.last];
  }

  String _getVibrationIntensityName(
    AppLocalizations l10n,
    models.VibrationIntensity intensity,
  ) {
    switch (intensity) {
      case models.VibrationIntensity.gentle:
        return l10n.vibrationIntensityGentle;
      case models.VibrationIntensity.standard:
        return l10n.vibrationIntensityStandard;
      case models.VibrationIntensity.aggressive:
        return l10n.vibrationIntensityAggressive;
    }
  }

  String _getSoundName(AppLocalizations l10n, models.AlarmSound sound) {
    switch (sound) {
      case models.AlarmSound.defaultAlarm:
        return l10n.soundDefault;
      case models.AlarmSound.gentle:
        return l10n.soundGentle;
      case models.AlarmSound.digital:
        return l10n.soundDigital;
      case models.AlarmSound.classic:
        return l10n.soundClassic;
      case models.AlarmSound.nature:
        return l10n.soundNature;
      case models.AlarmSound.silent:
        return l10n.soundSilent;
    }
  }

  void _showSoundPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceSecondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ...models.AlarmSound.values.map(
            (sound) => ListTile(
              title: Text(
                _getSoundName(l10n, sound),
                style: const TextStyle(color: AppTheme.onSurface),
              ),
              trailing: _sound == sound
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                setState(() => _sound = sound);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showVibrationIntensityPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceSecondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ...models.VibrationIntensity.values.map(
            (intensity) => ListTile(
              title: Text(
                _getVibrationIntensityName(l10n, intensity),
                style: const TextStyle(color: AppTheme.onSurface),
              ),
              trailing: _vibrationIntensity == intensity
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                setState(() => _vibrationIntensity = intensity);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.onSurface,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppTheme.surface,
              hourMinuteColor: AppTheme.surfaceVariant,
              hourMinuteTextColor: AppTheme.onSurface,
              hourMinuteTextStyle: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w400,
              ),
              dialBackgroundColor: AppTheme.surfaceVariant,
              dialHandColor: AppTheme.primary,
              dialTextColor: AppTheme.onSurface,
              entryModeIconColor: AppTheme.onSurfaceSecondary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  Future<void> _deleteAlarm() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          l10n.deleteAlarm,
          style: const TextStyle(color: AppTheme.onSurface),
        ),
        content: Text(
          l10n.deleteAlarmConfirmation,
          style: const TextStyle(color: AppTheme.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AlarmService>().deleteAlarm(widget.alarm!.id);
      Navigator.pop(context);
    }
  }

  Future<void> _handleChallengeSelected(
    models.WakeUpChallenge challenge,
  ) async {
    if (_challenge == challenge) return;

    final isReady = await _ensureChallengeReady(challenge, showFeedback: true);
    if (!mounted || !isReady) return;

    setState(() => _challenge = challenge);
  }

  Future<bool> _ensureSelectedChallengeReady() {
    return _ensureChallengeReady(_challenge, showFeedback: true);
  }

  Future<bool> _ensureChallengeReady(
    models.WakeUpChallenge challenge, {
    required bool showFeedback,
  }) async {
    switch (challenge) {
      case models.WakeUpChallenge.none:
      case models.WakeUpChallenge.math:
      case models.WakeUpChallenge.shake:
        return true;
      case models.WakeUpChallenge.voiceRecognition:
        return _ensureVoiceChallengeReady(showFeedback: showFeedback);
      case models.WakeUpChallenge.steps:
        return _ensureStepsChallengeReady(showFeedback: showFeedback);
    }
  }

  Future<bool> _ensureVoiceChallengeReady({required bool showFeedback}) async {
    final l10n = AppLocalizations.of(context)!;
    final permissionGranted = await _ensurePermissionGranted(
      permission: Permission.microphone,
      deniedMessage: l10n.voiceChallengeNeedsMicrophone,
      rationaleTitle: l10n.microphonePermissionRationaleTitle,
      rationaleMessage: l10n.microphonePermissionRationaleMessage,
      showFeedback: showFeedback,
    );
    if (!permissionGranted || !mounted) return false;

    final speech = stt.SpeechToText();
    final available = await speech.initialize();
    if (!available) {
      if (showFeedback && mounted) {
        _showChallengeBlockedSnackBar(l10n.speechNotAvailable);
      }
      return false;
    }

    return true;
  }

  Future<bool> _ensureStepsChallengeReady({required bool showFeedback}) async {
    final l10n = AppLocalizations.of(context)!;
    final permissionGranted = await _ensurePermissionGranted(
      permission: Permission.activityRecognition,
      deniedMessage: l10n.stepsChallengeNeedsActivityPermission,
      rationaleTitle: l10n.activityPermissionRationaleTitle,
      rationaleMessage: l10n.activityPermissionRationaleMessage,
      showFeedback: showFeedback,
    );
    if (!permissionGranted || !mounted) return false;

    final hasStepCounterSensor =
        await AndroidAlarmPlatformService.hasStepCounterSensor();
    if (!hasStepCounterSensor) {
      if (showFeedback && mounted) {
        _showChallengeBlockedSnackBar(l10n.stepSensorNotAvailable);
      }
      return false;
    }

    return true;
  }

  Future<bool> _ensurePermissionGranted({
    required Permission permission,
    required String deniedMessage,
    required String rationaleTitle,
    required String rationaleMessage,
    required bool showFeedback,
  }) async {
    var status = await permission.status;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    if (status.isDenied) {
      if (isAndroid && showFeedback) {
        final shouldShowRationale = await permission.shouldShowRequestRationale;
        if (shouldShowRationale) {
          final shouldContinue = await _showPermissionRationaleDialog(
            title: rationaleTitle,
            message: rationaleMessage,
          );
          if (!shouldContinue) {
            return false;
          }
        }
      }

      status = await permission.request();
    }

    if (status.isGranted) {
      return true;
    }

    if (!showFeedback || !mounted) {
      return false;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      await _showPermissionSettingsDialog(
        deniedMessage: deniedMessage,
        onOpenSettings: permission == Permission.notification
            ? _openAndroidNotificationSettings
            : openAppSettings,
      );
      return false;
    }

    _showChallengeBlockedSnackBar(deniedMessage);
    return false;
  }

  Future<bool> _showPermissionRationaleDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return false;

    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(
              title,
              style: const TextStyle(color: AppTheme.onSurface),
            ),
            content: Text(
              message,
              style: const TextStyle(color: AppTheme.onSurfaceSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.permissionContinue),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showPermissionSettingsDialog({
    required String deniedMessage,
    required Future<bool> Function() onOpenSettings,
  }) async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          l10n.permissionSettingsTitle,
          style: const TextStyle(color: AppTheme.onSurface),
        ),
        content: Text(
          '$deniedMessage\n\n${l10n.permissionSettingsMessage}',
          style: const TextStyle(color: AppTheme.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await onOpenSettings();
            },
            child: Text(l10n.settings),
          ),
        ],
      ),
    );
  }

  Future<bool> _openAndroidNotificationSettings() async {
    final opened = await AndroidAlarmPlatformService.openNotificationSettings();
    if (opened) {
      return true;
    }
    return openAppSettings();
  }

  void _showChallengeBlockedSnackBar(
    String message, {
    bool withSettingsAction = false,
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: withSettingsAction
              ? SnackBarAction(
                  label: AppLocalizations.of(context)!.settings,
                  onPressed: openAppSettings,
                )
              : null,
        ),
      );
  }

  void _saveAlarm() async {
    final alarmService = context.read<AlarmService>();
    final canSave = await _confirmAlarmReliabilityBeforeSave();
    if (!canSave) return;
    final challengeReady = await _ensureSelectedChallengeReady();
    if (!challengeReady) return;

    final alarm = models.Alarm(
      id: widget.alarm?.id,
      time: models.TimeOfDay(hour: _hour, minute: _minute),
      label: _labelController.text,
      repeatDays: _repeatDays,
      pausedDates: _repeatDays.isEmpty ? const {} : _pausedDates,
      challenge: _challenge,
      challengeDifficulty: _challengeDifficulty,
      sound: _sound,
      vibrate: _vibrate,
      vibrationIntensity: _vibrationIntensity,
      gradualVolume: _gradualVolume,
    );

    if (widget.alarm == null) {
      await alarmService.addAlarm(alarm);
    } else {
      await alarmService.updateAlarm(alarm);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<bool> _confirmAlarmReliabilityBeforeSave() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    await _requestNotificationPermissionIfNeeded();

    final canScheduleExactAlarms =
        await AndroidAlarmPlatformService.canScheduleExactAlarms();
    final notificationsEnabled =
        await AndroidAlarmPlatformService.areNotificationsEnabled();
    final canUseFullScreenIntent =
        await AndroidAlarmPlatformService.canUseFullScreenIntent();
    final ignoringBatteryOptimization =
        await AndroidAlarmPlatformService.isIgnoringBatteryOptimizations();

    if (!mounted) return false;

    final missingChecks = <String>[];
    if (!canScheduleExactAlarms) {
      missingChecks.add('Exact alarm permission');
    }
    if (!notificationsEnabled) {
      missingChecks.add('Notification permission');
    }
    if (!canUseFullScreenIntent) {
      missingChecks.add('Full-screen alarm display');
    }
    if (!ignoringBatteryOptimization) {
      missingChecks.add('Battery optimization');
    }

    if (missingChecks.isEmpty) {
      return true;
    }

    final shouldSaveAnyway =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text(
              'Alarm reliability warning',
              style: TextStyle(color: AppTheme.onSurface),
            ),
            content: Text(
              'Some Android settings are disabled: ${missingChecks.join(', ')}.\n'
              'The alarm screen may not take over the lock screen automatically, '
              'and while you are actively using the device Android may show a '
              'heads-up notification instead.',
              style: const TextStyle(color: AppTheme.onSurfaceSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Review settings'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Save anyway'),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return false;
    if (shouldSaveAnyway) return true;

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    return false;
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final status = await Permission.notification.status;
    if (!status.isDenied || !mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final shouldContinue = await _showPermissionRationaleDialog(
      title: l10n.notificationPermissionRationaleTitle,
      message: l10n.notificationPermissionRationaleMessage,
    );
    if (!shouldContinue) {
      return;
    }

    await Permission.notification.request();
  }

  Widget _buildPauseDatesTile(
    BuildContext context,
    AppLocalizations l10n, {
    bool inPanel = false,
  }) {
    final sortedPausedDates =
        _pausedDates.map(models.alarmDateFromKey).whereType<DateTime>().toList()
          ..sort();
    final hasPausedDates = sortedPausedDates.isNotEmpty;

    return Padding(
      padding: inPanel
          ? const EdgeInsets.fromLTRB(0, 16, 0, 0)
          : const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 20,
            horizontalTitleGap: 16,
            visualDensity: const VisualDensity(vertical: -2),
            leading: const Icon(
              Icons.pause_circle_outline_rounded,
              color: AppTheme.onSurfaceSecondary,
            ),
            title: Text(
              l10n.pauseDates,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: AppTheme.onSurface),
            ),
            subtitle: hasPausedDates
                ? Text(
                    _buildPauseDatesSummary(context, sortedPausedDates),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceSecondary,
                    ),
                  )
                : null,
            trailing: Icon(
              hasPausedDates
                  ? Icons.edit_calendar_outlined
                  : Icons.add_circle_outline_rounded,
              color: AppTheme.onSurfaceSecondary,
            ),
            onTap: () => _showPauseRangePicker(context),
          ),
          if (hasPausedDates)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedPausedDates
                    .map((date) {
                      final dateKey = models.alarmDateKey(date);
                      return InputChip(
                        label: Text(_formatPauseDate(context, date)),
                        selected: true,
                        selectedColor: AppTheme.primary.withValues(alpha: 0.18),
                        onDeleted: () {
                          setState(() {
                            _pausedDates.remove(dateKey);
                          });
                        },
                      );
                    })
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  String _buildPauseDatesSummary(
    BuildContext context,
    List<DateTime> sortedPausedDates,
  ) {
    if (sortedPausedDates.isEmpty) {
      return '';
    }
    if (sortedPausedDates.length == 1) {
      return _formatPauseDate(context, sortedPausedDates.first);
    }
    if (_isContiguousPauseDates(sortedPausedDates)) {
      return '${_formatPauseDate(context, sortedPausedDates.first)} - ${_formatPauseDate(context, sortedPausedDates.last)}';
    }

    final preview = sortedPausedDates
        .take(2)
        .map((date) => _formatPauseDate(context, date))
        .join(', ');
    final remainingCount = sortedPausedDates.length - 2;
    if (remainingCount <= 0) {
      return preview;
    }
    return '$preview +$remainingCount';
  }

  bool _isContiguousPauseDates(List<DateTime> sortedPausedDates) {
    for (var i = 1; i < sortedPausedDates.length; i++) {
      final previous = DateTime(
        sortedPausedDates[i - 1].year,
        sortedPausedDates[i - 1].month,
        sortedPausedDates[i - 1].day,
      );
      final current = DateTime(
        sortedPausedDates[i].year,
        sortedPausedDates[i].month,
        sortedPausedDates[i].day,
      );
      if (current.difference(previous).inDays != 1) {
        return false;
      }
    }
    return true;
  }

  Future<void> _showPauseRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
              onSurface: AppTheme.onSurface,
            ),
            scaffoldBackgroundColor: AppTheme.background,
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      var cursor = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      final end = DateTime(picked.end.year, picked.end.month, picked.end.day);
      while (!cursor.isAfter(end)) {
        _pausedDates.add(models.alarmDateKey(cursor));
        cursor = cursor.add(const Duration(days: 1));
      }
    });
  }

  String _formatPauseDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.MMMd(locale).format(date);
  }
}

class _RepeatDaysSelector extends StatelessWidget {
  final Set<int> selectedDays;
  final bool compact;
  final ValueChanged<Set<int>> onChanged;

  const _RepeatDaysSelector({
    required this.selectedDays,
    this.compact = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final alarmSettings = context.watch<AlarmSettingsService>();
    final dayLabels = <int, String>{
      1: l10n.dayMonday,
      2: l10n.dayTuesday,
      3: l10n.dayWednesday,
      4: l10n.dayThursday,
      5: l10n.dayFriday,
      6: l10n.daySaturday,
      7: l10n.daySunday,
    };
    final orderedWeekdays = alarmSettings.weekdayOrder;
    final chipSize = compact ? 40.0 : 44.0;
    final dayFontSize = compact ? 12.0 : 14.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(orderedWeekdays.length, (index) {
        final dayNumber = orderedWeekdays[index];
        final isSelected = selectedDays.contains(dayNumber);

        return GestureDetector(
          onTap: () {
            final newDays = Set<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(dayNumber);
            } else {
              newDays.add(dayNumber);
            }
            onChanged(newDays);
          },
          child: Container(
            width: chipSize,
            height: chipSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppTheme.primary : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Center(
              child: Text(
                dayLabels[dayNumber]!,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.onSurfaceSecondary,
                  fontSize: dayFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ChallengeSelector extends StatelessWidget {
  final models.WakeUpChallenge selected;
  final bool compact;
  final Future<void> Function(models.WakeUpChallenge) onChanged;

  const _ChallengeSelector({
    required this.selected,
    this.compact = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final challenges = [
      (models.WakeUpChallenge.none, Icons.alarm, l10n.challengeNone),
      (
        models.WakeUpChallenge.math,
        Icons.calculate_outlined,
        l10n.challengeMath,
      ),
      (models.WakeUpChallenge.voiceRecognition, Icons.mic, l10n.challengeVoice),
      (models.WakeUpChallenge.shake, Icons.phone_android, l10n.challengeShake),
      (
        models.WakeUpChallenge.steps,
        Icons.directions_walk,
        l10n.challengeSteps,
      ),
    ];
    final selectorHeight = compact ? 88.0 : 100.0;
    final itemWidth = compact ? 72.0 : 80.0;
    final itemMargin = compact ? 3.0 : 4.0;
    final iconSize = compact ? 28.0 : 32.0;
    final iconLabelSpacing = compact ? 6.0 : 8.0;
    final labelFontSize = compact ? 11.0 : 12.0;

    return SizedBox(
      height: selectorHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final (challenge, icon, label) = challenges[index];
          final isSelected = selected == challenge;

          return GestureDetector(
            onTap: () => onChanged(challenge),
            child: Container(
              width: itemWidth,
              margin: EdgeInsets.symmetric(horizontal: itemMargin),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.onSurfaceSecondary,
                    size: iconSize,
                  ),
                  SizedBox(height: iconLabelSpacing),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.onSurfaceSecondary,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  final int difficulty;
  final bool compact;
  final ValueChanged<int> onChanged;

  const _DifficultySelector({
    required this.difficulty,
    this.compact = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sliderTrackHeight = compact ? 3.0 : 4.0;
    final valueLabelSpacing = compact ? 12.0 : 16.0;
    final valueLabelWidth = compact ? 56.0 : 60.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.primary,
                inactiveTrackColor: AppTheme.surfaceVariant,
                thumbColor: AppTheme.primary,
                overlayColor: AppTheme.primary.withValues(alpha: 0.2),
                trackHeight: sliderTrackHeight,
              ),
              child: Slider(
                value: difficulty.toDouble(),
                min: 1,
                max: 3,
                divisions: 2,
                label: _getDifficultyLabel(l10n, difficulty),
                onChanged: (value) => onChanged(value.toInt()),
              ),
            ),
          ),
          SizedBox(width: valueLabelSpacing),
          SizedBox(
            width: valueLabelWidth,
            child: Text(
              _getDifficultyLabel(l10n, difficulty),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyLabel(AppLocalizations l10n, int level) {
    switch (level) {
      case 1:
        return l10n.difficultyEasy;
      case 2:
        return l10n.difficultyNormal;
      case 3:
        return l10n.difficultyHard;
      default:
        return l10n.difficultyNormal;
    }
  }
}
