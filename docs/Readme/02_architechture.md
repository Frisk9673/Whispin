# 🏗️ 02 — アーキテクチャ

## レイヤー構成

```
UI層（Screens / Widgets）
        ↓ Provider
状態管理層（Providers）
        ↓ Service
ビジネスロジック層（Services）
        ↓ Repository
データアクセス層（Repositories）
        ↓ Firestore SDK
データベース（Firebase Cloud Firestore）
```

### 各レイヤーの責務

| レイヤー | 責務 |
|---|---|
| **UI層** | ユーザーインターフェース、イベントハンドリング |
| **Provider層** | 状態管理、UIへの変更通知 |
| **Service層** | ビジネスロジック、複数Repositoryの調整 |
| **Repository層** | Firestoreアクセスの抽象化、CRUD操作 |
| **Extensions** | Dart標準型の機能拡張、ユーティリティ |

---

## プロジェクト構造

```
lib/
├── config/               # アプリケーション設定
│   ├── app_config.dart       # Theme設定（Light / Dark）
│   ├── environment.dart      # 環境変数管理（.env）
│   └── firebase_config.dart  # Firebase初期化
│
├── constants/            # 定数定義
│   ├── app_constants.dart    # アプリ全体の定数
│   ├── colors.dart           # カラーパレット
│   ├── routes.dart           # ルート名定義
│   ├── text_styles.dart      # テキストスタイル
│   ├── responsive.dart       # レスポンシブ設定
│   └── navigation_items.dart # ナビゲーション定義
│
├── extensions/           # 拡張メソッド
│   ├── context_extensions.dart   # BuildContext拡張
│   ├── datetime_extensions.dart  # DateTime拡張
│   ├── list_extensions.dart      # List拡張
│   └── string_extensions.dart    # String拡張
│
├── models/               # データモデル
│   ├── user.dart
│   ├── chat_room.dart
│   ├── friendship.dart
│   ├── friend_request.dart
│   ├── invitation.dart
│   ├── block.dart
│   ├── extension_request.dart
│   ├── user_evaluation.dart
│   ├── administrator.dart
│   ├── premium_log_model.dart
│   ├── premium_counter.dart
│   └── question_message.dart
│
├── repositories/         # データアクセス層
│   ├── base_repository.dart       # 基底クラス（CRUD共通）
│   ├── user_repository.dart
│   ├── chat_room_repository.dart
│   ├── friendship_repository.dart
│   ├── block_repository.dart
│   └── premium_log_repository.dart
│
├── services/             # ビジネスロジック層
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── storage_service.dart           # 抽象インターフェース
│   ├── firestore_storage_service.dart # Firestore実装
│   ├── invitation_service.dart
│   ├── friendship_service.dart
│   ├── block_service.dart
│   ├── fcm_service.dart
│   ├── notification_cache_service.dart
│   ├── startup_invitation_service.dart
│   ├── user_auth_service.dart
│   ├── account_create_service.dart
│   ├── password_hasher.dart
│   ├── premium_log_service.dart
│   └── profile_image_service.dart
│
├── providers/            # 状態管理
│   ├── user_provider.dart
│   ├── admin_provider.dart
│   ├── chat_provider.dart
│   ├── theme_provider.dart
│   └── premium_log_provider.dart
│
├── screens/              # UI画面
│   ├── user/
│   │   ├── home_screen.dart
│   │   ├── profile.dart
│   │   ├── chat_screen.dart
│   │   ├── room_create_screen.dart
│   │   ├── room_join_screen.dart
│   │   ├── friend_list_screen.dart
│   │   ├── block_list_screen.dart
│   │   ├── notifications.dart
│   │   ├── user_login_page.dart
│   │   ├── account_create_screen.dart
│   │   └── question_chat_user.dart
│   └── admin/
│       ├── admin_home_screen.dart
│       ├── admin_login_screen.dart
│       ├── premium_log_list_screen.dart
│       └── admin_question_list_screen.dart
│
├── widgets/              # 再利用可能ウィジェット
│   ├── common/
│   │   ├── header.dart
│   │   ├── unified_widgets.dart
│   │   ├── message_bubble.dart
│   │   └── message_input_field.dart
│   ├── navigation/
│   │   ├── bottom_navigation_bar.dart
│   │   └── side_navigation_bar.dart
│   ├── evaluation_dialog.dart
│   └── extension_request_dialog.dart
│
├── routes/               # ルーティング
│   ├── app_router.dart
│   ├── navigation_helper.dart
│   └── routes_guard.dart
│
└── utils/                # ユーティリティ
    ├── app_logger.dart        # ロギングシステム
    ├── navigation_logger.dart # ナビゲーションログ
    └── app_exceptions.dart    # カスタム例外
```

---

## 依存パッケージ

```yaml
dependencies:
  # Firebase
  firebase_core: ^4.2.1
  firebase_auth: ^6.1.2
  cloud_firestore: ^6.1.0
  firebase_messaging: ^15.2.1
  firebase_storage: (使用)

  # 状態管理
  provider: ^6.1.2

  # UI
  google_fonts: ^6.3.2

  # ユーティリティ
  http: ^1.6.0
  crypto: ^3.0.3
  shared_preferences: ^2.2.2
  intl: ^0.19.0
  path_provider: ^2.1.5
  flutter_dotenv: ^5.2.1
  image_picker: ^1.2.1
  flutter_local_notifications: ^18.0.1
```