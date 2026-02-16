import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/alarm_service.dart';
import 'services/app_navigation_service.dart';
import 'services/alarm_settings_service.dart';
import 'services/locale_service.dart';
import 'screens/home_screen.dart';
import 'screens/alarm_ringing_screen.dart';
import 'theme/app_theme.dart';

/// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Request microphone permission at app startup for voice recognition challenge
Future<void> _requestMicrophonePermission() async {
  if (kIsWeb) return; // Skip on web platform

  final status = await Permission.microphone.status;
  if (status.isDenied) {
    await Permission.microphone.request();
  }
}

/// Initialize notifications for Android
Future<void> _initializeNotifications() async {
  if (kIsWeb) return;

  const androidSettings = AndroidInitializationSettings(
    '@mipmap/launcher_icon',
  );
  const initSettings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Notification was tapped - app will show alarm screen via AlarmMonitor
      debugPrint('Notification tapped: ${response.payload}');
    },
  );

  // Request notification permission for Android 13+
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await _initializeNotifications();

  // Request microphone permission at startup for voice recognition challenge
  await _requestMicrophonePermission();

  // Set system UI overlay style for status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const NextAlarmApp());
}

class NextAlarmApp extends StatelessWidget {
  const NextAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlarmService()),
        ChangeNotifierProvider(create: (_) => LocaleService()),
        ChangeNotifierProvider(create: (_) => AlarmSettingsService()),
      ],
      child: Consumer<LocaleService>(
        builder: (context, localeService, child) {
          return MaterialApp(
            title: 'NextAlarm',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppNavigationService.navigatorKey,
            theme: AppTheme.darkTheme,
            locale: localeService.locale,
            supportedLocales: LocaleService.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AlarmMonitor(),
          );
        },
      ),
    );
  }
}

class AlarmMonitor extends StatelessWidget {
  const AlarmMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmService>(
      builder: (context, alarmService, child) {
        final ringingAlarm = alarmService.ringingAlarm;

        if (ringingAlarm != null) {
          // Show alarm ringing screen
          return AlarmRingingScreen(alarm: ringingAlarm);
        }

        // Show home screen
        return const HomeScreen();
      },
    );
  }
}
