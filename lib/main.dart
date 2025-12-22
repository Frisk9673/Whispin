import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'screens/account_create/account_create_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/admin_provider.dart';
import 'services/firestore_storage_service.dart';
import 'services/invitation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 [main] アプリケーション起動開始');

  // Firebase初期化
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
  print('✅ [main] Firebase初期化完了');

  // エミュレーター設定
  try {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
      sslEnabled: false,
    );
    print('✅ [main] Firebaseエミュレーター接続完了');
  } catch (e) {
    print('❌ [main] エミュレーター設定エラー: $e');
  }

  // ===== StorageService の初期化 =====
  print('📦 [main] StorageService初期化開始');
  final storageService = FirestoreStorageService();
  await storageService.initialize();
  await storageService.load();
  storageService.startListening();
  print('✅ [main] StorageService初期化完了');

  // ===== InvitationService の初期化 =====
  print('📨 [main] InvitationService初期化開始');
  final invitationService = InvitationService(storageService);
  
  // 期限切れ招待のクリーンアップを実行
  await invitationService.cleanupExpiredInvitations();
  print('✅ [main] InvitationService初期化完了');

  // アプリ起動
  runApp(
    MultiProvider(
      providers: [
        // ChatProvider
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
        
        // AdminProvider
        ChangeNotifierProvider(
          create: (_) => AdminProvider(),
        ),
        
        // StorageService (Provider経由で提供)
        Provider<FirestoreStorageService>.value(
          value: storageService,
        ),
        
        // InvitationService (Provider経由で提供)
        Provider<InvitationService>.value(
          value: invitationService,
        ),
      ],
      child: const MyApp(),
    ),
  );

  print('✅ [main] アプリケーション起動完了');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const UserRegisterPage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          primary: const Color(0xFF667EEA),
          secondary: const Color(0xFF764BA2),
        ),
      ),
    );
  }
}