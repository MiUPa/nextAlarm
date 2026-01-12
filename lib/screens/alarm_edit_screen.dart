import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
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

  @override
  void initState() {
    super.initState();
    _hour = widget.alarm?.time.hour ?? DateTime.now().hour;
    _minute = widget.alarm?.time.minute ?? DateTime.now().minute;
    _label = widget.alarm?.label ?? '';
    _repeatDays = Set.from(widget.alarm?.repeatDays ?? {});
    _challenge = widget.alarm?.challenge ?? models.WakeUpChallenge.none;
    _challengeDifficulty = widget.alarm?.challengeDifficulty ?? 2;
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(widget.alarm == null ? 'Add Alarm' : 'Edit Alarm'),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Time Picker
            Container(
              height: 220,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontSize: 24,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(2024, 1, 1, _hour, _minute),
                  onDateTimeChanged: (DateTime value) {
                    setState(() {
                      _hour = value.hour;
                      _minute = value.minute;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Label
            _buildSection(
              'Label',
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: TextEditingController(text: _label),
                  onChanged: (value) => _label = value,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: const InputDecoration(
                    hintText: 'Alarm name',
                    hintStyle: TextStyle(color: AppTheme.onSurfaceSecondary),
                  ),
                ),
              ),
            ),

            // Repeat days
            _buildSection(
              'Repeat',
              _RepeatDaysSelector(
                selectedDays: _repeatDays,
                onChanged: (days) {
                  setState(() => _repeatDays = days);
                  Vibration.vibrate(duration: 10);
                },
              ),
            ),

            // Wake-up challenge
            _buildSection(
              'Wake-up Challenge',
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
                'Difficulty',
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

  void _saveAlarm() async {
    Vibration.vibrate(duration: 15);

    final alarm = models.Alarm(
      id: widget.alarm?.id,
      time: models.TimeOfDay(hour: _hour, minute: _minute),
      label: _label,
      repeatDays: _repeatDays,
      challenge: _challenge,
      challengeDifficulty: _challengeDifficulty,
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
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
    final challenges = [
      (models.WakeUpChallenge.none, Icons.alarm, 'None'),
      (models.WakeUpChallenge.math, Icons.calculate_outlined, 'Math'),
      (models.WakeUpChallenge.qrCode, Icons.qr_code_scanner, 'QR Code'),
      (models.WakeUpChallenge.voiceRecognition, Icons.mic, 'Voice'),
      (models.WakeUpChallenge.shake, Icons.phone_android, 'Shake'),
      (models.WakeUpChallenge.steps, Icons.directions_walk, 'Steps'),
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
                label: _getDifficultyLabel(difficulty),
                onChanged: (value) => onChanged(value.toInt()),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 60,
            child: Text(
              _getDifficultyLabel(difficulty),
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

  String _getDifficultyLabel(int level) {
    switch (level) {
      case 1:
        return 'Easy';
      case 2:
        return 'Normal';
      case 3:
        return 'Hard';
      default:
        return 'Normal';
    }
  }
}
