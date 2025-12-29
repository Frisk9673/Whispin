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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('\n╔═════════════════════════════════════════════════╗');
  print('║          🚀 Whispin アプリ起動中...          ║');
  print('╚═════════════════════════════════════════════════╝\n');

  // Firebase初期化
  print('📦 Firebase 初期化中...');
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
  print('✅ Firebase 初期化完了\n');

  // エミュレーター設定
  try {
    print('🔧 Firebase エミュレーター接続中...');
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
      sslEnabled: false,
    );
    print('✅ エミュレーター接続完了');
    print('   - Auth: localhost:9099');
    print('   - Firestore: localhost:8080\n');
  } catch (e) {
    print('❌ エミュレーター設定エラー: $e\n');
  }

  // Services層の初期化
  print('📦 Services 初期化中...');
  final storageService = FirestoreStorageService();
  await storageService.initialize();
  await storageService.load();
  storageService.startListening();

  final authService = AuthService(storageService);
  await authService.initialize();

  final chatService = ChatService(storageService);

  print('✅ Services 初期化完了\n');

  print('╔═════════════════════════════════════════════════╗');
  print('║          ✨ アプリ起動準備完了！             ║');
  print('╚═════════════════════════════════════════════════╝\n');

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
      // ✅ NavigatorObserversにNavigationLoggerを追加
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