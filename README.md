# Whispin

匿名チャットアプリケーション - Flutter製のクロスプラットフォームアプリ

## 📱 概要

Whispinは、ユーザーが匿名でリアルタイムチャットを楽しめるFlutterアプリケーションです。ルームを作成し、他のユーザーと時間制限付きのチャットセッションを行うことができます。

### 主な機能

- **匿名チャット**: ニックネームを使用した匿名チャット
- **ルームベース**: パブリック/プライベートルームの作成・参加
- **時間制限**: 10分間の制限時間付きチャット（延長可能）
- **評価システム**: チャット後の相手評価
- **フレンド機能**: ユーザー間のフレンド申請・管理
- **招待機能**: フレンドをプライベートルームに招待
- **ブロック機能**: 特定ユーザーのブロック
- **プレミアムプラン**: 延長回数無制限などの特典
- **管理者機能**: ユーザー管理、ログ閲覧、お問い合わせ対応
- **通知機能**: リアルタイム通知（フレンドリクエスト、招待）
- **レスポンシブデザイン**: モバイル・タブレット・デスクトップ対応

---

## 🏗️ アーキテクチャ

### プロジェクト構造
```
lib/
├── config/                      # アプリケーション設定
│   ├── app_config.dart         # Theme設定
│   ├── environment.dart        # 環境変数管理
│   └── firebase_config.dart    # Firebase初期化
│
├── constants/                   # 定数定義
│   ├── app_constants.dart      # アプリ全体の定数
│   ├── colors.dart             # カラーパレット
│   ├── routes.dart             # ルート名定義
│   ├── text_styles.dart        # テキストスタイル
│   └── responsive.dart         # レスポンシブ設定
│
├── extensions/                  # 拡張メソッド
│   ├── context_extensions.dart # BuildContext拡張
│   ├── datetime_extensions.dart # DateTime拡張
│   ├── list_extensions.dart    # List拡張
│   └── string_extensions.dart  # String拡張
│
├── models/                      # データモデル
│   ├── user.dart               # ユーザーモデル
│   ├── chat_room.dart          # チャットルームモデル
│   ├── friendship.dart         # フレンドシップモデル
│   ├── friend_request.dart     # フレンドリクエストモデル
│   ├── invitation.dart         # 招待モデル
│   ├── block.dart              # ブロックモデル
│   ├── administrator.dart      # 管理者モデル
│   ├── premium_log_model.dart  # プレミアムログモデル
│   └── question_message.dart   # お問い合わせメッセージ
│
├── repositories/                # データアクセス層
│   ├── base_repository.dart    # 基底リポジトリ
│   ├── user_repository.dart    # ユーザーデータ
│   ├── chat_room_repository.dart # ルームデータ
│   ├── friendship_repository.dart # フレンド関係
│   ├── block_repository.dart   # ブロック管理
│   └── premium_log_repository.dart # ログ管理
│
├── services/                    # ビジネスロジック層
│   ├── auth_service.dart       # 認証管理
│   ├── chat_service.dart       # チャット機能
│   ├── storage_service.dart    # データ永続化（抽象）
│   ├── firestore_storage_service.dart # Firestore実装
│   ├── invitation_service.dart # 招待機能（UI統合版）
│   ├── friendship_service.dart # フレンド管理
│   ├── block_service.dart      # ブロック機能
│   ├── fcm_service.dart        # プッシュ通知
│   ├── notification_cache_service.dart # 通知キャッシュ
│   ├── startup_invitation_service.dart # 起動時招待処理
│   ├── user_auth_service.dart  # ユーザー認証
│   ├── account_create_service.dart # アカウント作成
│   ├── password_hasher.dart    # パスワードハッシュ化
│   └── premium_log_service.dart # ログ管理
│
├── providers/                   # 状態管理
│   ├── user_provider.dart      # ユーザー状態
│   ├── admin_provider.dart     # 管理者状態
│   ├── chat_provider.dart      # チャット状態
│   └── premium_log_provider.dart # ログ状態
│
├── screens/                     # UI画面
│   ├── user/
│   │   ├── home_screen.dart    # ホーム画面
│   │   ├── profile.dart        # プロフィール
│   │   ├── chat_screen.dart    # チャット画面
│   │   ├── room_create_screen.dart # ルーム作成
│   │   ├── room_join_screen.dart # ルーム参加
│   │   ├── friend_list_screen.dart # フレンド一覧
│   │   ├── block_list_screen.dart # ブロック一覧
│   │   ├── notifications.dart  # 通知一覧
│   │   ├── user_login_page.dart # ログイン
│   │   ├── account_create_screen.dart # 新規登録
│   │   └── question_chat_user.dart # お問い合わせ
│   └── admin/
│       ├── admin_home_screen.dart # 管理者ホーム
│       ├── admin_login_screen.dart # 管理者ログイン
│       ├── premium_log_list_screen.dart # ログ一覧
│       └── admin_question_list_screen.dart # 問い合わせ管理
│
├── widgets/                     # 再利用可能ウィジェット
│   ├── common/
│   │   ├── header.dart         # 統一ヘッダー
│   │   └── unified_widgets.dart # 統一UI部品
│   ├── layout/
│   │   └── app_page_scaffold.dart # 共通レイアウト
│   ├── evaluation_dialog.dart  # 評価ダイアログ
│   ├── extension_request_dialog.dart # 延長リクエスト
│   ├── message_bubble.dart     # メッセージ表示
│   └── message_input_field.dart # メッセージ入力
│
├── routes/                      # ルーティング
│   ├── app_router.dart         # ルート生成
│   ├── navigation_helper.dart  # ナビゲーション補助
│   └── routes_guard.dart       # ルートガード
│
├── utils/                       # ユーティリティ
│   ├── app_logger.dart         # ロギングシステム
│   ├── navigation_logger.dart  # ナビゲーションログ
│   └── app_exceptions.dart     # カスタム例外
│
└── main.dart                    # エントリーポイント
```

