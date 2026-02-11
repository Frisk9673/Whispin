# 🚀 03 — セットアップ

## 必要要件

`pubspec.yaml` の `environment.sdk: '>=3.0.0 <4.0.0'` を基準に、Dart/Flutter要件を以下に定義します。

| ツール | 最小要件 | 推奨/検証メモ |
|---|---|---|
| Dart SDK | 3.0.0以上（4.0未満） | 3.x系の最新安定版を推奨 |
| Flutter SDK | 3.10.0以上 | Stable チャンネルの最新安定版を推奨（Dart 3.x 同梱） |
| Firebase CLI | 最新版 | `firebase emulators:start` が実行できること |
| FlutterFire CLI | 最新版 | `flutterfire configure` が実行できること |
| Node.js | 18以上 | Firebase Emulator Suite 利用時に必要 |

---

## インストール手順

### 1. リポジトリのクローン
```bash
git clone https://github.com/Whispin/whispin.git
cd whispin
```

### 2. 依存パッケージを取得
```bash
flutter pub get
```

### 3. Firebase / FlutterFire CLI を準備
```bash
npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli
```

### 4. FlutterFire 設定を反映
```bash
flutterfire configure
```

> 既存の `lib/firebase_options.dart` を使う場合でも、
> プロジェクトやプラットフォーム設定を変更した際は `flutterfire configure` を再実行してください。

### 5. `.env` ファイルを作成

`lib/config/environment.dart` で参照しているキーに合わせて、プロジェクト直下に `.env` を作成します。

```env
# 環境種別
ENVIRONMENT=development

# Firebase接続先
FIREBASE_MODE=emulator   # emulator | production

# バックエンド
BACKEND=firebase         # firebase | aws

# デバッグ
DEBUG_MODE=true

# エミュレーター設定
EMULATOR_HOST=localhost
AUTH_EMULATOR_PORT=9099
FIRESTORE_EMULATOR_PORT=8080
STORAGE_EMULATOR_PORT=9199
DATABASE_EMULATOR_PORT=9000
```

> ⚠️ `FIREBASE_MODE=emulator` はデバッグ/プロファイルビルド時のみ有効。  
> リリースビルドでは自動的に本番環境へ接続します。

### 6. Firebase Emulator を起動
```bash
firebase emulators:start
```

### 7. アプリ起動
```bash
flutter run
```

---

## 環境設定まとめ

| 環境 | ENVIRONMENT | FIREBASE_MODE | DEBUG_MODE |
|---|---|---|---|
| 開発 | development | emulator | true |
| ステージング | staging | production | true |
| 本番 | production | production | false |

> 本番ビルド（`kReleaseMode=true`）では `.env` の設定に関わらず常に本番環境へ接続します。
