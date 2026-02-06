import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'services/block_service.dart';
import 'config/environment.dart';
import 'config/firebase_config.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'constants/routes.dart';
import 'services/storage_service.dart';
import 'services/firestore_storage_service.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/fcm_service.dart';
import 'services/invitation_service.dart';
import 'services/startup_invitation_service.dart';
import 'services/friendship_service.dart';
import 'services/notification_cache_service.dart';
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
  if (kIsWeb) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  logger.section('バックグラウンドメッセージ受信', name: 'FCM_BG');
  logger.info('Data: ${message.data}', name: 'FCM_BG');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env読み込み
  await dotenv.load(fileName: '.env');
  Environment.loadFromEnv();
  Environment.printConfiguration();

  // Firebase初期化
  await FirebaseConfig.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCMバックグラウンドハンドラー登録
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }

  // 日付フォーマット初期化
  await initializeDateFormatting('ja_JP', null);

  // ログシステムの初期化
  await logger.initialize();

  logger.section('🚀 Whispin アプリ起動中...', name: 'Main');

  // Services層の初期化
  logger.start('Services 初期化中...', name: 'Main');
  final storageService = FirestoreStorageService();
  await storageService.initialize();
  await storageService.load();
  storageService.startListening();

  final authService = AuthService(storageService);
  await authService.initialize();

  final chatService = ChatService(storageService);

  // FCMサービスの初期化
  final fcmService = FCMService();
  await fcmService.initialize();

  // 招待サービスの初期化
  final invitationService = InvitationService(storageService);
  final startupInvitationService = StartupInvitationService(
    storageService: storageService,
    invitationService: invitationService,
    fcmService: fcmService,
  );

  // ThemeProviderの初期化
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  logger.success('Services 初期化完了', name: 'Main');

  // Repository層の初期化
  logger.start('Repositories 初期化中...', name: 'Main');
  final userRepository = UserRepository();
  final friendshipRepository = FriendshipRepository();
  final friendRequestRepository = FriendRequestRepository();
  final chatRoomRepository = ChatRoomRepository();
  final blockRepository = BlockRepository();

  logger.success('Repositories 初期化完了', name: 'Main');

  // Service層の初期化
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

  runApp(
    MultiProvider(
      providers: [
        // Providers
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(
          create: (_) => UserProvider(userRepository: userRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(userRepository: userRepository),
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        Provider<NotificationCacheService>.value(
            value: notificationCacheService),

        // Services
        Provider<StorageService>.value(value: storageService),
        Provider<AuthService>.value(value: authService),
        Provider<ChatService>.value(value: chatService),
        Provider<FCMService>.value(value: fcmService),
        Provider<InvitationService>.value(value: invitationService),
        Provider<StartupInvitationService>.value(
            value: startupInvitationService),
        Provider<FriendshipService>.value(value: friendshipService),
        Provider<BlockService>.value(value: blockService),

        // Repositories
        Provider<UserRepository>.value(value: userRepository),
        Provider<FriendshipRepository>.value(value: friendshipRepository),
        Provider<FriendRequestRepository>.value(value: friendRequestRepository),
        Provider<ChatRoomRepository>.value(value: chatRoomRepository),
        Provider<BlockRepository>.value(value: blockRepository),
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