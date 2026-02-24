# NextAlarm ⏰

> **Smart alarm clock that beats SmartAlarm**
> Apple標準アプリレベルの洗練されたUI × 多様な覚醒チャレンジ

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

## 📱 今すぐ試す

### Web版（スマホのブラウザで即アクセス）

**https://miupa.github.io/Linux-Playground/**

- ✅ インストール不要
- ✅ iOS/Android対応
- ✅ **アラーム鳴動機能が動作中**（数学チャレンジ含む）
- ⚠️ **制限事項**: ブラウザタブを開いたまま、スリープせずに待機する必要あり

### Android APK（ネイティブアプリ）

1. [GitHub Actions](https://github.com/MiUPa/Linux-Playground/actions) にアクセス
2. 最新の「Build Android APK」をクリック
3. 「Artifacts」から `nextalarm-apk` をダウンロード
4. APKをインストール

---

## 🎯 なぜNextAlarmなのか？

### SmartAlarmとの比較

| 機能 | NextAlarm | SmartAlarm |
|------|-----------|------------|
| **覚醒チャレンジ** | 6種類（計算✅、QR、音声、シェイク、歩数、なし） | 計算のみ |
| **タイマー数** | 無制限 | 2個まで |
| **UI/UX** | Apple標準レベル | 標準的 |
| **カスタマイズ** | 高度 | 中程度 |
| **価格** | 無料 | 無料 + $2.99 |
| **最終更新** | 2026年1月 | 2025年4月 |

### NextAlarmの強み

1. **🎨 世界レベルのUI/UX**
   - iOS標準アプリに匹敵する洗練されたデザイン
   - ダークモード完全対応
   - スムーズなアニメーションとハプティックフィードバック

2. **🧠 多様な覚醒チャレンジ**
   - **計算問題** ✅: 難易度3段階（Easy/Normal/Hard）- **実装済み**
   - **QRコード/バーコード** 🔜: 自作コード + 既存コード対応
   - **音声認識** 🔜: 早口言葉で覚醒
   - **シェイク** 🔜: 指定回数スマホを振る
   - **歩数カウント** 🔜: 歩いて目を覚ます
   - **なし** ✅: シンプルなアラーム

3. **⚡ 無制限のカスタマイズ**
   - アラーム数無制限
   - タイマー無制限
   - 曜日別繰り返し設定
   - グループ管理

---

## ✨ 主要機能

### 実装済み（MVP完了✨）

✅ **アラーム管理**
- 直感的な時間設定（Cupertino Picker）
- ラベル/メモ機能
- 曜日別繰り返し（月-日）
- スワイプで削除
- **無制限のアラーム作成**

✅ **洗練されたUI**
- Apple標準アプリレベルのデザイン
- SF Pro風タイポグラフィ
- iOS風カラーパレット（#007AFF Blue, #5856D6 Purple）
- カード型レイアウト、大きなタイトル
- **完全なダークモード対応**

✅ **スムーズな体験**
- タップ時のスケールアニメーション
- ハプティックフィードバック
- 画面遷移アニメーション
- データ自動保存（SharedPreferences）

✅ **アラーム鳴動（Web版で動作中）**
- 毎秒の時刻チェックで自動トリガー
- フルスクリーン鳴動画面（パルスアニメーション付き）
- 重複防止メカニズム
- **Web通知統合**（ブラウザ通知）

✅ **覚醒チャレンジ（数学問題）**
- **難易度3段階**：Easy / Normal / Hard
  - Easy: 簡単な足し算（1-20）
  - Normal: 掛け算（1-12）
  - Hard: 複合演算
- **正解するまで停止不可**
- リアルタイム答え合わせ

✅ **多言語対応**
- 🇯🇵 日本語 / 🇬🇧 English
- 設定画面から言語切り替え可能
- デフォルトはスマホ本体設定に準拠
- 音声認識チャレンジの早口言葉も言語別対応

✅ **バックグラウンドアラーム（Android）**
- 画面オフ時でもアラームが発火
- ロック画面上にアラーム表示
- AndroidAlarmManager + フルスクリーンインテント
- アラーム音量（STREAM_ALARM）で再生

### 次期実装予定

🔜 **ネイティブアプリ機能（Android/iOS）**
- バックグラウンド動作（Service Worker for Web, android_alarm_manager_plus for Android）
- システムアラーム音統合
- ネイティブ通知（flutter_local_notifications）

🔜 **追加覚醒チャレンジ**
- QRコード/バーコードスキャナー
- 音声認識（早口言葉）
- シェイク（加速度センサー）
- 歩数カウント

🔜 **カスタマイズ拡張**
- アラーム音選択
- スヌーズ機能
- データバックアップ/復元
- 統計・使用履歴

---

## 🛠️ 技術スタック

### フレームワーク
- **Flutter 3.10+**
- **Dart 3.10+**

### 主要パッケージ
- `flutter_local_notifications` - 通知
- `android_alarm_manager_plus` - バックグラウンドアラーム
- `provider` - 状態管理
- `shared_preferences` - データ永続化
- `mobile_scanner` - QR/バーコードスキャン
- `speech_to_text` - 音声認識
- `sensors_plus` - シェイク検出
- `pedometer` - 歩数カウント
- `vibration` - ハプティック

### アーキテクチャ
```
lib/
├── models/          # データモデル
├── services/        # ビジネスロジック
├── screens/         # UI画面
├── widgets/         # 再利用コンポーネント
└── theme/           # テーマ定義
```

---

## 🚀 開発

### 前提条件
- Flutter SDK 3.10以上
- Android Studio / Xcode
- Android SDK / iOS SDK

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/MiUPa/Linux-Playground.git
cd Linux-Playground

# 依存関係をインストール
flutter pub get

# 実行
flutter run
```

### ビルド

```bash
# Android APK
flutter build apk --release

# Android AAB (Play Store)
flutter build appbundle --release

# Signed AAB helper (checks key.properties then builds)
./scripts/release_android_playstore.sh

# iOS (Macのみ)
flutter build ios --release

# Web
flutter build web
```

### Internal Test 自動配信（GitHub Actions）

`release-internal` または `release/internal-*` ブランチへ push すると、GitHub Actions が自動で Play Console の `internal` トラックへ AAB をアップロードします。

- Workflow: `.github/workflows/release-internal-play.yml`
- 実行コマンド: `./scripts/release_android_playstore.sh build-upload --track internal`

#### 必須 Secrets（Repository Secrets）

- `ANDROID_UPLOAD_KEYSTORE_BASE64`（upload keystore を base64 化した文字列）
- `ANDROID_UPLOAD_STORE_PASSWORD`
- `ANDROID_UPLOAD_KEY_ALIAS`
- `ANDROID_UPLOAD_KEY_PASSWORD`
- `PLAY_SERVICE_ACCOUNT_JSON_BASE64`（Play service account JSON を base64 化した文字列）

#### 公開リポジトリでのセキュリティ注意点

この構成は公開リポジトリでも運用可能ですが、次の前提が必須です。

1. 秘密情報（keystore / `key.properties` / service account JSON）をリポジトリにコミットしない  
2. `release-internal` / `release/internal-*` へ push できる人を最小化する（Branch protection 推奨）  
3. Play service account は最小権限にし、定期的に鍵ローテーションする  
4. Secrets は GitHub Actions の Secrets だけで管理し、ログ出力させない

補足: Fork からの Pull Request では通常 Secrets は渡されませんが、**リポジトリに push 権限があるユーザー**は workflow を変更して Secrets にアクセスできるため、push 権限管理が最重要です。

---

## 📸 スクリーンショット

### ホーム画面
- 大きなタイトル（34pt, Bold）
- カード型アラーム一覧
- スムーズなアニメーション

### 編集画面
- Cupertinoタイムピッカー
- 曜日選択（円形ボタン）
- チャレンジ選択（横スクロール）
- 難易度スライダー

---

## 🎯 ロードマップ

### v1.0 (✅ 完了) - MVP
- [x] 基本的なアラーム管理
- [x] Apple標準レベルのUI/UX
- [x] データ永続化
- [x] **アラーム鳴動機能（Web版）**
- [x] **計算問題チャレンジ（3段階難易度）**

### v1.1 (✅ 完了) - Androidネイティブ対応
- [x] Androidバックグラウンドアラーム
- [x] ロック画面でのアラーム表示
- [x] アラーム音量で再生
- [x] **多言語対応（日本語/英語）**
- [x] 起動時のマイク権限リクエスト

### v1.2 (進行中) - ネイティブアプリ拡張
- [ ] iOSバックグラウンド動作
- [ ] スヌーズ機能

### v1.2 - 追加チャレンジ実装
- [ ] QRコードスキャンチャレンジ
- [ ] 音声認識チャレンジ
- [ ] シェイクチャレンジ
- [ ] 歩数カウントチャレンジ

### v1.2 - カスタマイズ
- [ ] アラーム音選択
- [ ] テーマカラー変更
- [ ] グループ管理

### v2.0 - プレミアム機能
- [ ] 睡眠サイクル分析
- [ ] 統計とインサイト
- [ ] スマートホーム連携

---

## 🤝 貢献

プルリクエストを歓迎します！

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照

---

## 🙏 クレジット

**競合分析対象**: [SmartAlarm](https://play.google.com/store/apps/details?id=jp.tanyu.SmartAlarm)
- 評価: 4.25/5 (4,000レビュー)
- 長所: 計算問題による強制覚醒、10年の実績
- 改善点: タイマー制限、覚醒方法の限定性

**デザイン参考**: Apple iOS 標準アプリ
- クロックアプリのUI/UX
- SF Pro Typography
- iOS Human Interface Guidelines

---

## 📮 お問い合わせ

Issue: https://github.com/MiUPa/Linux-Playground/issues

---

**Made with ❤️ using Flutter**
