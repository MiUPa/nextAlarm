import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/alarm_service.dart';
import '../services/android_alarm_platform_service.dart';
import '../services/app_update_service.dart';
import '../services/review_prompt_service.dart';
import '../models/alarm.dart' as models;
import '../theme/app_theme.dart';
import 'alarm_edit_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
	const HomeScreen({super.key});

	@override
	State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
	late AnimationController _fabController;
	Timer? _appUpdateTimer;
	Timer? _reviewPromptTimer;
	Timer? _androidReliabilityTimer;

	@override
	void initState() {
		super.initState();
		_fabController = AnimationController(
			duration: const Duration(milliseconds: 300),
			vsync: this,
		);
		_fabController.forward();

		// Check for app updates on Android
		_checkForAppUpdate();
		_checkAndroidAlarmReliability();

		// Check if review prompt should be shown
		_checkReviewPrompt();
	}

	void _checkForAppUpdate() {
		// Wait for the first frame to ensure context is ready.
		_appUpdateTimer?.cancel();
		_appUpdateTimer = Timer(const Duration(seconds: 2), () async {
			if (!mounted) return;
			await AppUpdateService.checkForUpdate(context);
		});
	}

	void _checkReviewPrompt() {
		// Wait for the UI to settle.
		_reviewPromptTimer?.cancel();
		_reviewPromptTimer = Timer(const Duration(seconds: 2), () async {
			if (!mounted) return;

			final shouldShow = await ReviewPromptService.shouldShowPrompt();
			if (shouldShow && mounted) {
				_showReviewDialog();
			}
		});
	}

	void _checkAndroidAlarmReliability() {
		if (defaultTargetPlatform != TargetPlatform.android) return;
		_androidReliabilityTimer?.cancel();
		_androidReliabilityTimer = Timer(const Duration(seconds: 2), () async {
			if (!mounted) return;
			final canScheduleExactAlarms =
					await AndroidAlarmPlatformService.canScheduleExactAlarms();
			final notificationsEnabled =
					await AndroidAlarmPlatformService.areNotificationsEnabled();
			final canUseFullScreenIntent =
					await AndroidAlarmPlatformService.canUseFullScreenIntent();
			if (!mounted) return;
			if (canScheduleExactAlarms &&
					notificationsEnabled &&
					canUseFullScreenIntent) {
				return;
			}

			ScaffoldMessenger.of(context)
				..hideCurrentSnackBar()
				..showSnackBar(
					SnackBar(
						content: const Text(
							'Android alarm reliability settings need attention.',
						),
						action: SnackBarAction(
							label: 'Settings',
							onPressed: () => _openSettings(context),
						),
						duration: const Duration(seconds: 8),
					),
				);
		});
	}

	void _showReviewDialog() {
		final l10n = AppLocalizations.of(context)!;

		showDialog(
			context: context,
			builder: (context) => AlertDialog(
				backgroundColor: AppTheme.surface,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(20),
				),
				title: Row(
					children: [
						const Icon(Icons.star_rounded, color: AppTheme.warning, size: 28),
						const SizedBox(width: 10),
						Expanded(
							child: Text(
								l10n.reviewPromptTitle,
								style: const TextStyle(
									color: AppTheme.onSurface,
									fontSize: 20,
									fontWeight: FontWeight.w600,
								),
							),
						),
					],
				),
				content: Text(
					l10n.reviewPromptMessage,
					style: const TextStyle(
						color: AppTheme.onSurfaceSecondary,
						fontSize: 15,
						height: 1.4,
					),
				),
				actionsAlignment: MainAxisAlignment.center,
				actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
				actions: [
					Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							// Rate Now → triggers in-app review
							ElevatedButton(
								onPressed: () {
									Navigator.of(context).pop();
									ReviewPromptService.rateNow();
								},
								style: ElevatedButton.styleFrom(
									backgroundColor: AppTheme.primary,
									foregroundColor: Colors.white,
									padding: const EdgeInsets.symmetric(vertical: 14),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(12),
									),
								),
								child: Text(
									l10n.reviewPromptRate,
									style: const TextStyle(
										fontSize: 16,
										fontWeight: FontWeight.w600,
									),
								),
							),
							const SizedBox(height: 4),
							// Later
							TextButton(
								onPressed: () {
									Navigator.of(context).pop();
									ReviewPromptService.remindLater();
								},
								child: Text(
									l10n.reviewPromptLater,
									style: const TextStyle(
										color: AppTheme.primary,
										fontSize: 15,
										fontWeight: FontWeight.w500,
									),
								),
							),
							// Don't show again
							TextButton(
								onPressed: () {
									Navigator.of(context).pop();
									ReviewPromptService.dismiss();
								},
								child: Text(
									l10n.reviewPromptDismiss,
									style: TextStyle(
										color: AppTheme.onSurfaceSecondary.withValues(alpha: 0.7),
										fontSize: 13,
										fontWeight: FontWeight.w400,
									),
								),
							),
						],
					),
				],
			),
		);
	}

	@override
	void dispose() {
		_appUpdateTimer?.cancel();
		_reviewPromptTimer?.cancel();
		_androidReliabilityTimer?.cancel();
		_fabController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;

		return Scaffold(
			body: CustomScrollView(
				slivers: [
					// Apple-style large title
					SliverAppBar(
						expandedHeight: 120,
						floating: false,
						pinned: true,
						backgroundColor: Colors.transparent,
						actions: [
							IconButton(
								icon: const Icon(Icons.settings, color: AppTheme.onSurface),
								onPressed: () => _openSettings(context),
							),
						],
						flexibleSpace: FlexibleSpaceBar(
							titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
							title: Text(
								l10n.alarms,
								style: const TextStyle(
									fontSize: 13,
									fontWeight: FontWeight.w400,
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
											AppTheme.background.withValues(alpha: 0),
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
													color: AppTheme.onSurfaceSecondary.withValues(alpha: 0.5),
												),
												const SizedBox(height: 24),
												Text(
													l10n.noAlarmsYet,
													style: Theme.of(context).textTheme.titleLarge?.copyWith(
														color: AppTheme.onSurfaceSecondary,
													),
												),
												const SizedBox(height: 8),
												Text(
													l10n.tapToCreateAlarm,
													style: Theme.of(context).textTheme.bodyMedium?.copyWith(
														color: AppTheme.onSurfaceSecondary.withValues(alpha: 0.7),
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
												onConfirmDelete: () => _confirmDeleteAlarm(context),
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
					child: FloatingActionButton(
						onPressed: () => _addAlarm(context),
						elevation: 8,
						child: const Icon(Icons.add, size: 24),
					),
				),
			);
		}

	void _openSettings(BuildContext context) {
		Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => const SettingsScreen(),
			),
		);
	}

	void _addAlarm(BuildContext context) async {
		await Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => const AlarmEditScreen(),
				fullscreenDialog: true,
			),
		);
	}

	void _editAlarm(BuildContext context, models.Alarm alarm) async {
		await Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => AlarmEditScreen(alarm: alarm),
				fullscreenDialog: true,
			),
		);
	}

	void _toggleAlarm(String id) {
		context.read<AlarmService>().toggleAlarm(id);
	}

	Future<bool> _confirmDeleteAlarm(BuildContext context) async {
		final l10n = AppLocalizations.of(context)!;

		final result = await showDialog<bool>(
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

		return result ?? false;
	}

	void _deleteAlarm(String id) {
		context.read<AlarmService>().deleteAlarm(id);
	}
}

