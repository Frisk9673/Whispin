import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/account_create/account_create_screen.dart';

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

  print('🔗 エミュレーター設定開始...');

  // Authエミュレーター設定（確実な方法）
  try {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    print('✅ Authエミュレーター設定完了: localhost:9099');
  } catch (e) {
    print('❌ Authエミュレーター設定エラー: $e');
  }

  // Firestoreエミュレーター設定
  try {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
      sslEnabled: false,
    );
    print('✅ Firestoreエミュレーター設定完了: localhost:8080');
  } catch (e) {
    print('❌ Firestoreエミュレーター設定エラー: $e');
  }

  // 設定の確認
  print('🎯 Firebase設定完了、アプリ起動...');

  runApp(const MyApp());
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