### アーキテクチャパターン

**Repository Pattern + Provider + Service層**

```
UI層（Screens/Widgets）
    ↓ Provider
状態管理層（Providers）
    ↓ Service
ビジネスロジック層（Services）
    ↓ Repository
データアクセス層（Repositories）
    ↓ Firestore
データベース（Firebase Cloud Firestore）
```

#### レイヤーの責務

- **UI層**: ユーザーインターフェース、イベントハンドリング
- **Provider層**: 状態管理、UIへの変更通知
- **Service層**: ビジネスロジック、複数Repositoryの調整
- **Repository層**: Firestoreアクセスの抽象化、CRUD操作
- **Extensions**: Dart標準型の機能拡張、ユーティリティ

---

## 🚀 セットアップ

### 必要要件

- Flutter SDK 3.5以上
- Dart 3.2以上
- Firebase CLI
- Node.js 16以上（Firebaseエミュレータ用）

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

# Firebaseにログイン
firebase login

# Firebaseプロジェクトの初期化
firebase init
```

4. **環境変数の設定**

`.env`ファイルを作成：
```env
# 環境設定
ENVIRONMENT=development

# Firebase モード
FIREBASE_MODE=emulator  # emulator or production

# バックエンド選択
BACKEND=firebase        # firebase or aws

# デバッグモード
DEBUG_MODE=true

# エミュレーター設定
EMULATOR_HOST=localhost
AUTH_EMULATOR_PORT=9099
FIRESTORE_EMULATOR_PORT=8080
DATABASE_EMULATOR_PORT=9000
```

5. **Firebase構成ファイルの生成**
```bash
# FlutterFire CLIをインストール
dart pub global activate flutterfire_cli

# Firebase構成を自動生成
flutterfire configure
```

6. **Firebaseエミュレータの起動**（開発環境）
```bash
firebase emulators:start
```

7. **アプリの起動**
```bash
flutter run
```

---

## 🔥 Firebase構成

### 使用サービス

- **Firebase Authentication**: ユーザー認証
- **Cloud Firestore**: NoSQLデータベース
- **Firebase Cloud Messaging (FCM)**: プッシュ通知
- **Firebase Emulator**: ローカル開発環境

### Firestoreコレクション構造

```
users/                           # ユーザーコレクション
  {userId}/
    - id: string (Email)
    - password: string (hashed)
    - firstName: string
    - lastName: string
    - nickname: string
    - phoneNumber: string?
    - rate: number
    - premium: boolean
    - roomCount: number
    - createdAt: timestamp
    - lastUpdatedPremium: timestamp?
    - deletedAt: timestamp?
    - fcmToken: string?
    - fcmTokenUpdatedAt: timestamp?

