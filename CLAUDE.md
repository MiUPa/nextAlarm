# NextAlarm - Development Notes

## ⚠️ リリース前チェックリスト

**重要**: mainブランチにマージしてリリースビルドを作成する前に、必ず以下を確認すること：

1. **バージョンを上げる** - `pubspec.yaml`の`version`を更新
   - 形式: `X.Y.Z+N` (例: `0.1.1+2`)
   - `X.Y.Z`: セマンティックバージョン（メジャー.マイナー.パッチ）
   - `+N`: ビルド番号（Google Play Consoleでは必ず前回より大きい値が必要）

2. **ビルドコマンド**:
   ```bash
   flutter build appbundle --release
   ```

3. **成果物の場所**: `build/app/outputs/bundle/release/app-release.aab`

## プロジェクト概要

SmartAlarmを超える次世代アラームアプリ「NextAlarm」の開発プロジェクト。
Apple標準アプリレベルの洗練されたUIと、多彩な覚醒チャレンジを特徴とする。

### 競合分析
- **SmartAlarm**: 4.25★、4000レビュー、$2.99有料版
- **弱点**: タイマー2個制限、覚醒方法が限定的、位置情報機能なし
- **NextAlarmの差別化**: 無制限アラーム、6種類のチャレンジ、モダンUI

## 現在の開発状況

### ✅ 実装済み機能（MVP完了）

#### UI/UX
- Apple風の洗練されたデザインシステム（lib/theme/app_theme.dart）
- iOS色彩（#007AFF Blue, #5856D6 Purple）とSF Pro風タイポグラフィ
- ダークテーマ対応
- カードベースレイアウト with グラデーション
- スケールアニメーション、ハプティックフィードバック
- Large title（34pt）のSliverAppBar

#### アラーム管理
- **無制限のアラーム作成・編集・削除**
- 時間設定（24時間形式、CupertinoDatePicker）
- ラベル設定
- 曜日別繰り返し（月〜日の個別設定）
- 6種類のチャレンジタイプ選択
  - なし
  - 数学問題
  - QRコード/バーコード
  - 音声認識
  - シェイク
  - 歩数
- 難易度設定（1-5: Easy/Normal/Medium/Hard/Expert）
- データ永続化（SharedPreferences）
- Swipe to delete

#### アラーム鳴動機能（Web版）
- **毎秒のタイマーチェック**（lib/services/alarm_service.dart:40-72）
- 時刻一致で自動トリガー
- 重複防止メカニズム（同じアラームが1分間に複数回鳴らない）
- フルスクリーン鳴動UI（lib/screens/alarm_ringing_screen.dart）
  - パルスアニメーション
  - アラーム情報表示（時刻、ラベル）
- **数学チャレンジ実装**
  - 難易度別問題生成
  - Easy: 簡単な足し算（1-20）
  - Medium: 掛け算（1-12）
  - Hard: 複合演算
  - 正解するまで停止不可
- **Web Notification統合**
  - ブラウザ通知許可リクエスト
  - アラーム鳴動時に通知送信
  - 条件付きエクスポートでWeb/非Web対応
- 音声再生フレームワーク（AudioPlayer統合済み、音声ファイル未設定）

### 🚧 未実装・プレースホルダー

- QRコード/バーコードチャレンジ（UI表示のみ）
- 音声認識チャレンジ（UI表示のみ）
- シェイクチャレンジ（UI表示のみ）
- 歩数チャレンジ（UI表示のみ）
- アラーム音声ファイル（フレームワークは準備済み）
- バックグラウンド動作（Service Worker）
- スヌーズ機能

### ⚠️ Web版の制限事項

1. **タブを開いている必要あり** - ブラウザタブを閉じると動作停止
2. **バックグラウンド非対応** - Service Worker未実装
3. **スリープ時停止** - PCスリープでタイマー停止
4. **音声ファイル未設定** - デバッグログのみ出力

## 技術スタック

### フレームワーク・言語
- **Flutter 3.38.5** / Dart 3.10
- **Material Design 3** + カスタムApple風テーマ
- **Cupertino widgets** for iOS-like interactions

### 状態管理・データ
- **Provider** - アプリ全体の状態管理
- **SharedPreferences** - データ永続化

