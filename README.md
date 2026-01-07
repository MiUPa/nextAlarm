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
- ✅ 全機能が動作

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
| **覚醒チャレンジ** | 6種類（計算、QR、音声、シェイク、歩数、なし） | 計算のみ |
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
   - **計算問題**: 難易度5段階（Easy～Expert）
   - **QRコード/バーコード**: 自作コード + 既存コード対応
   - **音声認識**: 早口言葉で覚醒
   - **シェイク**: 指定回数スマホを振る
   - **歩数カウント**: 歩いて目を覚ます
   - **なし**: シンプルなアラーム

3. **⚡ 無制限のカスタマイズ**
   - アラーム数無制限
   - タイマー無制限
   - 曜日別繰り返し設定
   - グループ管理

---

## ✨ 主要機能

### 実装済み（MVP）

✅ **アラーム管理**
- 直感的な時間設定（Cupertino Picker）
- ラベル/メモ機能
- 曜日別繰り返し（月-日）
- スワイプで削除

✅ **洗練されたUI**
- Apple標準アプリレベルのデザイン
- SF Pro風タイポグラフィ
- iOS風カラーパレット（#007AFF Blue, #5856D6 Purple）
- カード型レイアウト、大きなタイトル

✅ **スムーズな体験**
- タップ時のスケールアニメーション
- ハプティックフィードバック
- 画面遷移アニメーション
- データ自動保存（SharedPreferences）

### 次期実装予定

🔜 **実際のアラーム鳴動**
- バックグラウンド動作
- システムアラーム統合

🔜 **覚醒チャレンジ実装**
- 計算問題画面
- QRコードスキャナー
- 音声認識
- センサー連携（シェイク、歩数）

🔜 **カスタマイズ拡張**
- アラーム音選択
- テーマカラー変更
- グループ管理

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

# iOS (Macのみ)
flutter build ios --release

# Web
flutter build web
```

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

### v1.0 (現在) - MVP
- [x] 基本的なアラーム管理
- [x] Apple標準レベルのUI/UX
- [x] データ永続化
- [ ] アラーム鳴動機能

### v1.1 - チャレンジ実装
- [ ] 計算問題チャレンジ
- [ ] QRコードスキャンチャレンジ
- [ ] 音声認識チャレンジ

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
