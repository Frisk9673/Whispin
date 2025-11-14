import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    // Android emulator
    const host = '10.0.2.2';
    FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
    debugPrint('✅ Whispin: Using Firebase Emulator (DB:9000, Auth:9099)');
  }

  runApp(const WhispinApp());
}

class WhispinApp extends StatelessWidget {
  const WhispinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Whispin')),
      ),
    );
  }
}
