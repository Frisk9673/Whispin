// screens/admin/admin_login_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_auth_service.dart';
import '../login/user_login_page.dart';
import '../account_create/account_create_screen.dart'; // ユーザ新規登録画面

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final adminAuth = AdminLoginService();

  bool loading = false;
  String message = "";

  Future<void> loginAdmin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => message = "メールアドレス または パスワードが未入力です");
      debugPrint("⚠️ 入力不足: email=$email, password=${password.isNotEmpty}");
      return;
    }

    try {
      setState(() => loading = true);
      debugPrint("🔐 [AdminLogin] ログイン処理開始: $email");

      await adminAuth.loginAdmin(email, password, context);

      debugPrint("✅ [AdminLogin] 管理者ログイン成功: $email");

    } catch (e) {
      setState(() => message = e.toString());
      debugPrint("❌ [AdminLogin] ログインエラー: $e");
    } finally {
      setState(() => loading = false);
      debugPrint("⏹ [AdminLogin] ログイン処理終了: $email");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("管理者ログイン")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "メールアドレス"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "パスワード"),
              obscureText: true,
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: loading ? null : loginAdmin,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("管理者ログイン"),
            ),

            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 40),

            /// ユーザログイン
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserLoginPage()),
                );
              },
              child: const Text("ユーザログインはこちら"),
            ),

            const SizedBox(height: 8),

            /// ユーザ新規登録
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserRegisterPage()),
                );
              },
              child: const Text("ユーザ新規登録はこちら"),
            ),
          ],
        ),
      ),
    );
  }
}