rooms/                           # チャットルーム
  {roomId}/
    - id: string
    - topic: string
    - status: number (0: 待機, 1: 会話中, 2: 終了)
    - id1: string (creator)
    - id2: string? (participant)
    - comment1: string?
    - comment2: string?
    - extensionCount: number
    - extension: number
    - startedAt: timestamp
    - expiresAt: timestamp
    - private: boolean          # ✅ 新機能: Public/Private

friendships/                     # フレンドシップ
  {friendshipId}/
    - id: string
    - userId: string
    - friendId: string
    - active: boolean
    - createdAt: timestamp

friendRequests/                  # フレンドリクエスト
  {requestId}/
    - id: string
    - senderId: string
    - receiverId: string
    - status: string (pending/accepted/rejected)
    - createdAt: timestamp
    - respondedAt: timestamp?

blocks/                          # ブロック
  {blockId}/
    - id: string
    - blockerId: string
    - blockedId: string
    - active: boolean
    - createdAt: timestamp

invitations/                     # ルーム招待
  {invitationId}/
    - id: string
    - roomId: string
    - inviterId: string
    - inviteeId: string
    - status: string (pending/accepted/rejected/expired)
    - createdAt: timestamp
    - respondedAt: timestamp?
    - expiresAt: timestamp

evaluations/                     # ユーザー評価
  {evaluationId}/
    - id: string
    - evaluatorId: string
    - evaluatedId: string
    - rating: string (thumbs_up/thumbs_down)
    - createdAt: timestamp

extensionRequests/               # 延長リクエスト
  {requestId}/
    - id: string
    - roomId: string
    - requesterId: string
    - status: string (pending/approved/rejected)
    - createdAt: timestamp

administrator/                   # 管理者
  {email}/
    - Password: string
    - Role: string
    - LastLogin: timestamp?

QuestionChat/                    # お問い合わせ
  {chatId}/
    - UserID: string
    - AdminID: string?
    - LastMessage: string
    - UpdatedAt: timestamp
    - Status: string (pending/in_progress/resolved)
    
    Messages/                    # サブコレクション
      {messageId}/
        - ID: string
        - IsAdmin: boolean
        - Text: string
        - CreatedAt: timestamp
        - Read: boolean

Log_Premium/                     # プレミアムログ
  {logId}/
    - ID: string (Email)
    - Timestamp: timestamp
    - Detail: string (契約/解約)

PremiumCounter/                  # プレミアム会員数カウンター
  counter/
    - count: number
    - lastUpdated: timestamp
```

---

## 📦 依存パッケージ

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI/UX
  google_fonts: ^6.3.2
  
  # Firebase
  firebase_core: ^4.2.1
  firebase_auth: ^6.1.2
  cloud_firestore: ^6.1.0
  firebase_messaging: ^15.2.1
  
  # ローカル通知
  flutter_local_notifications: ^18.0.1
  
  # 状態管理
  provider: ^6.1.2
  
  # ユーティリティ
  http: ^1.6.0
  crypto: ^3.0.3
  shared_preferences: ^2.2.2
  intl: ^0.19.0
  path_provider: ^2.1.5
  flutter_dotenv: ^5.2.1
  
  # その他
  image_picker: ^1.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

---

## 🎯 主要機能の実装詳細

### 1. 認証システム

**Firebase Authentication + Firestore連携 + パスワードハッシュ化**

```dart
// services/account_create_service.dart
Future<bool> register({
  required User user,
  required String password,
  required StorageService storageService,
}) async {
  // 1. パスワードをハッシュ化
  final salt = PasswordHasher.generateSalt();
  final passwordHash = PasswordHasher.hashPassword(password, salt);
  
  // 2. Firebase Authにユーザー作成
  final credential = await _auth.createUserWithEmailAndPassword(
    email: user.id,
    password: password,
  );
  
  // 3. Firestoreにユーザー情報保存
  final userWithPassword = User(
    id: user.id,
    password: passwordHash,
    // その他のフィールド...
  );
  
  storageService.users.add(userWithPassword);
  await storageService.save();
  
  return true;
}
```

### 2. プライベート/パブリックルーム機能

**ルーム作成時にプライバシー設定を選択**

```dart
// screens/user/room_create_screen.dart
final newRoom = ChatRoom(
  id: roomId,
  topic: roomName,
  status: AppConstants.roomStatusWaiting,
  id1: currentUserEmail,
  id2: null,
  private: _isPrivate, // ✅ プライバシー設定
  // ...
);

