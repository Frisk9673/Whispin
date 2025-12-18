import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/admin_provider.dart';
import 'screens/account_create/account_create_screen.dart';
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
  } catch (e) {
    print('❌ エミュレーター設定エラー: $e');
  }

  runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider(create: (_) => AdminProvider()),
    ],
    child: const MyApp(),
  ),
);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const UserRegisterPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
