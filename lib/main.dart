import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'services/firestore_storage_service.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'screens/account_create/account_create_screen.dart';
import 'screens/user/home_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/user_provider.dart';
import 'utils/navigation_logger.dart';
import 'utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ログシステムの初期化
  await logger.initialize();

  logger.section('🚀 Whispin アプリ起動中...', name: 'Main');

  // Firebase初期化
  logger.start('Firebase 初期化中...', name: 'Main');
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'dummy', 
      authDomain: 'dummy.firebaseapp.com',
      projectId: 'kazutxt-firebase-overvie-8d3e4',
      storageBucket: 'dummy.appspot.com',
      messagingSenderId: 'dummy',
      appId: 'dummy',
    ),
  );
  logger.success('Firebase 初期化完了', name: 'Main');

  // エミュレーター設定
  try {
    logger.start('Firebase エミュレーター接続中...', name: 'Main');
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
      sslEnabled: false,
    );
    logger.success('エミュレーター接続完了', name: 'Main');
    logger.info('  - Auth: localhost:9099', name: 'Main');
    logger.info('  - Firestore: localhost:8080', name: 'Main');
  } catch (e) {
    logger.error('エミュレーター設定エラー: $e', name: 'Main', error: e);
  }

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
  logger.section('✨ アプリ起動準備完了！', name: 'Main');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        Provider<FirestoreStorageService>.value(value: storageService),
        Provider<AuthService>.value(value: authService),
        Provider<ChatService>.value(value: chatService),
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
      home: authService.isLoggedIn()
          ? HomeScreen(
              authService: authService,
              storageService: storageService,
            )
          : const UserRegisterPage(),
    );
  }
}