await _roomRepository.create(newRoom, id: roomId);
```

**検索・参加機能でプライベートルームを除外**

```dart
// services/chat_service.dart
final filteredRooms = rooms.where((room) {
  // プライベートルームは検索結果から除外
  if (room.private) {
    return false;
  }
  // その他のフィルタリング条件...
}).toList();
```

### 3. フレンド招待機能（UI統合版）

**InvitationServiceでダイアログ表示まで処理**

```dart
// services/invitation_service.dart
Future<void> showInviteFriendDialog({
  required BuildContext context,
  required String roomId,
  required String currentUserId,
}) async {
  // フレンド一覧を取得
  final friendships = _storageService.friendships.where((f) {
    return f.active && 
           (f.userId == currentUserId || f.friendId == currentUserId);
  }).toList();
  
  // ダイアログを表示
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('フレンドを招待'),
      content: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return ListTile(
            title: Text(friend['name']),
            trailing: ElevatedButton(
              onPressed: () async {
                await sendInvitation(
                  roomId: roomId,
                  inviterId: currentUserId,
                  inviteeId: friend['id'],
                );
                Navigator.pop(ctx);
              },
              child: Text('招待'),
            ),
          );
        },
      ),
    ),
  );
}
```

### 4. 通知キャッシュシステム

**5分間キャッシュ + 自動リフレッシュ**

```dart
// services/notification_cache_service.dart
class NotificationCacheService {
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  int _friendRequestCount = 0;
  int _invitationCount = 0;
  DateTime? _lastFetchedAt;
  Timer? _autoRefreshTimer;
  
  Future<int> getCount({
    required String userId,
    bool forceRefresh = false,
  }) async {
    // キャッシュが有効なら即返す
    if (!forceRefresh && isCacheValid) {
      return totalCount;
    }
    
    // 無効なら再取得
    await _fetch(userId);
    return totalCount;
  }
  
  void startAutoRefresh(String userId) {
    _autoRefreshTimer = Timer.periodic(_cacheDuration, (_) async {
      await _fetch(userId);
    });
  }
}
```

### 5. レスポンシブデザイン

**Context拡張メソッドで簡単にレスポンシブ対応**

```dart
// constants/responsive.dart
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  
  double responsiveFontSize(double baseFontSize) {
    return ResponsiveHelper.getResponsiveFontSize(this, baseFontSize);
  }
}

// 使用例
Widget build(BuildContext context) {
  final isMobile = context.isMobile;
  final fontSize = context.responsiveFontSize(16);
  
  return Text(
    'レスポンシブテキスト',
    style: TextStyle(fontSize: fontSize),
  );
}
```

### 6. リアルタイムチャット

**StreamとTimerの併用で正確なタイマー管理**

```dart
// services/chat_service.dart
void startRoomTimer(String roomId, DateTime expiresAt) {
  _roomTimers[roomId]?.cancel();
  
  final duration = expiresAt.difference(DateTime.now());
  
  if (duration.isNegative) {
    deleteRoom(roomId);
    return;
  }
  
  _roomTimers[roomId] = Timer(duration, () async {
    await deleteRoom(roomId);
  });
}
```

### 7. 統一ロギングシステム

**ファイル出力 + コンソール出力 + Dart DevTools連携**

```dart
// utils/app_logger.dart
logger.section('処理開始', name: 'ServiceName');
logger.start('処理中...', name: 'ServiceName');
logger.success('成功', name: 'ServiceName');
logger.error('エラー: $e', name: 'ServiceName', error: e, stackTrace: stack);
```

---

## 🛡️ セキュリティ

### 実装済みセキュリティ機能

1. **パスワードハッシュ化**: PBKDF2ベース（10,000回イテレーション）
2. **タイミング攻撃対策**: 定数時間比較アルゴリズム
3. **論理削除**: `deletedAt`フィールドによる削除管理
4. **ブロック機能**: 不適切ユーザーのブロック
5. **管理者認証**: Firestore管理者コレクションでの権限確認
6. **入力バリデーション**: フォーム入力の徹底的な検証

### Firestore Securityルール例

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーコレクション
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // チャットルーム
    match /rooms/{roomId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (resource.data.id1 == request.auth.token.email || 
         resource.data.id2 == request.auth.token.email);
    }
    
    // フレンドリクエスト
    match /friendRequests/{requestId} {
      allow read: if request.auth != null && 
        (resource.data.senderId == request.auth.token.email ||
         resource.data.receiverId == request.auth.token.email);
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        resource.data.receiverId == request.auth.token.email;
    }
    
    // 招待
    match /invitations/{invitationId} {
      allow read: if request.auth != null &&
        (resource.data.inviterId == request.auth.token.email ||
         resource.data.inviteeId == request.auth.token.email);
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        resource.data.inviteeId == request.auth.token.email;
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

# カバレッジレポート生成
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 📱 ビルド

### Android
```bash
# デバッグビルド
flutter build apk --debug

