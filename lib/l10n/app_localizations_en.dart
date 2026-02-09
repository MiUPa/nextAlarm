// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NextAlarm';

  @override
  String get alarms => 'Alarms';

  @override
  String get noAlarmsYet => 'No alarms yet';

  @override
  String get tapToCreateAlarm => 'Tap + to create your first alarm';

  @override
  String get addAlarm => 'Add Alarm';

  @override
  String get editAlarm => 'Edit Alarm';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get label => 'Label';

  @override
  String get labelHint => 'Alarm name';

  @override
  String get repeat => 'Repeat';

  @override
  String get wakeUpChallenge => 'Wake-up Challenge';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get challengeNone => 'None';

  @override
  String get challengeMath => 'Math';

  @override
  String get challengeVoice => 'Voice';

  @override
  String get challengeShake => 'Shake';

  @override
  String get challengeSteps => 'Steps';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyNormal => 'Normal';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get dayMonday => 'M';

  @override
  String get dayTuesday => 'T';

  @override
  String get dayWednesday => 'W';

  @override
  String get dayThursday => 'T';

  @override
  String get dayFriday => 'F';

  @override
  String get daySaturday => 'S';

  @override
  String get daySunday => 'S';

  @override
  String get repeatOnce => 'Once';

  @override
  String get repeatEveryDay => 'Every day';

  @override
  String get repeatWeekdays => 'Weekdays';

  @override
  String get repeatWeekends => 'Weekends';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return 'in $count $_temp0';
  }

  @override
  String inHoursMinutes(int hours, int minutes) {
    return 'in ${hours}h ${minutes}m';
  }

  @override
  String inHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hours',
      one: 'hour',
    );
    return 'in $count $_temp0';
  }

  @override
  String inMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return 'in $count $_temp0';
  }

  @override
  String get stopAlarm => 'Stop Alarm';

  @override
  String get solveMathToStop => 'Solve the math problem to stop the alarm';

  @override
  String get enterAnswer => 'Enter answer';

  @override
  String get confirm => 'Confirm';

  @override
  String get wrongAnswer => 'Wrong! Try again.';

  @override
  String get shakeToStop => 'Shake your phone to stop the alarm';

  @override
  String shakesCount(int current, int required) {
    return '$current / $required';
  }

  @override
  String get speakToStop => 'Say the phrase to stop the alarm';

  @override
  String get tapMicrophone => 'Tap microphone';

  @override
  String get listening => 'Listening...';

  @override
  String recognized(String text) {
    return 'Recognized: $text';
  }

  @override
  String get speechNotAvailable => 'Speech recognition not available';

  @override
  String get walkToStop => 'Walk to stop the alarm';

  @override
  String stepsCount(int current, int required) {
    return '$current / $required steps';
  }

  @override
  String get challengeNotImplemented => 'This challenge is not implemented yet';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get tongueTwister1 => 'Peter Piper picked a peck of pickled peppers';

  @override
  String get tongueTwister2 => 'She sells seashells by the seashore';

  @override
  String get tongueTwister3 => 'How much wood would a woodchuck chuck';

  @override
  String get tongueTwister4 => 'Red lorry yellow lorry';

  @override
  String get tongueTwister5 => 'Unique New York';

  @override
  String get alarmSound => 'Alarm Sound';

  @override
  String get soundDefault => 'Default';

  @override
  String get soundGentle => 'Gentle';

  @override
  String get soundDigital => 'Digital';

  @override
  String get soundClassic => 'Classic';

  @override
  String get soundNature => 'Nature';

  @override
  String get soundSilent => 'Silent';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationOn => 'On';

  @override
  String get vibrationOff => 'Off';

  @override
  String get gradualVolume => 'Gradual Volume';

  @override
  String get gradualVolumeDescription => 'Slowly increase volume';

  @override
  String get deleteAlarm => 'Delete Alarm';

  @override
  String get deleteAlarmConfirmation =>
      'Are you sure you want to delete this alarm?';

  @override
  String get delete => 'Delete';

  @override
  String get reviewPromptTitle => 'Enjoying NextAlarm?';

  @override
  String get reviewPromptMessage =>
      'If you like this app, please take a moment to rate it. Your feedback helps us improve!';

  @override
  String get reviewPromptRate => 'Rate Now';

  @override
  String get reviewPromptLater => 'Later';

  @override
  String get reviewPromptDismiss => "Don't show again";
}
