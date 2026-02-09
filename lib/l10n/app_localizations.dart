import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'NextAlarm'**
  String get appTitle;

  /// Title for the alarms list screen
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarms;

  /// No description provided for @noAlarmsYet.
  ///
  /// In en, this message translates to:
  /// **'No alarms yet'**
  String get noAlarmsYet;

  /// No description provided for @tapToCreateAlarm.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first alarm'**
  String get tapToCreateAlarm;

  /// No description provided for @addAlarm.
  ///
  /// In en, this message translates to:
  /// **'Add Alarm'**
  String get addAlarm;

  /// No description provided for @editAlarm.
  ///
  /// In en, this message translates to:
  /// **'Edit Alarm'**
  String get editAlarm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @labelHint.
  ///
  /// In en, this message translates to:
  /// **'Alarm name'**
  String get labelHint;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @wakeUpChallenge.
  ///
  /// In en, this message translates to:
  /// **'Wake-up Challenge'**
  String get wakeUpChallenge;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @challengeNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get challengeNone;

  /// No description provided for @challengeMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get challengeMath;

  /// No description provided for @challengeVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get challengeVoice;

  /// No description provided for @challengeShake.
  ///
  /// In en, this message translates to:
  /// **'Shake'**
  String get challengeShake;

  /// No description provided for @challengeSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get challengeSteps;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get difficultyNormal;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get daySunday;

  /// No description provided for @repeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get repeatOnce;

  /// No description provided for @repeatEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatEveryDay;

  /// No description provided for @repeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get repeatWeekends;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'in {count} {count, plural, =1{day} other{days}}'**
  String inDays(int count);

  /// No description provided for @inHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {hours}h {minutes}m'**
  String inHoursMinutes(int hours, int minutes);

  /// No description provided for @inHours.
  ///
  /// In en, this message translates to:
  /// **'in {count} {count, plural, =1{hour} other{hours}}'**
  String inHours(int count);

  /// No description provided for @inMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {count} {count, plural, =1{minute} other{minutes}}'**
  String inMinutes(int count);

  /// No description provided for @stopAlarm.
  ///
  /// In en, this message translates to:
  /// **'Stop Alarm'**
  String get stopAlarm;

  /// No description provided for @solveMathToStop.
  ///
  /// In en, this message translates to:
  /// **'Solve the math problem to stop the alarm'**
  String get solveMathToStop;

  /// No description provided for @enterAnswer.
  ///
  /// In en, this message translates to:
  /// **'Enter answer'**
  String get enterAnswer;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @wrongAnswer.
  ///
  /// In en, this message translates to:
  /// **'Wrong! Try again.'**
  String get wrongAnswer;

  /// No description provided for @shakeToStop.
  ///
  /// In en, this message translates to:
  /// **'Shake your phone to stop the alarm'**
  String get shakeToStop;

  /// No description provided for @shakesCount.
  ///
  /// In en, this message translates to:
  /// **'{current} / {required}'**
  String shakesCount(int current, int required);

  /// No description provided for @speakToStop.
  ///
  /// In en, this message translates to:
  /// **'Say the phrase to stop the alarm'**
  String get speakToStop;

  /// No description provided for @tapMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Tap microphone'**
  String get tapMicrophone;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @recognized.
  ///
  /// In en, this message translates to:
  /// **'Recognized: {text}'**
  String recognized(String text);

  /// No description provided for @speechNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available'**
  String get speechNotAvailable;

  /// No description provided for @walkToStop.
  ///
  /// In en, this message translates to:
  /// **'Walk to stop the alarm'**
  String get walkToStop;

  /// No description provided for @stepsCount.
  ///
  /// In en, this message translates to:
  /// **'{current} / {required} steps'**
  String stepsCount(int current, int required);

  /// No description provided for @challengeNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'This challenge is not implemented yet'**
  String get challengeNotImplemented;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// No description provided for @tongueTwister1.
  ///
  /// In en, this message translates to:
  /// **'Peter Piper picked a peck of pickled peppers'**
  String get tongueTwister1;

  /// No description provided for @tongueTwister2.
  ///
  /// In en, this message translates to:
  /// **'She sells seashells by the seashore'**
  String get tongueTwister2;

  /// No description provided for @tongueTwister3.
  ///
  /// In en, this message translates to:
  /// **'How much wood would a woodchuck chuck'**
  String get tongueTwister3;

  /// No description provided for @tongueTwister4.
  ///
  /// In en, this message translates to:
  /// **'Red lorry yellow lorry'**
  String get tongueTwister4;

  /// No description provided for @tongueTwister5.
  ///
  /// In en, this message translates to:
  /// **'Unique New York'**
  String get tongueTwister5;

  /// No description provided for @alarmSound.
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound'**
  String get alarmSound;

  /// No description provided for @soundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get soundDefault;

  /// No description provided for @soundGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get soundGentle;

  /// No description provided for @soundDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get soundDigital;

  /// No description provided for @soundClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get soundClassic;

  /// No description provided for @soundNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get soundNature;

  /// No description provided for @soundSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get soundSilent;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrationOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get vibrationOn;

  /// No description provided for @vibrationOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get vibrationOff;

  /// No description provided for @gradualVolume.
  ///
  /// In en, this message translates to:
  /// **'Gradual Volume'**
  String get gradualVolume;

  /// No description provided for @gradualVolumeDescription.
  ///
  /// In en, this message translates to:
  /// **'Slowly increase volume'**
  String get gradualVolumeDescription;

  /// No description provided for @deleteAlarm.
  ///
  /// In en, this message translates to:
  /// **'Delete Alarm'**
  String get deleteAlarm;

  /// No description provided for @deleteAlarmConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this alarm?'**
  String get deleteAlarmConfirmation;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @reviewPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoying NextAlarm?'**
  String get reviewPromptTitle;

  /// No description provided for @reviewPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'If you like this app, please take a moment to rate it. Your feedback helps us improve!'**
  String get reviewPromptMessage;

  /// No description provided for @reviewPromptRate.
  ///
  /// In en, this message translates to:
  /// **'Rate Now'**
  String get reviewPromptRate;

  /// No description provided for @reviewPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get reviewPromptLater;

  /// No description provided for @reviewPromptDismiss.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again'**
  String get reviewPromptDismiss;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
