import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/account_create_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_storage_service.dart';
import '../../providers/user_provider.dart'; // ← 追加
import '../../screens/user/home_screen.dart';
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

    // User 作成
    final user = User(
      phoneNumber: telId,
      id: email,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      nickname: nicknameController.text.trim(),
      rate: 0.0,
      premium: false,
      roomCount: 0,
      createdAt: DateTime.now(),
      lastUpdatedPremium: null,
      deletedAt: null,
    );

    developer.log("=== User 作成完了 ===");
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

      if (!mounted) {
        developer.log("⚠️ 画面非表示状態で終了");
        return;
      }

      // ✅ UserProviderでユーザー情報を読み込む
      developer.log("▶ UserProviderでユーザー情報読み込み開始...");
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserData();

      if (userProvider.error != null) {
        developer.log("❌ UserProvider読み込みエラー: ${userProvider.error}");
        setState(() {
          message = "ユーザー情報の読み込みに失敗しました";
          loading = false;
        });
        return;
      }

      developer.log("✅ UserProvider読み込み完了");
      developer.log("  名前: ${userProvider.currentUser?.fullName}");
      developer.log("  ニックネーム: ${userProvider.currentUser?.displayName}");
      developer.log("  プレミアム: ${userProvider.currentUser?.premium}");

      developer.log("▶ HomeScreen へ遷移します…");
      
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

      developer.log("=== registerUser() 正常終了 ===\n");

    } catch (e, stack) {
      developer.log("❌ registerUser() エラー発生: $e",
          error: e, stackTrace: stack);

      setState(() => message = e.toString());

      developer.log("=== registerUser() 異常終了 ===\n");

    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
              enabled: !loading,
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: '姓'),
              enabled: !loading,
            ),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: '名'),
              enabled: !loading,
            ),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: 'ニックネーム'),
              enabled: !loading,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
              enabled: !loading,
            ),
            TextField(
              controller: telIdController,
              decoration: const InputDecoration(labelText: '電話番号（TEL_ID）'),
              keyboardType: TextInputType.phone,
              enabled: !loading,
            ),
            const SizedBox(height: 16),

            // ✅ ローディング表示付き登録ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : registerUser,
                child: loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('登録中...'),
                        ],
                      )
                    : const Text("登録"),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),

            const SizedBox(height: 24),

            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UserLoginPage()),
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