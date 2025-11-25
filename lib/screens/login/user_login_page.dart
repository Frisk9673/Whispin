// lib/screens/login/user_login_page.dart
import 'package:flutter/material.dart';

import '../../services/user_auth_service.dart';
import '../../screens/user/home.dart';
import '../account_create/account_create_screen.dart';
import '../admin/admin_login_screen.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = UserAuthService();

  String message = '';

  Future<void> _login() async {
    try {
      await authService.loginUser(
        email: emailController.text,
        password: passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoomJoinScreen()),
      );

    } catch (e) {
      setState(() => message = "ログインエラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _login,
              child: const Text('ログイン'),
            ),

            const SizedBox(height: 20),
            Text(message, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserRegisterPage()),
                );
              },
              child: const Text("新規登録はこちら"),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              },
              child: const Text(
                '管理者ログインはこちら',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
