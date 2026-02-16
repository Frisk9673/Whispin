// アプリ起動フロー概要:
// 1) .env/Environment初期化
// 2) Firebase初期化
// 3) 各Service初期化
// 4) Repository初期化
// 5) Provider登録
// 6) runApp実行
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'services/user/block_service.dart';
import 'config/environment.dart';
import 'config/firebase_config.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'constants/routes.dart';
import 'services/user/storage_service.dart';
import 'services/user/firestore_storage_service.dart';
import 'services/user/auth_service.dart';
import 'services/user/chat_service.dart';
import 'services/user/fcm_service.dart';
import 'services/user/invitation_service.dart';
import 'services/user/startup_invitation_service.dart';
import 'services/user/friendship_service.dart';
import 'services/user/notification_cache_service.dart';
import 'providers/chat_provider.dart';
import 'providers/user_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/theme_provider.dart';
import 'repositories/user_repository.dart';
import 'repositories/friendship_repository.dart';
import 'repositories/chat_room_repository.dart';
import 'repositories/block_repository.dart';
import 'utils/navigation_logger.dart';
import 'utils/app_logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // このハンドラーはバックグラウンド isolate 上で実行されるため、
  // UI操作やBuildContextへのアクセスは不可。必要最小限の初期化と処理のみ行う。
  if (kIsWeb) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  logger.section('バックグラウンドメッセージ受信', name: 'FCM_BG');
  logger.info('Data: ${message.data}', name: 'FCM_BG');
}

