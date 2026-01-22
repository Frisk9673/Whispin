import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:whispin/config/environment.dart';
import 'package:whispin/config/firebase_config.dart';
import 'package:whispin/firebase_options.dart';
import 'package:whispin/routes/app_router.dart';
import 'package:whispin/constants/routes.dart';
import 'package:whispin/services/storage_service.dart';
import 'services/firestore_storage_service.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'providers/chat_provider.dart';
import 'providers/user_provider.dart';
import 'providers/admin_provider.dart';
import 'repositories/user_repository.dart';
import 'repositories/friendship_repository.dart';
import 'repositories/chat_room_repository.dart';
import 'repositories/block_repository.dart';
import 'utils/navigation_logger.dart';
import 'utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env読み込み
  await dotenv.load(fileName: '.env');
  Environment.loadFromEnv();
  
  // ✅ 追加: 起動時に環境情報を表示
  Environment.printConfiguration();
  
  await FirebaseConfig.initialize(); 
  await initializeDateFormatting('ja_JP', null);

  // ログシステムの初期化
  await logger.initialize();

  logger.section('🚀 Whispin アプリ起動中...', name: 'Main');
  
  // ✅ 追加: エミュレーター使用状況をログ出力
  if (Environment.shouldUseFirebaseEmulator) {
    logger.warning('⚠️ Firebaseエミュレーターモードで起動', name: 'Main');
    logger.info('  Auth: ${Environment.emulatorHost}:${Environment.authEmulatorPort}', name: 'Main');
    logger.info('  Firestore: ${Environment.emulatorHost}:${Environment.firestoreEmulatorPort}', name: 'Main');
  } else {
    logger.success('✅ Firebase本番モードで起動', name: 'Main');
  }

  // Firebase初期化（後方互換性のため残す）
  logger.start('Firebase 初期化中...', name: 'Main');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  logger.success('Firebase 初期化完了', name: 'Main');

  // Services層の初期化
  logger.start('Services 初期化中...', name: 'Main');
  final storageService = FirestoreStorageService();
  await storageService.initialize();
  await storageService.load();
  storageService.startListening();

  final authService = AuthService(storageService);
  await authService.initialize();

  final chatService = ChatService(storageService);

  logger.success('Services 初期化完了', name: 'Main');

  // Repository層の初期化
  logger.start('Repositories 初期化中...', name: 'Main');
  final userRepository = UserRepository();
  final friendshipRepository = FriendshipRepository();
  final chatRoomRepository = ChatRoomRepository();
  final blockRepository = BlockRepository();

  logger.success('Repositories 初期化完了', name: 'Main');
  logger.info('  - UserRepository', name: 'Main');
  logger.info('  - FriendshipRepository', name: 'Main');
  logger.info('  - ChatRoomRepository', name: 'Main');
  logger.info('  - BlockRepository', name: 'Main');

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

        // Services
        Provider<StorageService>.value(value: storageService),
        Provider<AuthService>.value(value: authService),
        Provider<ChatService>.value(value: chatService),

        // Repositories
        Provider<UserRepository>.value(value: userRepository),
        Provider<FriendshipRepository>.value(value: friendshipRepository),
        Provider<ChatRoomRepository>.value(value: chatRoomRepository),
        Provider<BlockRepository>.value(value: blockRepository),
      ],
      child: MyApp(
        authService: authService,
        storageService: storageService,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final FirestoreStorageService storageService;

  const MyApp({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whispin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          primary: const Color(0xFF667EEA),
          secondary: const Color(0xFF764BA2),
        ),
      ),
      navigatorObservers: [
        NavigationLogger(),
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: authService.isLoggedIn() ? AppRoutes.home : AppRoutes.login,
    );
  }
}