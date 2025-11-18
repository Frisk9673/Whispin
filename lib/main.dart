import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_create.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FirebaseOptions はプロジェクト固有の値を使う
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'dummy', // Web用にダミーでもOK
      authDomain: 'dummy.firebaseapp.com',
      projectId: 'kazutxt-firebase-overvie-8d3e4',
      storageBucket: 'dummy.appspot.com',
      messagingSenderId: 'dummy',
      appId: 'dummy',
    ),
  );

  // Firestore Emulator に接続
  final db = FirebaseFirestore.instance;
  db.useFirestoreEmulator('localhost', 8080);

  // Flutter Web での CORS 回避用設定
  db.settings = const Settings(
    persistenceEnabled: false,
    sslEnabled: false,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: UserRegisterPage(),
    );
  }
}