Future<void> main() async {
  // Flutterエンジンを初期化し、以降の非同期セットアップを安全に実行できる状態にする。
  WidgetsFlutterBinding.ensureInitialized();

  // 設定値の初期化: .envを読み込み、Environmentへ反映して以降の初期化が参照できるようにする。
  await dotenv.load(fileName: '.env');
  Environment.loadFromEnv();
  Environment.printConfiguration();

  // Firebase基盤の初期化: FCMや認証などFirebase依存サービス利用前に必須。
  await FirebaseConfig.initialize();

  // FCM受信処理の登録: Firebase初期化後に、バックグラウンド通知のハンドラーを紐付ける。
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }

  // ロケール依存機能の初期化: 日付表示で日本語フォーマットを使用するため事前準備する。
  await initializeDateFormatting('ja_JP', null);

  // ログ基盤の初期化: 起動後の各レイヤー初期化ログを正しく記録するため先に有効化する。
  await logger.initialize();

  logger.section('🚀 Whispin アプリ起動中...', name: 'Main');

  // Service層の基盤初期化: 永続化・認証・通知など、Repository/Providerが依存する実処理を生成する。
  logger.start('Services 初期化中...', name: 'Main');
  final storageService = FirestoreStorageService();
  await storageService.initialize();
  await storageService.load();
  storageService.startListening();

  final authService = AuthService(storageService);
  await authService.initialize();

  final chatService = ChatService(storageService);

  // 通知サービス初期化: FCMを有効化し、招待通知などの受信処理に備える。
  final fcmService = FCMService();
  await fcmService.initialize();

  // 起動時招待導線の初期化: Storage/Invitation/FCMを束ねて、起動後チェックで利用可能にする。
  final invitationService = InvitationService(storageService);
  final startupInvitationService = StartupInvitationService(
    storageService: storageService,
    invitationService: invitationService,
    fcmService: fcmService,
  );

  // UI設定の初期化: runApp前にテーマ状態を読み込み、初期描画へ即時反映できるようにする。
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  logger.success('Services 初期化完了', name: 'Main');

  // Repository層の初期化: データアクセス窓口を生成し、上位Service/Providerへ注入可能にする。
  logger.start('Repositories 初期化中...', name: 'Main');
  final userRepository = UserRepository();
  final friendshipRepository = FriendshipRepository();
  final friendRequestRepository = FriendRequestRepository();
  final chatRoomRepository = ChatRoomRepository();
  final blockRepository = BlockRepository();

  logger.success('Repositories 初期化完了', name: 'Main');

  // ドメインServiceの初期化: Repositoryを組み合わせたユースケース処理を構築する。
  logger.start('FriendshipService 初期化中...', name: 'Main');
  final friendshipService = FriendshipService(
    friendshipRepository: friendshipRepository,
    friendRequestRepository: friendRequestRepository,
  );
  logger.success('FriendshipService 初期化完了', name: 'Main');

  logger.start('BlockService 初期化中...', name: 'Main');
  final blockService = BlockService(
    blockRepository: blockRepository,
    userRepository: userRepository,
  );
  logger.success('BlockService 初期化完了', name: 'Main');

  logger.start('NotificationCacheService 初期化中...', name: 'Main');
  final notificationCacheService = NotificationCacheService(
    friendRequestRepository: friendRequestRepository,
    invitationService: invitationService,
  );
  logger.success('NotificationCacheService 初期化完了', name: 'Main');

  logger.section('✨ アプリ起動準備完了！', name: 'Main');

  // Provider登録とrunApp: 画面層が必要な状態/サービスへアクセスできるよう依存性を配線して起動する。
  runApp(
    MultiProvider(
      providers: [
        // Providers
        ChangeNotifierProvider(create: (_) => ChatProvider()), // チャット一覧/トーク画面の状態管理
        ChangeNotifierProvider(
          create: (_) => UserProvider(userRepository: userRepository), // プロフィール表示・ユーザー情報同期
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(userRepository: userRepository), // 管理者向けユーザー管理機能
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider), // 全画面のライト/ダークテーマ切替
        Provider<NotificationCacheService>.value(
            value: notificationCacheService), // 通知バッジ/未処理通知キャッシュ参照

        // Services
        Provider<StorageService>.value(value: storageService), // ログイン状態・ユーザーデータの永続化
        Provider<AuthService>.value(value: authService), // 認証フロー(ログイン/ログアウト/セッション管理)
        Provider<ChatService>.value(value: chatService), // チャット送受信・履歴取得機能
        Provider<FCMService>.value(value: fcmService), // Push通知登録・トークン管理
        Provider<InvitationService>.value(value: invitationService), // 招待作成/承認など招待機能
        Provider<StartupInvitationService>.value(
            value: startupInvitationService), // アプリ起動時の招待処理導線
        Provider<FriendshipService>.value(value: friendshipService), // フレンド申請/承認/解除機能
        Provider<BlockService>.value(value: blockService), // ユーザーブロック/解除機能

        // Repositories
        Provider<UserRepository>.value(value: userRepository), // ユーザー情報取得・更新のデータアクセス
        Provider<FriendshipRepository>.value(value: friendshipRepository), // フレンド関係データの永続化操作
        Provider<FriendRequestRepository>.value(value: friendRequestRepository), // フレンド申請データの取得/更新
        Provider<ChatRoomRepository>.value(value: chatRoomRepository), // チャットルーム一覧・メッセージ関連データ
        Provider<BlockRepository>.value(value: blockRepository), // ブロック関係データの取得/更新
      ],
      child: MyApp(
        authService: authService,
        storageService: storageService,
        startupInvitationService: startupInvitationService,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AuthService authService;
  final FirestoreStorageService storageService;
  final StartupInvitationService startupInvitationService;

  const MyApp({
    super.key,
    required this.authService,
    required this.storageService,
    required this.startupInvitationService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // アプリ起動後に招待をチェック
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInvitations();
    });
  }

  Future<void> _checkInvitations() async {
    logger.section('アプリ起動後の招待チェック', name: 'MyApp');

    final currentUser = widget.authService.currentUser;
    if (currentUser == null) {
      logger.info('未ログイン - 招待チェックスキップ', name: 'MyApp');
      return;
    }

    final context = _navigatorKey.currentContext;
    if (context == null) {
      logger.warning('Contextが取得できません', name: 'MyApp');
      return;
    }

    await widget.startupInvitationService.checkAndHandleInvitations(
      context,
      currentUser.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Whispin',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppConfig.lightTheme,
          darkTheme: AppConfig.darkTheme,
          navigatorObservers: [
            NavigationLogger(),
          ],
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppRoutes.home,
        );
      },
    );
  }
}
