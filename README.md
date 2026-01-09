# Whispin

匿名チャットアプリケーション - Flutter製のクロスプラットフォームアプリ

## 📱 概要

Whispinは、ユーザーが匿名でリアルタイムチャットを楽しめるFlutterアプリケーションです。ルームを作成し、他のユーザーと時間制限付きのチャットセッションを行うことができます。

### 主な機能

- **匿名チャット**: ニックネームを使用した匿名チャット
- **ルームベース**: チャットルームの作成・参加
- **時間制限**: 10分間の制限時間付きチャット（延長可能）
- **評価システム**: チャット後の相手評価
- **フレンド機能**: ユーザー間のフレンド申請・管理
- **ブロック機能**: 特定ユーザーのブロック
- **プレミアムプラン**: 延長回数無制限などの特典
- **管理者機能**: ユーザー管理、ログ閲覧、お問い合わせ対応

---

## 🏗️ アーキテクチャ

### プロジェクト構造
```
lib/
├── config/                 # アプリケーション設定
│   ├── app_config.dart
│   ├── environment.dart
│   └── firebase_config.dart
├── constants/             # 定数定義
│   ├── app_constants.dart
│   ├── colors.dart
│   ├── routes.dart
│   └── text_styles.dart
├── extensions/            # 拡張メソッド
│   ├── context_extensions.dart
│   ├── datetime_extensions.dart
│   ├── list_extensions.dart
│   ├── num_extensions.dart
│   └── string_extensions.dart
├── models/               # データモデル
│   ├── user.dart
│   ├── chat_room.dart
│   ├── friendship.dart
│   ├── friend_request.dart
│   ├── invitation.dart
│   ├── block.dart
│   └── ...
├── repositories/         # データアクセス層
│   ├── base_repository.dart
│   ├── user_repository.dart
│   ├── chat_room_repository.dart
│   ├── friendship_repository.dart
│   └── ...
├── services/            # ビジネスロジック層
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── storage_service.dart
│   ├── invitation_service.dart
│   └── ...
├── providers/           # 状態管理
│   ├── user_provider.dart
│   ├── admin_provider.dart
│   └── chat_provider.dart
├── screens/             # UI画面
│   ├── user/
│   │   ├── home_screen.dart
│   │   ├── profile.dart
│   │   ├── chat_screen.dart
│   │   └── ...
│   └── admin/
│       ├── admin_home_screen.dart
│       └── ...
├── widgets/             # 再利用可能ウィジェット
│   ├── common/
│   │   └── header.dart
│   └── ...
├── routes/              # ルーティング
│   ├── app_router.dart
│   ├── navigation_helper.dart
│   └── routes_guard.dart
├── utils/               # ユーティリティ
│   ├── app_logger.dart
│   └── navigation_logger.dart
└── main.dart           # エントリーポイント
```

### アーキテクチャパターン

**Repository Pattern + Provider**

- **Repository層**: Firestoreとの通信を抽象化
- **Service層**: ビジネスロジックを集約
- **Provider**: 状態管理とUIへの通知
- **Extensions**: Dart標準型の機能拡張

---

## 🚀 セットアップ

### 必要要件

- Flutter SDK 3.0以上
- Dart 3.0以上
- Firebase CLI
- Node.js（Firebaseエミュレータ用）

### インストール手順

1. **リポジトリのクローン**
```bash
git clone https://github.com/your-repo/whispin.git
cd whispin
```

2. **依存関係のインストール**
```bash
flutter pub get
```

3. **Firebase設定**
```bash
# Firebase CLIのインストール
npm install -g firebase-tools

# Firebaseプロジェクトの初期化
firebase init
```

4. **環境変数の設定**

`lib/config/environment.dart`を編集し、Firebase設定を記入してください。
```dart
static const String firebaseApiKey = 'YOUR_API_KEY';
static const String firebaseProjectId = 'YOUR_PROJECT_ID';
// ...
```

5. **Firebaseエミュレータの起動**（開発環境）
```bash
firebase emulators:start
```

6. **アプリの起動**
```bash
flutter run
```

---

## 🔥 Firebase構成

### 使用サービス

- **Firebase Authentication**: ユーザー認証
- **Cloud Firestore**: データベース
- **Firebase Emulator**: ローカル開発環境

### Firestoreコレクション構造
```
User/
  - id (Email)
  - firstName, lastName, nickname
  - premium (boolean)
  - rate (double)
  - roomCount (int)
  - createdAt, deletedAt

rooms/
  - id (roomId)
  - topic (string)
  - status (0: 待機, 1: 会話中, 2: 終了)
  - id1, id2 (参加者)
  - startedAt, expiresAt
  - extensionCount

friendships/
  - id
  - userId, friendId
  - active (boolean)

friendRequests/
  - id
  - senderId, receiverId
  - status (pending/accepted/rejected)

blocks/
  - id
  - blockerId, blockedId
  - active (boolean)

invitations/
  - id
  - roomId
  - inviterId, inviteeId
  - status
  - expiresAt

administrator/
  - email
  - password
  - lastLogin

Log_Premium/
  - ID (電話番号 or Email)
  - Timestamp
  - Detail (契約/解約)
```

