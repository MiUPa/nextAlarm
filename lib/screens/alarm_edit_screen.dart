import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm.dart' as models;
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';

class AlarmEditScreen extends StatefulWidget {
	final models.Alarm? alarm;

	const AlarmEditScreen({super.key, this.alarm});

	@override
	State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
	late int _hour;
	late int _minute;
	late String _label;
	late Set<int> _repeatDays;
	late models.WakeUpChallenge _challenge;
	late int _challengeDifficulty;
	late models.AlarmSound _sound;

	@override
	void initState() {
		super.initState();
		_hour = widget.alarm?.time.hour ?? DateTime.now().hour;
		_minute = widget.alarm?.time.minute ?? DateTime.now().minute;
		_label = widget.alarm?.label ?? '';
		_repeatDays = Set.from(widget.alarm?.repeatDays ?? {});
		_challenge = widget.alarm?.challenge ?? models.WakeUpChallenge.none;
		_challengeDifficulty = widget.alarm?.challengeDifficulty ?? 2;
		_sound = widget.alarm?.sound ?? models.AlarmSound.defaultAlarm;
	}

	@override
	Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;

		return Scaffold(
			backgroundColor: AppTheme.background,
			appBar: AppBar(
				leading: IconButton(
					icon: const Icon(Icons.close),
					onPressed: () {
						Vibration.vibrate(duration: 10);
						Navigator.pop(context);
					},
				),
				title: Text(widget.alarm == null ? l10n.addAlarm : l10n.editAlarm),
				actions: [
					TextButton(
						onPressed: _saveAlarm,
						child: Text(l10n.save),
					),
				],
			),
			body: SingleChildScrollView(
				child: Column(
					children: [
						// Time Picker - Android style
						GestureDetector(
							onTap: () => _showTimePicker(context),
							child: Container(
								height: 180,
								padding: const EdgeInsets.symmetric(vertical: 30),
								child: Center(
									child: Text(
										'${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
										style: const TextStyle(
											fontSize: 72,
											fontWeight: FontWeight.w300,
											color: AppTheme.onSurface,
											letterSpacing: 2,
										),
									),
								),
							),
						),

						const SizedBox(height: 8),

						// Label
						_buildSection(
							l10n.label,
							Padding(
								padding: const EdgeInsets.symmetric(horizontal: 20),
								child: TextField(
									controller: TextEditingController(text: _label),
									onChanged: (value) => _label = value,
									style: const TextStyle(color: AppTheme.onSurface),
									decoration: InputDecoration(
										hintText: l10n.labelHint,
										hintStyle: const TextStyle(color: AppTheme.onSurfaceSecondary),
									),
								),
							),
						),

						// Repeat days
						_buildSection(
							l10n.repeat,
							_RepeatDaysSelector(
								selectedDays: _repeatDays,
								onChanged: (days) {
									setState(() => _repeatDays = days);
									Vibration.vibrate(duration: 10);
								},
							),
						),

						// Alarm sound
						_buildSection(
							l10n.alarmSound,
							_SoundSelector(
								selected: _sound,
								onChanged: (sound) {
									setState(() => _sound = sound);
									Vibration.vibrate(duration: 10);
								},
							),
						),

						// Wake-up challenge
						_buildSection(
							l10n.wakeUpChallenge,
							_ChallengeSelector(
								selected: _challenge,
								onChanged: (challenge) {
									setState(() => _challenge = challenge);
									Vibration.vibrate(duration: 10);
								},
							),
						),

						// Challenge difficulty
						if (_challenge != models.WakeUpChallenge.none)
							_buildSection(
								l10n.difficulty,
								_DifficultySelector(
									difficulty: _challengeDifficulty,
									onChanged: (value) {
										setState(() => _challengeDifficulty = value);
									},
								),
							),

						const SizedBox(height: 40),
					],
				),
			),
		);
	}

	Widget _buildSection(String title, Widget child) {
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

	Future<void> _showTimePicker(BuildContext context) async {
		Vibration.vibrate(duration: 10);
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

	void _saveAlarm() async {
		Vibration.vibrate(duration: 15);

		final alarm = models.Alarm(
			id: widget.alarm?.id,
			time: models.TimeOfDay(hour: _hour, minute: _minute),
			label: _label,
			repeatDays: _repeatDays,
			challenge: _challenge,
			challengeDifficulty: _challengeDifficulty,
			sound: _sound,
		);

		final alarmService = context.read<AlarmService>();

		if (widget.alarm == null) {
			await alarmService.addAlarm(alarm);
		} else {
			await alarmService.updateAlarm(alarm);
		}

		if (mounted) {
			Navigator.pop(context);
		}
	}
}

class _RepeatDaysSelector extends StatelessWidget {
	final Set<int> selectedDays;
	final ValueChanged<Set<int>> onChanged;

	const _RepeatDaysSelector({
		required this.selectedDays,
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
							width: 44,
							height: 44,
							decoration: BoxDecoration(
								shape: BoxShape.circle,
								color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
							),
							child: Center(
								child: Text(
									days[index],
									style: TextStyle(
										color: isSelected ? Colors.white : AppTheme.onSurfaceSecondary,
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
	final ValueChanged<models.WakeUpChallenge> onChanged;

	const _ChallengeSelector({
		required this.selected,
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

		return SizedBox(
			height: 100,
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
							width: 80,
							margin: const EdgeInsets.symmetric(horizontal: 4),
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
										size: 32,
									),
									const SizedBox(height: 8),
									Text(
										label,
										style: TextStyle(
											color: isSelected ? Colors.white : AppTheme.onSurfaceSecondary,
											fontSize: 12,
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
	final ValueChanged<int> onChanged;

	const _DifficultySelector({
		required this.difficulty,
		required this.onChanged,
	});

	@override
	Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;

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
								overlayColor: AppTheme.primary.withOpacity(0.2),
								trackHeight: 4,
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
					const SizedBox(width: 16),
					SizedBox(
						width: 60,
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

class _SoundSelector extends StatelessWidget {
	final models.AlarmSound selected;
	final ValueChanged<models.AlarmSound> onChanged;

	const _SoundSelector({
		required this.selected,
		required this.onChanged,
	});

	@override
	Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;
		final sounds = [
			(models.AlarmSound.defaultAlarm, Icons.alarm, l10n.soundDefault),
			(models.AlarmSound.gentle, Icons.water_drop_outlined, l10n.soundGentle),
			(models.AlarmSound.digital, Icons.electric_bolt, l10n.soundDigital),
			(models.AlarmSound.classic, Icons.notifications_outlined, l10n.soundClassic),
			(models.AlarmSound.nature, Icons.forest_outlined, l10n.soundNature),
		];

		return SizedBox(
			height: 100,
			child: ListView.builder(
				scrollDirection: Axis.horizontal,
				padding: const EdgeInsets.symmetric(horizontal: 16),
				itemCount: sounds.length,
				itemBuilder: (context, index) {
					final (sound, icon, label) = sounds[index];
					final isSelected = selected == sound;

					return GestureDetector(
						onTap: () => onChanged(sound),
						child: Container(
							width: 80,
							margin: const EdgeInsets.symmetric(horizontal: 4),
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
										size: 32,
									),
									const SizedBox(height: 8),
									Text(
										label,
										style: TextStyle(
											color: isSelected ? Colors.white : AppTheme.onSurfaceSecondary,
											fontSize: 12,
											fontWeight: FontWeight.w600,
										),
										textAlign: TextAlign.center,
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