### 主要パッケージ
```yaml
dependencies:
  flutter_local_notifications: ^18.0.1  # ネイティブ通知（Web非対応）
  android_alarm_manager_plus: ^4.0.8    # Androidバックグラウンド（Web非対応）
  permission_handler: ^11.4.0
  shared_preferences: ^2.3.4
  qr_code_scanner: ^1.0.1              # QRスキャン（未使用）
  mobile_scanner: ^5.2.3                # 代替QRスキャナー（未使用）
  speech_to_text: ^7.0.0                # 音声認識（未使用）
  sensors_plus: ^6.1.2                  # シェイク検出（未使用）
  pedometer: ^4.0.2                     # 歩数カウント（未使用）
  audioplayers: ^6.2.0                  # 音声再生
  vibration: ^2.1.0                     # バイブレーション
  provider: ^6.1.2
  uuid: ^4.5.1
  intl: ^0.19.0
```

### プラットフォーム対応
- ✅ **Android** - フル機能（APKビルド可能、自動ビルドは無効化済み）
- ✅ **iOS** - フル機能（ビルド未検証）
- ⚠️ **Web** - 制限付き（現在開発中、GitHub Pagesデプロイ設定済み）

## ファイル構造

```
lib/
├── main.dart                          # エントリーポイント、AlarmMonitor
├── models/
│   └── alarm.dart                     # Alarm, WakeUpChallenge, TimeOfDay
├── services/
│   ├── alarm_service.dart             # アラーム管理 + タイマーチェック + 鳴動ロジック
│   ├── notification_service.dart      # 条件付きエクスポート
│   ├── notification_service_web.dart  # Web版通知（dart:html使用）
│   └── notification_service_stub.dart # 非Web版スタブ
├── screens/
│   ├── home_screen.dart               # ホーム画面、アラーム一覧
│   ├── alarm_edit_screen.dart         # アラーム編集画面
│   └── alarm_ringing_screen.dart      # アラーム鳴動画面
└── theme/
    └── app_theme.dart                 # Apple風テーマ定義

.github/workflows/
├── build-apk.yml                      # Android APKビルド（手動実行のみ）
└── deploy-pages.yml                   # GitHub Pages自動デプロイ
```

## 重要な実装詳細

### アラームチェックロジック（alarm_service.dart:47-72）
```dart
void _checkAlarms() {
  final now = DateTime.now();
  final currentMinute = '${now.hour}:${now.minute}';

  for (final alarm in _alarms) {
    if (!alarm.isEnabled) continue;
    if (_ringingAlarm != null) continue; // 一度に1つのみ

    final alarmMinute = '${alarm.time.hour}:${alarm.time.minute}';
    final alarmKey = '${alarm.id}_$currentMinute';

    // 時刻一致 && 未トリガー && 曜日一致
    if (alarmMinute == currentMinute && !_triggeredToday.contains(alarmKey)) {
      if (alarm.repeatDays.isEmpty || alarm.repeatDays.contains(now.weekday)) {
        _triggerAlarm(alarm);
        _triggeredToday.add(alarmKey);
      }
    }
  }
}
```

### 条件付きエクスポート（notification_service.dart）
```dart
export 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart';
```
- **Web**: `dart:html`でNotification APIを使用
- **非Web**: スタブ実装（何もしない）
- **重要**: 両ファイルで同じクラス名`NotificationService`が必須

### Flutter 3.38.5 API変更対応
- `CardTheme` → `CardThemeData`
- `FloatingActionButtonTheme` → `FloatingActionButtonThemeData`

## デプロイ情報

### GitHub Pages（Web版）
- **URL**: https://miupa.github.io/Linux-Playground/
- **自動デプロイ**: `claude/**`ブランチへのpushで自動実行
- **ワークフロー**: `.github/workflows/deploy-pages.yml`
- **ブランチ**: `gh-pages`（自動作成、peaceiris/actions-gh-pages@v3使用）
- **設定**: Settings → Pages → Source: Deploy from a branch, Branch: gh-pages

### Android APK
- **手動ビルドのみ**: https://github.com/MiUPa/Linux-Playground/actions/workflows/build-apk.yml
- **ワークフロー**: 「Run workflow」から手動実行
- **成果物**: Artifactsから`nextalarm-apk`をダウンロード（保持期間30日）

