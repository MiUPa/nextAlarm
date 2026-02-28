import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/alarm.dart' as models;
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';

class AlarmEntryScreen extends StatelessWidget {
  const AlarmEntryScreen({super.key, required this.alarm});

  final models.Alarm alarm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  _buildAlarmIcon(),
                  const SizedBox(height: 32),
                  Text(
                    _formattedTime(alarm.time),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  if (alarm.label.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      alarm.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    l10n.alarmIsRinging,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    alarm.challenge == models.WakeUpChallenge.none
                        ? l10n.stopAlarm
                        : l10n.completeChallengeToStopAlarm,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  if (alarm.challenge != models.WakeUpChallenge.none) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.extension, color: AppTheme.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${l10n.wakeUpChallenge}: '
                              '${_challengeName(l10n, alarm.challenge)} '
                              '(${_difficultyText(l10n, alarm.challengeDifficulty)})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      final alarmService = context.read<AlarmService>();
                      if (alarm.challenge == models.WakeUpChallenge.none) {
                        alarmService.stopRingingAlarm();
                        return;
                      }
                      alarmService.beginAlarmChallenge();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          alarm.challenge == models.WakeUpChallenge.none
                          ? AppTheme.error
                          : AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      alarm.challenge == models.WakeUpChallenge.none
                          ? l10n.stopAlarm
                          : l10n.startChallenge,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmIcon() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.error.withValues(alpha: 0.22),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: const Icon(Icons.alarm, size: 72, color: AppTheme.error),
      ),
    );
  }

  String _formattedTime(models.TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _challengeName(
    AppLocalizations l10n,
    models.WakeUpChallenge challenge,
  ) {
    switch (challenge) {
      case models.WakeUpChallenge.math:
        return l10n.challengeMath;
      case models.WakeUpChallenge.voiceRecognition:
        return l10n.challengeVoice;
      case models.WakeUpChallenge.shake:
        return l10n.challengeShake;
      case models.WakeUpChallenge.steps:
        return l10n.challengeSteps;
      case models.WakeUpChallenge.none:
        return l10n.challengeNone;
    }
  }

  String _difficultyText(AppLocalizations l10n, int difficulty) {
    switch (difficulty) {
      case 1:
        return l10n.difficultyEasy;
      case 2:
        return l10n.difficultyNormal;
      default:
        return l10n.difficultyHard;
    }
  }
}
