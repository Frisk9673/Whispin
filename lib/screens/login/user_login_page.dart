import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/user_auth_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_storage_service.dart';
import '../../screens/user/home_screen.dart';
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
  final userAuthService = UserAuthService();

  String message = '';

  Future<void> _login() async {
    print("===== [UserLoginPage] _login() 開始 =====");
    print("入力されたメール: ${emailController.text}");
    
    try {
      print("▶ FirebaseAuth でログイン処理中...");

      final loginResult = await userAuthService.loginUser(
        email: emailController.text,
        password: passwordController.text,
      );

      print("✔ Auth ログイン成功: $loginResult");

      if (!mounted) {
        print("⚠️ 画面非表示状態で終了");
        return;
      }

      // 論理削除チェック
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print("▶ Firestore からユーザ情報取得中: ${user.email}");
        final query = await FirebaseFirestore.instance
            .collection('User')
            .where('EmailAddress', isEqualTo: user.email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final userData = query.docs.first.data();
          final isDeleted = userData['IsDeleted'] ?? false;
          print("取得したユーザ情報: $userData");

          if (isDeleted) {
            print("❌ 論理削除済みアカウントです");
            await FirebaseAuth.instance.signOut();
            setState(() => message = "このアカウントは削除済みです");
            print("⚠️ ログイン中断: 論理削除アカウント");
            return;
          }
        } else {
          print("⚠️ ユーザ情報がFirestoreに存在しません");
        }
      }

      print("▶ 正常ログイン → HomeScreen へ遷移");
      
      // Services を Provider から取得
      final authService = context.read<AuthService>();
      final storageService = context.read<FirestoreStorageService>();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            authService: authService,
            storageService: storageService,
          ),
        ),
      );

      print("===== [UserLoginPage] _login() 正常終了 =====");

    } catch (e) {
      print("❌ ログイン処理で例外発生: $e");
      setState(() => message = "ログインエラー: $e");
      print("===== _login() 異常終了 =====");
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