class _AlarmCard extends StatefulWidget {
	final models.Alarm alarm;
	final VoidCallback onTap;
	final VoidCallback onToggle;
	final VoidCallback onDelete;
	final Future<bool> Function() onConfirmDelete;

	const _AlarmCard({
		required this.alarm,
		required this.onTap,
		required this.onToggle,
		required this.onDelete,
		required this.onConfirmDelete,
	});

	@override
	State<_AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<_AlarmCard>
		with SingleTickerProviderStateMixin {
	late AnimationController _controller;

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
		final l10n = AppLocalizations.of(context)!;
		final alarmService = context.watch<AlarmService>();
		final timeUntil = _getLocalizedTimeUntil(l10n, alarmService, widget.alarm);

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
					_controller.forward();
				},
				onTapUp: (_) {
					_controller.reverse();
					widget.onTap();
				},
				onTapCancel: () {
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
						confirmDismiss: (_) => widget.onConfirmDelete(),
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
															_getLocalizedRepeatText(l10n, widget.alarm),
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
																_getLocalizedChallengeText(l10n, widget.alarm),
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
																color: AppTheme.primary.withValues(alpha: 0.15),
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

	String _getLocalizedRepeatText(AppLocalizations l10n, models.Alarm alarm) {
		if (alarm.repeatDays.isEmpty) {
			return l10n.repeatOnce;
		}

		if (alarm.repeatDays.length == 7) {
			return l10n.repeatEveryDay;
		}

		final weekdays = {1, 2, 3, 4, 5};
		final weekends = {6, 7};

		if (alarm.repeatDays.containsAll(weekdays) && alarm.repeatDays.length == 5) {
			return l10n.repeatWeekdays;
		}

		if (alarm.repeatDays.containsAll(weekends) && alarm.repeatDays.length == 2) {
			return l10n.repeatWeekends;
		}

		final dayNames = [
			l10n.dayMonday,
			l10n.dayTuesday,
			l10n.dayWednesday,
			l10n.dayThursday,
			l10n.dayFriday,
			l10n.daySaturday,
			l10n.daySunday,
		];

		final sortedDays = alarm.repeatDays.toList()..sort();
		return sortedDays.map((d) => dayNames[d - 1]).join(' ');
	}

	String _getLocalizedChallengeText(AppLocalizations l10n, models.Alarm alarm) {
		String challengeName;
		switch (alarm.challenge) {
			case models.WakeUpChallenge.math:
				challengeName = l10n.challengeMath;
				break;
			case models.WakeUpChallenge.voiceRecognition:
				challengeName = l10n.challengeVoice;
				break;
			case models.WakeUpChallenge.shake:
				challengeName = l10n.challengeShake;
				break;
			case models.WakeUpChallenge.steps:
				challengeName = l10n.challengeSteps;
				break;
			default:
				challengeName = l10n.challengeNone;
		}

		String difficultyName;
		switch (alarm.challengeDifficulty) {
			case 1:
				difficultyName = l10n.difficultyEasy;
				break;
			case 3:
				difficultyName = l10n.difficultyHard;
				break;
			default:
				difficultyName = l10n.difficultyNormal;
		}

		return '$challengeName ($difficultyName)';
	}

	String _getLocalizedTimeUntil(AppLocalizations l10n, AlarmService alarmService, models.Alarm alarm) {
		if (!alarm.isEnabled) {
			return '';
		}

		final next = alarmService.calculateNextAlarmTime(alarm);
		final diff = next.difference(DateTime.now());

		if (diff.inHours > 24) {
			final days = diff.inDays;
			return l10n.inDays(days);
		}

		if (diff.inHours > 0) {
			final hours = diff.inHours;
			final minutes = diff.inMinutes % 60;
			if (minutes > 0) {
				return l10n.inHoursMinutes(hours, minutes);
			}
			return l10n.inHours(hours);
		}

		final minutes = diff.inMinutes;
		return l10n.inMinutes(minutes);
	}
}
