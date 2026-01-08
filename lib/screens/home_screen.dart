import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../services/alarm_service.dart';
import '../services/notification_service_web.dart';
import '../models/alarm.dart' as models;
import '../theme/app_theme.dart';
import 'alarm_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController.forward();

    // Request notification permission on Web
    if (kIsWeb) {
      _requestNotificationPermission();
    }
  }

  Future<void> _requestNotificationPermission() async {
    // Wait a bit for the UI to load
    await Future.delayed(const Duration(seconds: 1));
    await NotificationServiceWeb.requestPermission();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Apple-style large title
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Alarms',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.background,
                      AppTheme.background.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Alarm list
          Consumer<AlarmService>(
            builder: (context, alarmService, child) {
              if (alarmService.alarms.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.alarm_off_outlined,
                          size: 80,
                          color: AppTheme.onSurfaceSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No alarms yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.onSurfaceSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first alarm',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final alarm = alarmService.alarms[index];
                      return _AlarmCard(
                        alarm: alarm,
                        onTap: () => _editAlarm(context, alarm),
                        onToggle: () => _toggleAlarm(alarm.id),
                        onDelete: () => _deleteAlarm(alarm.id),
                      );
                    },
                    childCount: alarmService.alarms.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // Floating Action Button with scale animation
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.large(
          onPressed: () => _addAlarm(context),
          elevation: 8,
          child: const Icon(Icons.add, size: 32),
        ),
      ),
    );
  }

  void _addAlarm(BuildContext context) async {
    Vibration.vibrate(duration: 10);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AlarmEditScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _editAlarm(BuildContext context, models.Alarm alarm) async {
    Vibration.vibrate(duration: 10);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(alarm: alarm),
        fullscreenDialog: true,
      ),
    );
  }

  void _toggleAlarm(String id) {
    Vibration.vibrate(duration: 10);
    context.read<AlarmService>().toggleAlarm(id);
  }

  void _deleteAlarm(String id) {
    Vibration.vibrate(duration: 20, amplitude: 128);
    context.read<AlarmService>().deleteAlarm(id);
  }
}

class _AlarmCard extends StatefulWidget {
  final models.Alarm alarm;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AlarmCard({
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<_AlarmCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alarmService = context.watch<AlarmService>();
    final timeUntil = alarmService.getTimeUntilAlarm(widget.alarm);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 - (_controller.value * 0.02);

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.alarm.isEnabled ? AppTheme.softShadow : null,
          ),
          child: Dismissible(
            key: Key(widget.alarm.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => widget.onDelete(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Time and info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time
                        Text(
                          widget.alarm.formattedTime,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w300,
                            fontSize: 56,
                            height: 1.0,
                            color: widget.alarm.isEnabled
                                ? AppTheme.onSurface
                                : AppTheme.onSurfaceSecondary,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Label
                        if (widget.alarm.label.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              widget.alarm.label,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: widget.alarm.isEnabled
                                    ? AppTheme.onSurface
                                    : AppTheme.onSurfaceSecondary,
                              ),
                            ),
                          ),

                        // Repeat days
                        Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 14,
                              color: AppTheme.onSurfaceSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.alarm.repeatText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Challenge
                        if (widget.alarm.challenge != models.WakeUpChallenge.none)
                          Row(
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                size: 14,
                                color: AppTheme.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.alarm.challengeText,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),

                        // Time until alarm
                        if (widget.alarm.isEnabled && timeUntil.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                timeUntil,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Toggle switch
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: widget.alarm.isEnabled,
                      onChanged: (_) => widget.onToggle(),
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
}