# リリースビルド
flutter build apk --release

# App Bundle（Google Play推奨）
flutter build appbundle --release
```

### iOS
```bash
# デバッグビルド
flutter build ios --debug

# リリースビルド
flutter build ios --release
```

### Web
```bash
# リリースビルド
flutter build web --release

# ホスティング（Firebase Hosting）
firebase deploy --only hosting
```

---

## 🐛 トラブルシューティング

### よくある問題

**Q: Firebaseエミュレータに接続できない**

```bash
# エミュレータが起動しているか確認
firebase emulators:start

# ポート確認
lsof -i :8080  # Firestore
lsof -i :9099  # Auth

# .envファイルの設定確認
FIREBASE_MODE=emulator
EMULATOR_HOST=localhost
```

**Q: ログイン後にユーザー情報が表示されない**

```dart
// HomeScreenのdidChangeDependencies()で確認
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final userProvider = context.read<UserProvider>();
  
  if (userProvider.currentUser == null && !userProvider.isLoading) {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      userProvider.loadUserData(email);
    }
  }
}
```

**Q: 通知数が更新されない**

```dart
// NotificationCacheServiceの動作確認
final cacheService = context.read<NotificationCacheService>();

// 強制リフレッシュ
await cacheService.getCount(
  userId: currentUserId,
  forceRefresh: true,
);

