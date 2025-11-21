import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home.dart';
import 'account_create.dart';
import 'admin/login/admin_login.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String message = '';

  Future<void> loginUser() async {
    // ログ追加
    print('🔐 ログイン処理開始');
    print('📧 入力メール: ${emailController.text.trim()}');
    
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ログ追加
      print('✅ ログイン成功');
      print('👤 ユーザーID: ${userCredential.user?.uid}');
      print('📧 ユーザーメール: ${userCredential.user?.email}');

      // ログイン成功 → Home へ遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoomJoinScreen()),
      );
    } catch (e) {
      // ログ追加
      print('❌ ログインエラー: $e');
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
              onPressed: loginUser,
              child: const Text('ログイン'),
            ),

            const SizedBox(height: 20),
            Text(message, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // ログ追加
                print('🔄 新規登録画面へ遷移');
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
                  MaterialPageRoute(builder: (_) => const AdmLoginApp()),
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