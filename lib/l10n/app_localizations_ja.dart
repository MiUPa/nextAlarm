// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'NextAlarm';

  @override
  String get alarms => 'アラーム';

  @override
  String get noAlarmsYet => 'アラームがありません';

  @override
  String get tapToCreateAlarm => '+をタップして最初のアラームを作成';

  @override
  String get addAlarm => 'アラームを追加';

  @override
  String get editAlarm => 'アラームを編集';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get label => 'ラベル';

  @override
  String get labelHint => 'アラーム名';

  @override
  String get repeat => '繰り返し';

  @override
  String get wakeUpChallenge => '起床チャレンジ';

  @override
  String get difficulty => '難易度';

  @override
  String get challengeNone => 'なし';

  @override
  String get challengeMath => '計算';

  @override
  String get challengeVoice => '音声';

  @override
  String get challengeShake => 'シェイク';

  @override
  String get challengeSteps => '歩く';

  @override
  String get difficultyEasy => '簡単';

  @override
  String get difficultyNormal => '普通';

  @override
  String get difficultyHard => '難しい';

  @override
  String get dayMonday => '月';

  @override
  String get dayTuesday => '火';

  @override
  String get dayWednesday => '水';

  @override
  String get dayThursday => '木';

  @override
  String get dayFriday => '金';

  @override
  String get daySaturday => '土';

  @override
  String get daySunday => '日';

  @override
  String get repeatOnce => '1回のみ';

  @override
  String get repeatEveryDay => '毎日';

  @override
  String get repeatWeekdays => '平日';

  @override
  String get repeatWeekends => '週末';

  @override
  String inDays(int count) {
    return '$count日後';
  }

  @override
  String inHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分後';
  }

  @override
  String inHours(int count) {
    return '$count時間後';
  }

  @override
  String inMinutes(int count) {
    return '$count分後';
  }

  @override
  String get stopAlarm => 'アラームを停止';

  @override
  String get solveMathToStop => '数学問題を解いてアラームを停止';

  @override
  String get enterAnswer => '答えを入力';

  @override
  String get confirm => '確認';

  @override
  String get wrongAnswer => '不正解！もう一度試してください。';

  @override
  String get shakeToStop => 'スマホを振ってアラームを停止';

  @override
  String shakesCount(int current, int required) {
    return '$current / $required';
  }

  @override
  String get speakToStop => '早口言葉を言ってアラームを停止';

  @override
  String get tapMicrophone => 'マイクをタップ';

  @override
  String get listening => '聞き取り中...';

  @override
  String recognized(String text) {
    return '認識: $text';
  }

  @override
  String get speechNotAvailable => '音声認識が利用できません';

  @override
  String get walkToStop => '歩いてアラームを停止';

  @override
  String stepsCount(int current, int required) {
    return '$current / $required 歩';
  }

  @override
  String get challengeNotImplemented => 'このチャレンジはまだ実装されていません';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システム設定';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get tongueTwister1 => '生麦生米生卵';

  @override
  String get tongueTwister2 => 'バスガス爆発';

  @override
  String get tongueTwister3 => '東京特許許可局';

  @override
  String get tongueTwister4 => '隣の客はよく柿食う客だ';

  @override
  String get tongueTwister5 => '赤巻紙青巻紙黄巻紙';

  @override
  String get alarmSound => 'アラーム音';

  @override
  String get soundDefault => 'デフォルト';

  @override
  String get soundGentle => 'やさしい';

  @override
  String get soundDigital => 'デジタル';

  @override
  String get soundClassic => 'クラシック';

  @override
  String get soundNature => '自然';

  @override
  String get vibration => 'バイブレーション';

  @override
  String get vibrationOn => 'オン';

  @override
  String get vibrationOff => 'オフ';

  @override
  String get gradualVolume => 'だんだん大きく';

  @override
  String get gradualVolumeDescription => '音量を徐々に上げる';

  @override
  String get deleteAlarm => 'アラームを削除';

  @override
  String get deleteAlarmConfirmation => 'このアラームを削除してもよろしいですか？';

  @override
  String get delete => '削除';
}
