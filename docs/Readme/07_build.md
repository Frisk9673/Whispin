# 📦 07 — ビルド・デプロイ

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

```bash
# デバッグビルド
flutter build ios --debug

# リリースビルド
flutter build ios --release
```

> リリース後はXcodeで署名・App Storeへアップロードしてください。

---

## Web（Firebase Hosting）

```bash
# リリースビルド
flutter build web --release

# Firebase Hostingへデプロイ
firebase deploy --only hosting
```