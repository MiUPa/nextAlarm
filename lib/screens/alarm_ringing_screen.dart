import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmRingingScreen extends StatefulWidget {
	final Alarm alarm;

	const AlarmRingingScreen({
		super.key,
		required this.alarm,
	});

	@override
	State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
		with SingleTickerProviderStateMixin {
	late AnimationController _pulseController;
	int _mathAnswer = 0;
	late int _correctAnswer;
	late String _mathQuestion;

	// Shake challenge
	StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
	int _shakeCount = 0;
	int _requiredShakes = 0;
	DateTime _lastShakeTime = DateTime.now();

	// Speech challenge
	final stt.SpeechToText _speech = stt.SpeechToText();
	String _targetPhrase = '';
	String _recognizedText = '';
	bool _isListening = false;

	// Step challenge
	StreamSubscription<StepCount>? _stepSubscription;
	int _initialSteps = 0;
	bool _initialStepsSet = false;
	int _currentSteps = 0;
	int _requiredSteps = 0;
	String? _stepError;

	@override
	void initState() {
		super.initState();
		_pulseController = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 1000),
		)..repeat(reverse: true);

		_initializeChallenge();
	}

	void _initializeChallenge() {
		switch (widget.alarm.challenge) {
			case WakeUpChallenge.math:
				_generateMathProblem();
				break;
			case WakeUpChallenge.shake:
				_initShakeChallenge();
				break;
			case WakeUpChallenge.voiceRecognition:
				_initSpeechChallenge();
				break;
			case WakeUpChallenge.steps:
				_initStepChallenge();
				break;
			default:
				break;
		}
	}

	@override
	void dispose() {
		_pulseController.dispose();
		_accelerometerSubscription?.cancel();
		_stepSubscription?.cancel();
		super.dispose();
	}

	void _generateMathProblem() {
		final random = math.Random();
		final difficulty = widget.alarm.challengeDifficulty;

		if (difficulty == 1) {
			// Easy: 2-digit addition/subtraction
			final a = random.nextInt(80) + 20; // 20-99
			final b = random.nextInt(80) + 20; // 20-99
			if (random.nextBool()) {
				_mathQuestion = '$a + $b = ?';
				_correctAnswer = a + b;
			} else {
				final larger = a > b ? a : b;
				final smaller = a > b ? b : a;
				_mathQuestion = '$larger - $smaller = ?';
				_correctAnswer = larger - smaller;
			}
		} else if (difficulty == 2) {
			// Normal: 2-digit x 1-digit or 3-digit addition/subtraction
			if (random.nextBool()) {
				final a = random.nextInt(30) + 10; // 10-39
				final b = random.nextInt(9) + 2; // 2-10
				_mathQuestion = '$a × $b = ?';
				_correctAnswer = a * b;
			} else {
				final a = random.nextInt(300) + 100; // 100-399
				final b = random.nextInt(200) + 50; // 50-249
				if (random.nextBool()) {
					_mathQuestion = '$a + $b = ?';
					_correctAnswer = a + b;
				} else {
					_mathQuestion = '$a - $b = ?';
					_correctAnswer = a - b;
				}
			}
		} else {
			// Hard: Complex operations
			final a = random.nextInt(50) + 20; // 20-69
			final b = random.nextInt(9) + 2; // 2-10
			final c = random.nextInt(50) + 10; // 10-59
			final operations = [
				() {
					final x = random.nextInt(20) + 10; // 10-29
					final y = random.nextInt(20) + 10; // 10-29
					_mathQuestion = '$x × $y = ?';
					_correctAnswer = x * y;
				},
				() {
					_mathQuestion = '$a × $b + $c = ?';
					_correctAnswer = a * b + c;
				},
				() {
					_mathQuestion = '$a × $b - $c = ?';
					_correctAnswer = a * b - c;
				},
				() {
					final d = random.nextInt(30) + 10;
					_mathQuestion = '$a + $b × $c - $d = ?';
					_correctAnswer = a + b * c - d;
				},
			];
			operations[random.nextInt(operations.length)]();
		}
		debugPrint('Math problem: $_mathQuestion, Correct answer: $_correctAnswer');
	}

	void _checkAnswer() {
		final l10n = AppLocalizations.of(context)!;
		if (_mathAnswer == _correctAnswer) {
			_stopAlarm();
		} else {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(l10n.wrongAnswer),
					backgroundColor: AppTheme.error,
					duration: const Duration(seconds: 2),
				),
			);
			setState(() {
				_mathAnswer = 0;
			});
		}
	}

	void _stopAlarm() {
		final alarmService = Provider.of<AlarmService>(context, listen: false);
		alarmService.stopRingingAlarm();
	}

	// === Shake Challenge ===
	void _initShakeChallenge() {
		final difficulty = widget.alarm.challengeDifficulty;
		_requiredShakes = 5 + (difficulty * 10); // 15/25/35 shakes based on difficulty

		_accelerometerSubscription = accelerometerEventStream().listen((event) {
			final acceleration = math.sqrt(
				event.x * event.x + event.y * event.y + event.z * event.z,
			);

			if (acceleration > 15) {
				final now = DateTime.now();
				if (now.difference(_lastShakeTime).inMilliseconds > 300) {
					setState(() {
						_shakeCount++;
						_lastShakeTime = now;
					});

					if (_shakeCount >= _requiredShakes) {
						_stopAlarm();
					}
				}
			}
		});
	}

	// === Speech Challenge ===
	void _initSpeechChallenge() {
		// Get locale-specific phrases
		WidgetsBinding.instance.addPostFrameCallback((_) {
			final l10n = AppLocalizations.of(context)!;
			final localeService = context.read<LocaleService>();
			final effectiveLocale = localeService.getEffectiveLocale(context);

			List<String> phrases;
			if (effectiveLocale.languageCode == 'ja') {
				phrases = [
					l10n.tongueTwister1,
					l10n.tongueTwister2,
					l10n.tongueTwister3,
					l10n.tongueTwister4,
					l10n.tongueTwister5,
				];
			} else {
				phrases = [
					l10n.tongueTwister1,
					l10n.tongueTwister2,
					l10n.tongueTwister3,
					l10n.tongueTwister4,
					l10n.tongueTwister5,
				];
			}

			final random = math.Random();
			setState(() {
				_targetPhrase = phrases[random.nextInt(phrases.length)];
			});
		});

		_initializeSpeechRecognition();
	}

	Future<void> _initializeSpeechRecognition() async {
		final available = await _speech.initialize();
		if (!available && mounted) {
			final l10n = AppLocalizations.of(context)!;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(l10n.speechNotAvailable)),
			);
		}
	}

	void _startListening() async {
		final localeService = context.read<LocaleService>();
		final effectiveLocale = localeService.getEffectiveLocale(context);
		final localeId = effectiveLocale.languageCode == 'ja' ? 'ja_JP' : 'en_US';

		if (!_isListening) {
			setState(() {
				_isListening = true;
				_recognizedText = '';
			});

			await _speech.listen(
				onResult: (result) {
					setState(() {
						_recognizedText = result.recognizedWords;
					});

					if (_recognizedText.toLowerCase().contains(_targetPhrase.toLowerCase())) {
						_stopAlarm();
					}
				},
				localeId: localeId,
			);
		}
	}

	void _stopListening() async {
		if (_isListening) {
			await _speech.stop();
			setState(() {
				_isListening = false;
			});
		}
	}

	// === Step Challenge ===
	Future<void> _initStepChallenge() async {
		final difficulty = widget.alarm.challengeDifficulty;
		_requiredSteps = 5 + (difficulty * 10); // 15/25/35 steps based on difficulty

		// Request activity recognition permission on Android 10+
		if (!kIsWeb) {
			final status = await Permission.activityRecognition.status;
			if (status.isDenied) {
				final result = await Permission.activityRecognition.request();
				if (!result.isGranted) {
					if (mounted) {
						setState(() {
							_stepError = 'permission_denied';
						});
					}
					return;
				}
			} else if (status.isPermanentlyDenied) {
				if (mounted) {
					setState(() {
						_stepError = 'permission_denied';
					});
				}
				return;
			}
		}

		if (!mounted) return;

		_stepSubscription = Pedometer.stepCountStream.listen(
			(event) {
				if (!mounted) return;
				if (!_initialStepsSet) {
					// Subtract 1 so the step that triggered this first event counts
					_initialSteps = event.steps - 1;
					_initialStepsSet = true;
				}
				setState(() {
					_currentSteps = event.steps - _initialSteps;
				});

				if (_currentSteps >= _requiredSteps) {
					_stepSubscription?.cancel();
					_stopAlarm();
				}
			},
			onError: (error) {
				if (!mounted) return;
				setState(() {
					_stepError = error.toString();
				});
			},
		);
	}

	Widget _buildChallengeContent() {
		switch (widget.alarm.challenge) {
			case WakeUpChallenge.math:
				return _buildMathChallenge();
			case WakeUpChallenge.voiceRecognition:
				return _buildSpeechChallenge();
			case WakeUpChallenge.shake:
				return _buildShakeChallenge();
			case WakeUpChallenge.steps:
				return _buildStepChallenge();
			default:
				return _buildSimpleStop();
		}
	}

	Widget _buildMathChallenge() {
		final l10n = AppLocalizations.of(context)!;
		return Column(
			mainAxisSize: MainAxisSize.min,
			children: [
				Text(
					l10n.solveMathToStop,
					style: const TextStyle(
						fontSize: 18,
						fontWeight: FontWeight.w500,
						color: Colors.white70,
					),
				),
				const SizedBox(height: 40),
				Text(
					_mathQuestion,
					style: const TextStyle(
						fontSize: 48,
						fontWeight: FontWeight.w300,
						color: Colors.white,
					),
				),
				const SizedBox(height: 40),
				Container(
					padding: const EdgeInsets.symmetric(horizontal: 40),
					child: TextField(
						autofocus: true,
						keyboardType: TextInputType.number,
						textAlign: TextAlign.center,
						style: const TextStyle(
							fontSize: 36,
							fontWeight: FontWeight.w600,
							color: Colors.white,
						),
						decoration: InputDecoration(
							hintText: l10n.enterAnswer,
							hintStyle: TextStyle(
								color: Colors.white.withOpacity(0.3),
							),
							enabledBorder: const UnderlineInputBorder(
								borderSide: BorderSide(color: Colors.white, width: 2),
							),
							focusedBorder: const UnderlineInputBorder(
								borderSide: BorderSide(color: AppTheme.primary, width: 3),
							),
						),
						onChanged: (value) {
							setState(() {
								_mathAnswer = int.tryParse(value) ?? 0;
							});
						},
						onSubmitted: (_) => _checkAnswer(),
					),
				),
				const SizedBox(height: 40),
				ElevatedButton(
					onPressed: _mathAnswer != 0 ? _checkAnswer : null,
					style: ElevatedButton.styleFrom(
						backgroundColor: AppTheme.primary,
						foregroundColor: Colors.white,
						padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(30),
						),
					),
					child: Text(
						l10n.confirm,
						style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
					),
				),
			],
		);
	}

	Widget _buildSimpleStop() {
		final l10n = AppLocalizations.of(context)!;
		return Column(
			mainAxisSize: MainAxisSize.min,
			children: [
				ElevatedButton(
					onPressed: _stopAlarm,
					style: ElevatedButton.styleFrom(
						backgroundColor: AppTheme.error,
						foregroundColor: Colors.white,
						padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(30),
						),
					),
					child: Text(
						l10n.stopAlarm,
						style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
					),
				),
			],
		);
	}

	Widget _buildShakeChallenge() {
		final l10n = AppLocalizations.of(context)!;
		final progress = _shakeCount / _requiredShakes;
		return Column(
			mainAxisSize: MainAxisSize.min,
			children: [
				Text(
					l10n.shakeToStop,
					style: const TextStyle(
						fontSize: 18,
						fontWeight: FontWeight.w500,
						color: Colors.white70,
					),
				),
				const SizedBox(height: 40),
				Icon(
					Icons.phone_android,
					size: 80,
					color: Colors.white.withOpacity(0.8),
				),
				const SizedBox(height: 40),
				Text(
					l10n.shakesCount(_shakeCount, _requiredShakes),
					style: const TextStyle(
						fontSize: 48,
						fontWeight: FontWeight.w300,
						color: Colors.white,
					),
				),
				const SizedBox(height: 20),
				Container(
					width: 200,
					height: 10,
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(5),
						color: Colors.white.withOpacity(0.2),
					),
					child: FractionallySizedBox(
						alignment: Alignment.centerLeft,
						widthFactor: progress,
						child: Container(
							decoration: BoxDecoration(
								borderRadius: BorderRadius.circular(5),
								color: AppTheme.primary,
							),
						),
					),
				),
			],
		);
	}

	Widget _buildSpeechChallenge() {
		final l10n = AppLocalizations.of(context)!;
		return Column(
			mainAxisSize: MainAxisSize.min,
			children: [
				Text(
					l10n.speakToStop,
					style: const TextStyle(
						fontSize: 18,
						fontWeight: FontWeight.w500,
						color: Colors.white70,
					),
				),
				const SizedBox(height: 40),
				Text(
					_targetPhrase,
					style: const TextStyle(
						fontSize: 32,
						fontWeight: FontWeight.w600,
						color: Colors.white,
					),
					textAlign: TextAlign.center,
				),
				const SizedBox(height: 40),
				if (_recognizedText.isNotEmpty)
					Container(
						padding: const EdgeInsets.all(16),
						decoration: BoxDecoration(
							color: Colors.white.withOpacity(0.1),
							borderRadius: BorderRadius.circular(12),
						),
						child: Text(
							l10n.recognized(_recognizedText),
							style: const TextStyle(
								fontSize: 16,
								color: Colors.white70,
							),
						),
					),
				const SizedBox(height: 40),
				ElevatedButton.icon(
					onPressed: _isListening ? _stopListening : _startListening,
					icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
					label: Text(_isListening ? l10n.listening : l10n.tapMicrophone),
					style: ElevatedButton.styleFrom(
						backgroundColor: _isListening ? AppTheme.error : AppTheme.primary,
						foregroundColor: Colors.white,
						padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(30),
						),
					),
				),
			],
		);
	}

	Widget _buildStepChallenge() {
		final l10n = AppLocalizations.of(context)!;
		final progress = _requiredSteps > 0
			? _currentSteps / _requiredSteps
			: 0.0;
		return Column(
			mainAxisSize: MainAxisSize.min,
			children: [
				Text(
					l10n.walkToStop,
					style: const TextStyle(
						fontSize: 18,
						fontWeight: FontWeight.w500,
						color: Colors.white70,
					),
				),
				const SizedBox(height: 40),
				Icon(
					Icons.directions_walk,
					size: 80,
					color: Colors.white.withOpacity(0.8),
				),
				const SizedBox(height: 40),
				if (_stepError != null) ...[
					Padding(
						padding: const EdgeInsets.only(bottom: 20),
						child: Text(
							l10n.stepSensorNotAvailable,
							style: const TextStyle(
								fontSize: 16,
								color: Colors.redAccent,
							),
							textAlign: TextAlign.center,
						),
					),
					const SizedBox(height: 20),
					ElevatedButton(
						onPressed: _stopAlarm,
						style: ElevatedButton.styleFrom(
							backgroundColor: AppTheme.error,
							foregroundColor: Colors.white,
							padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(30),
							),
						),
						child: Text(
							l10n.stopAlarm,
							style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
						),
					),
				] else ...[
					Text(
						l10n.stepsCount(_currentSteps, _requiredSteps),
						style: const TextStyle(
							fontSize: 48,
							fontWeight: FontWeight.w300,
							color: Colors.white,
						),
					),
					const SizedBox(height: 20),
					Container(
						width: 200,
						height: 10,
						decoration: BoxDecoration(
							borderRadius: BorderRadius.circular(5),
							color: Colors.white.withOpacity(0.2),
						),
						child: FractionallySizedBox(
							alignment: Alignment.centerLeft,
							widthFactor: progress.clamp(0.0, 1.0),
							child: Container(
								decoration: BoxDecoration(
									borderRadius: BorderRadius.circular(5),
									color: AppTheme.primary,
								),
							),
						),
					),
				],
			],
		);
	}

	@override
	Widget build(BuildContext context) {
		return PopScope(
			canPop: false,
			child: Scaffold(
			body: Container(
				decoration: const BoxDecoration(
					gradient: LinearGradient(
						begin: Alignment.topLeft,
						end: Alignment.bottomRight,
						colors: [
							Color(0xFF1a1a2e),
							Color(0xFF16213e),
							Color(0xFF0f3460),
						],
					),
				),
				child: SafeArea(
					child: Center(
						child: SingleChildScrollView(
							padding: const EdgeInsets.all(24),
							child: Column(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									// Pulsing alarm icon
									AnimatedBuilder(
										animation: _pulseController,
										builder: (context, child) {
											return Transform.scale(
												scale: 1.0 + (_pulseController.value * 0.2),
												child: Container(
													padding: const EdgeInsets.all(32),
													decoration: BoxDecoration(
														shape: BoxShape.circle,
														color: AppTheme.error.withOpacity(0.2),
														border: Border.all(
															color: AppTheme.error.withOpacity(0.5),
															width: 2,
														),
													),
													child: const Icon(
														Icons.alarm,
														size: 80,
														color: AppTheme.error,
													),
												),
											);
										},
									),
									const SizedBox(height: 40),

									// Time
									Text(
										'${widget.alarm.time.hour.toString().padLeft(2, '0')}:${widget.alarm.time.minute.toString().padLeft(2, '0')}',
										style: const TextStyle(
											fontSize: 72,
											fontWeight: FontWeight.w300,
											color: Colors.white,
											letterSpacing: -2,
										),
									),
									const SizedBox(height: 12),

									// Label
									Text(
										widget.alarm.label,
										style: const TextStyle(
											fontSize: 24,
											fontWeight: FontWeight.w500,
											color: Colors.white70,
										),
									),
									const SizedBox(height: 60),

									// Challenge content
									_buildChallengeContent(),
								],
							),
						),
					),
				),
			),
		));
	}
}
