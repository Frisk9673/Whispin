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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // エミュレーター設定
  try {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
      sslEnabled: false,
    );
    print('🔧 Connected to Firebase Emulators');
  } catch (e) {
    print('❌ エミュレーター設定エラー: $e');
  }

  // Services層の初期化
  print('📦 Initializing Services...');
  final storageService = FirestoreStorageService();
  await storageService.initialize();
  await storageService.load();
  storageService.startListening();

  final authService = AuthService(storageService);
  await authService.initialize();

  final chatService = ChatService(storageService);

  print('✅ Services initialized successfully');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // Services を Provider で提供
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
      home: authService.isLoggedIn()
          ? HomeScreen(
              authService: authService,
              storageService: storageService,
            )
          : const UserRegisterPage(),
    );
  }
}