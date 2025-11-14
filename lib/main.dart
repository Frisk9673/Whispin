import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'profile.dart';

Future<void> main() async {
  runApp(const WhispinApp());
}

class WhispinApp extends StatelessWidget {
  const WhispinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ProfileScreen(),
    );
  }
}
