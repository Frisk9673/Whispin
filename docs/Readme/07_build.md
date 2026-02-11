# 📦 07 — ビルド・デプロイ

## サポート方針（01_overview.md と統一）

| 区分 | 定義 |
|---|---|
| 対応済み | `flutter run` / `flutter build` と Firebase 初期化が現行設定で成立し、運用手順を本書で提供する |
| 実験的 | 雛形はあるが設定・検証不足のため継続運用を保証しない |
| 未サポート | 現行設定では起動要件を満たさず、標準手順として提供しない |

現行リポジトリの分類:

- **対応済み**: Android / Web
- **未サポート**: iOS / macOS / Windows / Linux
- **実験的**: 該当なし

## テスト

```bash
# 単体テスト
flutter test

# 統合テスト
flutter test integration_test/

# カバレッジレポート生成
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Android

```bash
# デバッグAPK
flutter build apk --debug

# リリースAPK
flutter build apk --release

# Google Play推奨 (App Bundle)
flutter build appbundle --release
```

---

## iOS

現状は**未サポート**です。

- `lib/firebase_options.dart` の `DefaultFirebaseOptions.currentPlatform` で iOS が `UnsupportedError` になるため、現行設定では起動できません。
- iOS 向け手順は、FlutterFire CLI で iOS 設定を追加後に提供してください。

---

## Web（Firebase Hosting）

```bash
# リリースビルド
flutter build web --release

# Firebase Hostingへデプロイ
firebase deploy --only hosting
```

---

## macOS / Windows / Linux

現状は**未サポート**です。

- 各プラットフォームのプロジェクト雛形は存在しますが、Firebase 初期化に必要な設定が未投入です。
- `DefaultFirebaseOptions.currentPlatform` が各OSで `UnsupportedError` を返すため、現行コードのままでは起動できません。
- サポート化する場合は、FlutterFire CLI で対象OSを追加して設定を再生成してから手順化してください。