---

## 📦 依存パッケージ
```yaml
dependencies:
  flutter:
    sdk: flutter
  #UI/UX
  google_fonts: 6.3.2

  # Firebase 系パッケージ（互換性を考慮）
  firebase_core: 4.2.1
  firebase_auth: 6.1.2
  cloud_firestore: 6.1.0

  #Utilities
  http: 1.6.0
  crypto: 3.0.3
  shared_preferences: 2.2.2
  intl: 0.19.0
  path_provider: 2.1.5

  # Other
  image_picker: 1.2.1
  provider: 6.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: 6.0.0
```

---

## 🎯 主要機能の実装詳細

### 1. 認証システム

**Firebase Authentication + Firestore連携**
```dart
// services/user_auth_service.dart
Future<User?> loginUser({
  required String email,
  required String password,
}) async {
  final credential = await _auth.signInWithEmailAndPassword(
    email: email.trim(),
    password: password.trim(),
  );
  
  // Firestoreからユーザー情報取得
  final query = await _firestore
      .collection("User")
      .where("email", isEqualTo: email)
      .limit(1)
      .get();
  
  return credential.user;
}
```

### 2. チャットルーム管理

**Repository Pattern採用**
```dart
// repositories/chat_room_repository.dart
Future<List<ChatRoom>> findWaitingRooms() async {
  return findByStatus(AppConstants.roomStatusWaiting);
}

Future<void> joinRoom(String roomId, String userId) async {
  final room = await findById(roomId);
  // ルーム参加ロジック
  await updateFields(roomId, {
    'id2': userId,
    'status': AppConstants.roomStatusActive,
    'startedAt': now.toIso8601String(),
  });
}
```

### 3. リアルタイム更新

**StreamとTimerの併用**
```dart
// services/chat_service.dart
void startRoomTimer(String roomId, DateTime expiresAt) {
  final duration = expiresAt.difference(DateTime.now());
  
  _roomTimers[roomId] = Timer(duration, () async {
    await deleteRoom(roomId);
  });
}
```

### 4. ロギングシステム

**統一ロガー実装**
```dart
// utils/app_logger.dart
logger.section('処理開始', name: 'ServiceName');
logger.info('情報メッセージ', name: 'ServiceName');
logger.success('成功メッセージ', name: 'ServiceName');
logger.error('エラー発生: $e', name: 'ServiceName', error: e);
```

---

## 🛡️ セキュリティ

### 実装済みセキュリティ機能

1. **パスワードハッシュ化**: PBKDF2ベースのハッシュ化
2. **論理削除**: 物理削除ではなく論理削除を採用
3. **ブロック機能**: 不適切ユーザーのブロック
4. **管理者認証**: Firestore管理者コレクションでの権限確認

### Firebase Securityルール例
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /User/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /rooms/{roomId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (resource.data.id1 == request.auth.uid || 
         resource.data.id2 == request.auth.uid);
    }
  }
}
```

---

## 🧪 テスト

### テスト実行
```bash
# 単体テスト
flutter test

# 統合テスト
flutter test integration_test/
```

---

## 📱 ビルド

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

---

## 🐛 トラブルシューティング

### よくある問題

**Q: Firebaseエミュレータに接続できない**
```bash
# エミュレータが起動しているか確認
firebase emulators:start

# ポートが使用されているか確認
lsof -i :8080
lsof -i :9099
```

**Q: ログイン後にユーザー情報が表示されない**
```dart
// UserProvider.loadUserData()が呼ばれているか確認
final userProvider = context.read<UserProvider>();
await userProvider.loadUserData(email);
```

**Q: ルームタイマーが動作しない**
```dart
// ChatService.startRoomTimer()が正しく呼ばれているか確認
chatService.startRoomTimer(roomId, expiresAt);
```

---

## 🤝 コントリビューション

プルリクエストを歓迎します！

1. フォーク
2. 機能ブランチ作成 (`git checkout -b feature/amazing-feature`)
3. コミット (`git commit -m 'Add amazing feature'`)
4. プッシュ (`git push origin feature/amazing-feature`)
5. プルリクエスト作成

---

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

---

## 👥 作成者

- **開発チーム**: Whispin Development Team
- **お問い合わせ**: support@whispin.app

---

## 📚 参考資料

- [Flutter公式ドキュメント](https://flutter.dev/docs)
- [Firebase公式ドキュメント](https://firebase.google.com/docs)
- [Provider パッケージ](https://pub.dev/packages/provider)

---

## 🗺️ ロードマップ

- [ ] プッシュ通知機能
- [ ] 画像・ファイル共有
- [ ] グループチャット機能
- [ ] AI自動翻訳
- [ ] ダークモード対応
- [ ] Web版の最適化

---

## 📊 統計情報

- **総コード行数**: ~20,000行
- **モデル数**: 15個
- **Repository数**: 6個
- **サービス数**: 10個
- **画面数**: 20画面以上

---

**最終更新**: 2026年1月9日