// キャッシュ無効化
cacheService.invalidateCache();
```

**Q: プライベートルームが検索結果に表示される**

```dart
// ChatService.searchRooms()のフィルタリング確認
final filteredRooms = allRooms.where((room) {
  // プライベートルームは除外されているか確認
  if (room.private) {
    logger.debug('除外: プライベートルーム - ${room.topic}');
    return false;
  }
  return true;
}).toList();
```

---

## 🤝 コントリビューション

プルリクエストを歓迎します！

### 開発フロー

1. フォーク
2. 機能ブランチ作成 (`git checkout -b feature/amazing-feature`)
3. コミット (`git commit -m 'Add amazing feature'`)
4. プッシュ (`git push origin feature/amazing-feature`)
5. プルリクエスト作成

### コーディング規約

- Dart公式スタイルガイドに準拠
- すべてのpublicメソッドにドキュメントコメント記載
- `flutter analyze`でエラーゼロを維持
- `logger`を使用した詳細なログ出力

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
- [Cloud Firestore ベストプラクティス](https://firebase.google.com/docs/firestore/best-practices)

---

## 🗺️ ロードマップ

### 実装済み（v1.0）
- ✅ 基本チャット機能
- ✅ プライベート/パブリックルーム
- ✅ フレンド招待システム
- ✅ 通知キャッシュシステム
- ✅ レスポンシブデザイン
- ✅ プレミアムプラン
- ✅ 管理者機能

### 今後の予定（v1.1以降）
- [ ] プッシュ通知（FCM完全統合）
- [ ] 画像・ファイル共有
- [ ] グループチャット機能
- [ ] AI自動翻訳
- [ ] ダークモード対応
- [ ] Web版の最適化
- [ ] E2E暗号化
- [ ] ボイスチャット機能

---

## 📊 統計情報

- **総コード行数**: ~25,000行
- **モデル数**: 18個
- **Repository数**: 8個
- **サービス数**: 15個
- **Provider数**: 4個
- **画面数**: 25画面以上
- **共通ウィジェット数**: 20個以上
- **拡張メソッド数**: 30個以上

---

## 🏆 主要な技術的特徴

1. **完全なRepository Pattern実装**: データアクセス層の完全な抽象化
2. **Service層でのビジネスロジック集約**: 複数Repositoryの調整、トランザクション管理
3. **包括的なログシステム**: ファイル出力、コンソール出力、Dart DevTools統合
4. **型安全な拡張メソッド**: Context、DateTime、List、String等の便利な拡張
5. **レスポンシブデザイン**: モバイル・タブレット・デスクトップ完全対応
6. **通知キャッシュ最適化**: 5分間キャッシュ + 自動リフレッシュで通信量削減
7. **統一UIコンポーネント**: 再利用可能なウィジェット群で開発効率向上
8. **エラーハンドリング**: カスタム例外クラスによる統一的なエラー処理
9. **パフォーマンス最適化**: StreamとTimerの効率的な使用、メモリリーク防止
10. **セキュリティ重視**: パスワードハッシュ化、論理削除、タイミング攻撃対策

---

## 💡 コード設計のポイント

### Repository Pattern

```dart
// repositories/base_repository.dart
abstract class BaseRepository<T> {
  String get collectionName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T model);
  
  Future<String> create(T model, {String? id});
  Future<T?> findById(String id);
  Future<List<T>> findAll();
  Future<void> update(String id, T model);
  Future<void> delete(String id);
  
  Stream<T?> watchById(String id);
  Stream<List<T>> watchAll();
}
```

すべてのRepositoryは`BaseRepository`を継承し、Firestoreアクセスを統一的に管理します。

### Service層のビジネスロジック

```dart
// services/friendship_service.dart
Future<void> acceptFriendRequest(FriendRequest request) async {
  // 1. リクエストを承認状態に更新
  await _friendRequestRepository.acceptRequest(request.id);
  
  // 2. Friendshipドキュメントを作成
  final friendship = Friendship(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    userId: request.senderId,
    friendId: request.receiverId,
    active: true,
    createdAt: DateTime.now(),
  );
  
  await _friendshipRepository.create(friendship, id: friendship.id);
}
```

Service層で複数のRepository操作を調整し、トランザクション的な処理を実現します。

### Provider による状態管理

```dart
// providers/user_provider.dart
class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  User? _currentUser;
  bool _isLoading = false;
  
  Future<void> loadUserData(String email) async {
    _isLoading = true;
    notifyListeners();
    
    _currentUser = await _userRepository.findByEmail(email);
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> updatePremiumStatus(bool isPremium) async {
    await _userRepository.updatePremiumStatus(_currentUser!.id, isPremium);
    
    _currentUser = _currentUser!.copyWith(
      premium: isPremium,
      lastUpdatedPremium: DateTime.now(),
    );
    
    notifyListeners();
  }
}
```

Providerで状態を管理し、UIに変更を通知します。

### 拡張メソッドの活用

```dart
// extensions/context_extensions.dart
extension ContextExtensions on BuildContext {
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Future<bool> showConfirmDialog({
    required String message,
    String confirmText = 'OK',
    String cancelText = 'キャンセル',
  }) async {
    // ダイアログ実装...
  }
}

// 使用例
context.showSuccessSnackBar('保存しました');
final confirmed = await context.showConfirmDialog(
  message: '本当に削除しますか？',
);
```

拡張メソッドでコードを簡潔にし、可読性を向上させます。

---

## 🎨 UI/UXデザイン

### カラーパレット

```dart
// constants/colors.dart
class AppColors {
  // プライマリカラー
  static const Color primary = Color(0xFF667EEA);
  static const Color secondary = Color(0xFF764BA2);
  
  // グラデーション
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
  );
  
  // ステータスカラー
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;
}
```

### レスポンシブブレークポイント

- **モバイル**: < 600px
- **タブレット**: 600px - 900px
- **デスクトップ**: ≥ 900px
- **大画面デスクトップ**: ≥ 1200px

### 統一UIコンポーネント

```dart
// widgets/common/unified_widgets.dart

// 情報カード
InfoCard(
  icon: Icons.info_outline,
  title: 'ルーム情報',
  children: [
    InfoItem(text: '最大2人まで参加可能'),
    InfoItem(text: '10分間のチャット'),
  ],
);

// グラデーションボタン
GradientButton(
  label: 'ルームを作成',
  icon: Icons.add_circle,
  onPressed: _createRoom,
);