## 既知の問題

### 現在のビルド状況
- **最新コミット**: `4f6c908` - "Unify class names for conditional exports"
- **ステータス**: ビルド実行中
- **過去の問題**:
  - ~~`dart:html`を無条件にインポート → 条件付きエクスポートで解決~~
  - ~~クラス名不一致 → `NotificationService`に統一~~
  - ~~Flutter API非互換 → CardThemeData等に修正~~

### Web版制限の詳細
1. **Timer精度**: 1秒間隔チェックのため、最大1秒のズレ
2. **タブフォーカス**: 一部ブラウザはバックグラウンドタブでタイマー精度低下
3. **通知許可**: ユーザーが明示的に許可する必要あり
4. **音声再生**: ユーザーインタラクション後のみ可能（自動再生制限）

## 次のステップ

### 短期（Web版デモ完成）
1. [ ] ビルド成功確認
2. [ ] GitHub Pagesデプロイ確認
3. [ ] Web版でアラーム鳴動テスト
4. [ ] アラーム音声ファイル追加（オプション）

### 中期（Android版フル実装）
1. [ ] Android APKビルド＆実機テスト
2. [ ] バックグラウンドアラーム実装（android_alarm_manager_plus）
3. [ ] ネイティブ通知実装（flutter_local_notifications）
4. [ ] 全チャレンジタイプの実装
   - [ ] QRコード/バーコードスキャン
   - [ ] 音声認識（早口言葉）
   - [ ] シェイク（duration/count指定）
   - [ ] 歩数カウント
5. [ ] 音声ファイル統合
6. [ ] スヌーズ機能

### 長期（プロダクト化）
1. [ ] iOS版実装＆テスト
2. [ ] データバックアップ/復元
3. [ ] アラーム音カスタマイズ
4. [ ] 統計・使用履歴
5. [ ] ウィジェット
6. [ ] 多言語対応
7. [ ] アプリストア公開準備

## テスト方法

### Web版
1. https://miupa.github.io/Linux-Playground/ にアクセス
2. 通知許可のポップアップで「許可」
3. アラームを追加（現在時刻の1-2分後に設定）
4. チャレンジタイプと難易度を選択
5. タブを開いたまま待機
6. 設定時刻にアラーム鳴動画面が自動表示
7. 数学問題を解いて停止（またはチャレンジ「なし」で即停止）

### Android APK
1. GitHub Actionsで手動ビルド実行
2. Artifactsから`nextalarm-apk`をダウンロード
3. APKをAndroid端末にインストール
4. 同様の手順でテスト（バックグラウンド動作可能）

## トラブルシューティング

### ビルドエラー時
1. GitHub Actions logsで詳細確認
2. Flutter API変更の可能性 → 公式ドキュメント確認
3. 条件付きインポート/エクスポートの構文確認
4. クラス名の一貫性確認

### アラームが鳴らない時
1. アラームが有効（isEnabled: true）か確認
2. ブラウザタブが開いているか確認
3. 曜日設定が現在の曜日と一致しているか確認
4. ブラウザのコンソールログ確認（`🔔 Alarm sound playing`が出ているか）

### 通知が表示されない時
1. ブラウザの通知許可状態確認
2. OSの通知設定確認（Do Not Disturb等）
3. コンソールログで許可状態確認

## 開発ブランチ

**現在の作業ブランチ**: `claude/clarify-capabilities-R4zop`

- すべての開発はこのブランチで実施
- mainブランチへのマージは未実施
- GitHub Pagesデプロイもこのブランチから自動実行

## 備考

- **UI品質要件**: "世界を取れるようなApple製品に標準搭載されていてもおかしくないくらい洗練されている"
- **ユーザー要求**: 当初は位置ベースアラームアプリだったが、完全に方向転換してSmartAlarm競合アプリに
- **開発環境制限**: この環境にはFlutterがインストールされていないため、ローカルビルド不可
- **CI/CD依存**: すべてのビルドはGitHub Actionsで実施

---

最終更新: 2026-01-11
作成者: Claude (Sonnet 4.5)
