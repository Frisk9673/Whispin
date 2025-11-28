// screens/account_create_screen.dart 
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/account_create_service.dart';
import '../../screens/user/home.dart';
import '../login/user_login_page.dart';

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({super.key});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final nicknameController = TextEditingController();
  final passwordController = TextEditingController();
  final telIdController = TextEditingController();

  bool loading = false;
  String message = '';

  final registerService = UserRegisterService();

  Future<void> registerUser() async {
    developer.log("=== registerUser() 開始 ===");

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final telId = telIdController.text.trim();

    developer.log("入力値: email=$email, password=${password.isNotEmpty}, tel=$telId");

    if (email.isEmpty || password.isEmpty || telId.isEmpty) {
      setState(() => message = "必須項目が未入力です");
      developer.log("❌ 必須入力エラー: email or password or tel が空");
      return;
    }

    // UserModel 作成
    final user = UserModel(
      phoneNumber: telId, // telId → phoneNumber に変更
      id: email,          // email → id に変更
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      nickname: nicknameController.text.trim(),
      rate: 0.0,          // double に合わせる
      premium: false,
      roomCount: 0,
      createdAt: DateTime.now(),
      lastUpdatedPremium: null,
      deletedAt: null,
    );


    developer.log("=== UserModel 作成完了 ===");
    developer.log("TEL_ID: ${user.phoneNumber}");
    developer.log("Email: ${user.id}");
    developer.log("Name: ${user.lastName} ${user.firstName}");
    developer.log("Nickname: ${user.nickname}");
    developer.log("Premium: ${user.premium}");
    developer.log("RoomCount: ${user.roomCount}");
    developer.log("CreateAt: ${user.createdAt}");
    developer.log("=================================");

    try {
      setState(() => loading = true);

      developer.log("registerService.register() を実行します…");

      await registerService.register(user, password);

      developer.log("🎉 registerService.register() 成功！");
      developer.log("RoomJoinScreen へ遷移します…");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoomJoinScreen()),
      );

      developer.log("=== registerUser() 正常終了 ===\n");

    } catch (e, stack) {
      developer.log("❌ registerUser() エラー発生: $e",
          error: e, stackTrace: stack);

      setState(() => message = e.toString());

      developer.log("=== registerUser() 異常終了 ===\n");

    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ユーザー登録")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: '姓'),
            ),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: '名'),
            ),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: 'ニックネーム'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            TextField(
              controller: telIdController,
              decoration: const InputDecoration(labelText: '電話番号（TEL_ID）'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: loading ? null : registerUser,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("登録"),
            ),

            const SizedBox(height: 16),

            Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),

            const SizedBox(height: 24),

            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserLoginPage()),
                );
              },
              child: const Text(
                "すでにアカウントをお持ちの方はこちら（ログイン）",
                style: TextStyle(fontSize: 14),
              ),
            )
          ],
        ),
      ),
    );
  }
}