// 空の状態表示
EmptyStateWidget(
  icon: Icons.inbox,
  title: '通知はありません',
  subtitle: '新しい通知が届くとここに表示されます',
);

// ユーザーアバター
UserAvatar(
  name: 'ユーザー名',
  size: 56,
  gradient: AppColors.primaryGradient,
);
```

---

## 📈 パフォーマンス最適化

### 実装済み最適化

1. **通知キャッシュシステム**: 5分間キャッシュでFirestoreクエリ削減
2. **StreamとTimerの効率的管理**: メモリリーク防止のため適切にcancel/dispose
3. **lazy loading**: 必要なデータのみを必要なタイミングで取得
4. **画像最適化**: image_pickerでの圧縮処理
5. **State管理の最適化**: 不必要なrebuildを防ぐ

### キャッシュ戦略

```dart
// services/notification_cache_service.dart
class NotificationCacheService {
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  Future<int> getCount({
    required String userId,
    bool forceRefresh = false,
  }) async {
    // キャッシュが有効ならFirestoreアクセスなし
    if (!forceRefresh && isCacheValid) {
      return totalCount;
    }
    
    // 無効なら再取得してキャッシュ更新
    await _fetch(userId);
    return totalCount;
  }
}
```

---

## 🔐 プライバシーとデータ保護

### データ管理ポリシー

1. **論理削除**: 物理削除ではなく`deletedAt`フィールドでの論理削除
2. **パスワード保護**: ハッシュ化されたパスワードのみ保存
3. **個人情報の最小化**: 必要最小限の情報のみ収集
4. **ブロック機能**: ユーザーが不快なユーザーをブロック可能
5. **データ暗号化**: Firestore通信はすべてSSL/TLS暗号化

### GDPR準拠

- ユーザーは自身のデータを削除可能（論理削除）
- データ収集の透明性確保
- プライバシーポリシーの明示

---

## 🌐 デプロイメント

### Firebase Hosting（Web版）

```bash
# ビルド
flutter build web --release

# デプロイ
firebase deploy --only hosting
```

### Google Play Store（Android）

```bash
# App Bundle作成
flutter build appbundle --release

# 署名確認
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

### App Store（iOS）

```bash
# iOSビルド
flutter build ios --release

# Xcodeで署名・アップロード
open ios/Runner.xcworkspace
```

---

## 📞 サポート

### お問い合わせ

- **Email**: support@whispin.app
- **GitHub Issues**: [Issues](https://github.com/your-repo/whispin/issues)
- **ドキュメント**: [Wiki](https://github.com/your-repo/whispin/wiki)

### よくある質問（FAQ）

**Q: プレミアムプランの料金は？**
A: 現在開発中の機能です。詳細は後日発表予定です。

**Q: データはどこに保存されますか？**
A: すべてのデータはGoogle Cloud Firestore（日本リージョン）に保存されます。

**Q: アカウントを完全に削除できますか？**
A: はい、プロフィール画面から「アカウント削除」で論理削除が可能です。

---

## 🙏 謝辞

このプロジェクトは以下のオープンソースプロジェクトを使用しています：

- Flutter & Dart by Google
- Firebase by Google
- Provider package by Remi Rousselet
- その他多数のFlutterパッケージ

すべてのコントリビューターに感謝します。

---

## 📝 変更履歴

### v1.0.0 (2026-01-09)
- 🎉 初回リリース
- ✨ 基本チャット機能
- ✨ フレンド機能
- ✨ ブロック機能
- ✨ プレミアムプラン
- ✨ 管理者機能

### v1.1.0 (予定)
- 🚀 プッシュ通知完全統合
- 🌍 多言語対応
- 🎨 ダークモード
- 📱 レスポンシブデザイン強化

---

**最終更新**: 2026年1月9日
**バージョン**: 1.0.0
**ライセンス**: MIT

---

## ⚙️ 環境設定ガイド

### 開発環境

```bash
# Flutterバージョン確認
flutter --version

# デバイス確認
flutter devices

# 依存関係の確認
flutter doctor
```

### 本番環境

```env
ENVIRONMENT=production
FIREBASE_MODE=production
BACKEND=firebase
DEBUG_MODE=false
```

### ステージング環境

```env
ENVIRONMENT=staging
FIREBASE_MODE=production
BACKEND=firebase
DEBUG_MODE=true
```

---

Happy Coding! 🚀✨