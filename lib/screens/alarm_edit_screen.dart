import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/alarm.dart' as models;
import '../services/alarm_service.dart';
import '../services/android_alarm_platform_service.dart';
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
	late models.WakeUpChallenge _challenge;
	late int _challengeDifficulty;
	late models.AlarmSound _sound;
	late bool _vibrate;
	late models.VibrationIntensity _vibrationIntensity;
	late bool _gradualVolume;

	@override
	void initState() {
		super.initState();
		_hour = widget.alarm?.time.hour ?? DateTime.now().hour;
		_minute = widget.alarm?.time.minute ?? DateTime.now().minute;
		_labelController = TextEditingController(text: widget.alarm?.label ?? '');
		_repeatDays = Set.from(widget.alarm?.repeatDays ?? {});
		_challenge = widget.alarm?.challenge ?? models.WakeUpChallenge.none;
		_challengeDifficulty = widget.alarm?.challengeDifficulty ?? 2;
		_sound = widget.alarm?.sound ?? models.AlarmSound.defaultAlarm;
		_vibrate = widget.alarm?.vibrate ?? true;
		_vibrationIntensity =
				widget.alarm?.vibrationIntensity ?? models.VibrationIntensity.standard;
		_gradualVolume = widget.alarm?.gradualVolume ?? false;
	}

	@override
	void dispose() {
		_labelController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;
		const isCompactLayout = true;
		const sectionTopPadding = 14.0;
		const sectionBottomPadding = 8.0;
		const timePickerHeight = 140.0;
		const timePickerVerticalPadding = 20.0;
		const timeFontSize = 64.0;
		const contentBottomSpacing = 12.0;

		return Scaffold(
			backgroundColor: AppTheme.background,
			appBar: AppBar(
				centerTitle: true,
				leading: IconButton(
					icon: const Icon(Icons.close),
					onPressed: () {
						Navigator.pop(context);
					},
				),
				title: widget.alarm != null
					? IconButton(
						onPressed: _deleteAlarm,
						icon: const Icon(Icons.delete_outline),
						color: AppTheme.danger,
						tooltip: l10n.deleteAlarm,
					)
					: null,
				actions: [
					TextButton(
						onPressed: _saveAlarm,
						child: Text(l10n.save),
					),
				],
			),
			body: SafeArea(
				top: false,
				child: Column(
					children: [
						// Time Picker - Android style
						GestureDetector(
							onTap: () => _showTimePicker(context),
							child: Container(
								height: timePickerHeight,
								padding: const EdgeInsets.symmetric(vertical: timePickerVerticalPadding),
								child: Center(
									child: Text(
										'${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
										style: const TextStyle(
											fontSize: timeFontSize,
											fontWeight: FontWeight.w300,
											color: AppTheme.onSurface,
											letterSpacing: 2,
										),
									),
								),
							),
						),

						const SizedBox(height: 6),

						// Label
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
							child: Row(
								children: [
									Text(
										l10n.label,
										style: Theme.of(context).textTheme.titleSmall?.copyWith(
											color: AppTheme.onSurfaceSecondary,
											letterSpacing: 0.5,
										),
									),
									const SizedBox(width: 16),
									Expanded(
										child: TextField(
											controller: _labelController,
											style: Theme.of(context).textTheme.bodyLarge?.copyWith(
												color: AppTheme.onSurface,
											),
											textAlign: TextAlign.end,
											decoration: InputDecoration(
												hintText: l10n.labelHint,
												hintStyle: TextStyle(
													color: AppTheme.onSurfaceSecondary.withValues(alpha: 0.5),
												),
												border: InputBorder.none,
												isDense: true,
												contentPadding: EdgeInsets.zero,
											),
										),
									),
								],
							),
						),

						// Repeat days
						_buildSection(
							l10n.repeat,
							_RepeatDaysSelector(
								selectedDays: _repeatDays,
								compact: isCompactLayout,
								onChanged: (days) {
									setState(() => _repeatDays = days);
								},
							),
							topPadding: sectionTopPadding,
							bottomPadding: sectionBottomPadding,
						),

						// Alarm sound
						ListTile(
							contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
							visualDensity: const VisualDensity(vertical: -2),
							title: Text(
								l10n.alarmSound,
								style: Theme.of(context).textTheme.titleSmall?.copyWith(
									color: AppTheme.onSurfaceSecondary,
									letterSpacing: 0.5,
								),
							),
							trailing: Row(
								mainAxisSize: MainAxisSize.min,
								children: [
									Text(
										_getSoundName(l10n, _sound),
										style: Theme.of(context).textTheme.bodyLarge?.copyWith(
											color: AppTheme.onSurface,
										),
									),
									const SizedBox(width: 4),
									const Icon(
										Icons.chevron_right,
										color: AppTheme.onSurfaceSecondary,
									),
								],
							),
							onTap: () {
								_showSoundPicker(context);
							},
						),

						// Vibration toggle
						SwitchListTile(
							contentPadding: const EdgeInsets.symmetric(horizontal: 20),
							dense: true,
							visualDensity: const VisualDensity(vertical: -2),
							title: Text(
								l10n.vibration,
								style: Theme.of(context).textTheme.titleSmall?.copyWith(
									color: AppTheme.onSurfaceSecondary,
									letterSpacing: 0.5,
								),
							),
							value: _vibrate,
							activeTrackColor: AppTheme.primary,
							activeThumbColor: Colors.white,
							onChanged: (value) {
								setState(() => _vibrate = value);
							},
						),

						if (_vibrate)
							ListTile(
								contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
								title: Text(
									l10n.vibrationIntensity,
									style: Theme.of(context).textTheme.titleSmall?.copyWith(
										color: AppTheme.onSurfaceSecondary,
										letterSpacing: 0.5,
									),
								),
								trailing: Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										Text(
											_getVibrationIntensityName(l10n, _vibrationIntensity),
											style: Theme.of(context).textTheme.bodyLarge?.copyWith(
												color: AppTheme.onSurface,
											),
										),
										const SizedBox(width: 4),
										const Icon(
											Icons.chevron_right,
											color: AppTheme.onSurfaceSecondary,
										),
									],
								),
								onTap: () {
									_showVibrationIntensityPicker(context);
								},
							),

						// Gradual volume
						SwitchListTile(
							contentPadding: const EdgeInsets.symmetric(horizontal: 20),
							dense: true,
							visualDensity: const VisualDensity(vertical: -2),
							title: Text(
								l10n.gradualVolume,
								style: Theme.of(context).textTheme.titleSmall?.copyWith(
									color: AppTheme.onSurfaceSecondary,
									letterSpacing: 0.5,
								),
							),
							subtitle: Text(
								l10n.gradualVolumeDescription,
								style: Theme.of(context).textTheme.bodySmall?.copyWith(
									color: AppTheme.onSurfaceSecondary.withValues(alpha: 0.7),
								),
							),
							value: _gradualVolume,
							activeTrackColor: AppTheme.primary,
							activeThumbColor: Colors.white,
							onChanged: (value) {
								setState(() => _gradualVolume = value);
							},
						),

						// Wake-up challenge
						_buildSection(
							l10n.wakeUpChallenge,
							_ChallengeSelector(
								selected: _challenge,
								compact: isCompactLayout,
								onChanged: (challenge) {
									setState(() => _challenge = challenge);
								},
							),
							topPadding: sectionTopPadding,
							bottomPadding: sectionBottomPadding,
						),

						// Challenge difficulty
						if (_challenge != models.WakeUpChallenge.none)
							_buildSection(
								l10n.difficulty,
								_DifficultySelector(
									difficulty: _challengeDifficulty,
									compact: isCompactLayout,
									onChanged: (value) {
										setState(() => _challengeDifficulty = value);
									},
								),
								topPadding: sectionTopPadding,
								bottomPadding: sectionBottomPadding,
							),

						const SizedBox(height: contentBottomSpacing),
					],
				),
			),
		);
	}

	Widget _buildSection(
		String title,
		Widget child, {
		double topPadding = 24,
		double bottomPadding = 12,
	}) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Padding(
					padding: EdgeInsets.fromLTRB(20, topPadding, 20, bottomPadding),
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
						style: TextButton.styleFrom(
							foregroundColor: AppTheme.danger,
						),
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

	void _saveAlarm() async {
		final alarmService = context.read<AlarmService>();
		final canSave = await _confirmAlarmReliabilityBeforeSave();
		if (!canSave) return;

		final alarm = models.Alarm(
			id: widget.alarm?.id,
			time: models.TimeOfDay(hour: _hour, minute: _minute),
			label: _labelController.text,
			repeatDays: _repeatDays,
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

		final canScheduleExactAlarms =
				await AndroidAlarmPlatformService.canScheduleExactAlarms();
		final notificationsEnabled =
				await AndroidAlarmPlatformService.areNotificationsEnabled();
		final canUseFullScreenIntent =
				await AndroidAlarmPlatformService.canUseFullScreenIntent();

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
							'The alarm screen may not appear automatically on lock screen or while '
							'another app is open.',
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
		final days = [
			l10n.dayMonday,
			l10n.dayTuesday,
			l10n.dayWednesday,
			l10n.dayThursday,
			l10n.dayFriday,
			l10n.daySaturday,
			l10n.daySunday,
		];
		final chipSize = compact ? 40.0 : 44.0;
		final dayFontSize = compact ? 12.0 : 14.0;

		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 20),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: List.generate(7, (index) {
					final dayNumber = index + 1;
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
								color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
							),
							child: Center(
								child: Text(
									days[index],
									style: TextStyle(
										color: isSelected ? Colors.white : AppTheme.onSurfaceSecondary,
										fontSize: dayFontSize,
										fontWeight: FontWeight.w600,
									),
								),
							),
						),
					);
				}),
			),
		);
	}
}

class _ChallengeSelector extends StatelessWidget {
	final models.WakeUpChallenge selected;
	final bool compact;
	final ValueChanged<models.WakeUpChallenge> onChanged;

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
			(models.WakeUpChallenge.math, Icons.calculate_outlined, l10n.challengeMath),
			(models.WakeUpChallenge.voiceRecognition, Icons.mic, l10n.challengeVoice),
			(models.WakeUpChallenge.shake, Icons.phone_android, l10n.challengeShake),
			(models.WakeUpChallenge.steps, Icons.directions_walk, l10n.challengeSteps),
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
				padding: const EdgeInsets.symmetric(horizontal: 16),
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
								color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
								borderRadius: BorderRadius.circular(16),
							),
							child: Column(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									Icon(
										icon,
										color: isSelected ? Colors.white : AppTheme.onSurfaceSecondary,
										size: iconSize,
									),
									SizedBox(height: iconLabelSpacing),
									Text(
										label,
										style: TextStyle(
											color: isSelected ? Colors.white : AppTheme.onSurfaceSecondary,
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
							style: Theme.of(context).textTheme.titleMedium?.copyWith(
								color: AppTheme.primary,
							),
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
