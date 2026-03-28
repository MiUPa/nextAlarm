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
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF191C30), Color(0xFF142544), Color(0xFF0B3B63)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: _StatusPill(
                      icon: Icons.notifications_active_rounded,
                      label: l10n.alarmIsRinging,
                    ),
                  ),
                  const Spacer(),
                  _buildAlarmIcon(),
                  const SizedBox(height: 28),
                  Text(
                    _formattedTime(alarm.time),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: -3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (alarm.label.trim().isNotEmpty) ...[
                    _MessageCard(
                      icon: Icons.flag_rounded,
                      title: alarm.label.trim(),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    l10n.stopAlarm,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.error.withValues(alpha: 0.32),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AlarmService>().stopRingingAlarm();
                      },
                      icon: const Icon(Icons.alarm_off_rounded),
                      label: Text(l10n.stopAlarm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
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
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.error.withValues(alpha: 0.18),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.52),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withValues(alpha: 0.16),
              blurRadius: 28,
              spreadRadius: 8,
            ),
          ],
        ),
        child: const Icon(Icons.alarm_rounded, size: 72, color: AppTheme.error),
      ),
    );
  }

  String _formattedTime(models.TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.warning),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
