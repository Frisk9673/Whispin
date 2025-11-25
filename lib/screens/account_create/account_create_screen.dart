// screens/user_register_screen.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
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
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final telId = telIdController.text.trim();

    if (email.isEmpty || password.isEmpty || telId.isEmpty) {
      setState(() => message = "必須項目が未入力です");
      return;
    }

    final user = UserModel(
      telId: telId,
      email: email,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      nickname: nicknameController.text.trim(),
      rate: 0,
      premium: false,
      roomCount: 3,
      createdAt: DateTime.now(),
      lastUpdatedPremium: null,
      deletedAt: null,
    );

    try {
      setState(() => loading = true);

      await registerService.register(user, password);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoomJoinScreen()),
      );
    } catch (e) {
      setState(() => message = e.toString());
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
