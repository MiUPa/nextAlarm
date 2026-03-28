import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'models/alarm.dart' show WakeUpChallenge;
import 'services/alarm_service.dart';
import 'services/alarm_settings_service.dart';
import 'services/app_navigation_service.dart';
import 'services/locale_service.dart';
import 'screens/home_screen.dart';
import 'screens/alarm_entry_screen.dart';
import 'screens/alarm_ringing_screen.dart';
import 'theme/app_theme.dart';

/// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Initialize notifications for Android
Future<void> _initializeNotifications() async {
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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await _initializeNotifications();

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
        ChangeNotifierProvider(create: (_) => AlarmSettingsService()),
        ChangeNotifierProxyProvider<AlarmSettingsService, AlarmService>(
          create: (_) => AlarmService(),
          update: (_, alarmSettings, alarmService) {
            alarmService ??= AlarmService();
            alarmService.updateSettings(alarmSettings);
            return alarmService;
          },
        ),
        ChangeNotifierProvider(create: (_) => LocaleService()),
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
          if (ringingAlarm.challenge != WakeUpChallenge.none ||
              alarmService.ringingUiStage == AlarmRingingUiStage.challenge) {
            return AlarmRingingScreen(alarm: ringingAlarm);
          }
          return AlarmEntryScreen(alarm: ringingAlarm);
        }

        // Show home screen
        return const HomeScreen();
      },
    );
  }
}
