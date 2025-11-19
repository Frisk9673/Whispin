import 'package:flutter/material.dart';
import 'admin_login_page.dart';

void main() {
  runApp(const AdmLoginApp());
}

class AdmLoginApp extends StatelessWidget {
  const AdmLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whispin 管理者ログイン',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AdminLoginPage(),
    );
  }
}
