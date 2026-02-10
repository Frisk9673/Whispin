# 🚀 03 — セットアップ

## 必要要件

| ツール | バージョン |
|---|---|
| Flutter SDK | 3.5以上 |
| Dart | 3.2以上 |
| Firebase CLI | 最新版 |
| Node.js | 16以上（エミュレータ用） |

---

## インストール手順

### 1. リポジトリのクローン
```bash
git clone https://github.com/your-repo/whispin.git
cd whispin
flutter pub get
```

### 2. Firebase設定
```bash
npm install -g firebase-tools
firebase login
firebase init
```

### 3. .env ファイルを作成

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

> ⚠️ `FIREBASE_MODE=emulator` はデバッグビルド時のみ有効。  
> リリースビルドでは自動的に本番環境へ接続します。

### 4. FlutterFire設定
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 5. エミュレーター起動
```bash
firebase emulators:start
```

### 6. アプリ起動
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