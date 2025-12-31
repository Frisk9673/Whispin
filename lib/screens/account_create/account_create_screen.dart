import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/account_create_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_storage_service.dart';
import '../../providers/user_provider.dart';
import '../../screens/user/home_screen.dart';
import '../login/user_login_page.dart';
import '../../utils/app_logger.dart';

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
  static const String _logName = 'UserRegisterPage';

  Future<void> registerUser() async {
    logger.section('registerUser() 開始', name: _logName);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final telId = telIdController.text.trim();

    logger.info('入力値: email=$email, password=${password.isNotEmpty ? "入力済" : "未入力"}, tel=$telId', name: _logName);

    if (email.isEmpty || password.isEmpty || telId.isEmpty) {
      setState(() => message = "必須項目が未入力です");
      logger.error('必須入力エラー: email or password or tel が空', name: _logName);
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

    logger.section('User 作成完了', name: _logName);
    logger.info('TEL_ID: ${user.phoneNumber}', name: _logName);
    logger.info('Email: ${user.id}', name: _logName);
    logger.info('Name: ${user.lastName} ${user.firstName}', name: _logName);
    logger.info('Nickname: ${user.nickname}', name: _logName);
    logger.info('Premium: ${user.premium}', name: _logName);
    logger.info('RoomCount: ${user.roomCount}', name: _logName);
    logger.info('CreateAt: ${user.createdAt}', name: _logName);

    try {
      setState(() => loading = true);

      logger.start('registerService.register() を実行します…', name: _logName);

      await registerService.register(user, password);

      logger.success('registerService.register() 成功！', name: _logName);

      if (!mounted) {
        logger.warning('画面非表示状態で終了', name: _logName);
        return;
      }

      // UserProviderでユーザー情報を読み込む
      logger.start('UserProviderでユーザー情報読み込み開始...', name: _logName);
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserData();

      if (userProvider.error != null) {
        logger.error('UserProvider読み込みエラー: ${userProvider.error}', name: _logName);
        setState(() {
          message = "ユーザー情報の読み込みに失敗しました";
          loading = false;
        });
        return;
      }

      logger.success('UserProvider読み込み完了', name: _logName);
      logger.info('  名前: ${userProvider.currentUser?.fullName}', name: _logName);
      logger.info('  ニックネーム: ${userProvider.currentUser?.displayName}', name: _logName);
      logger.info('  プレミアム: ${userProvider.currentUser?.premium}', name: _logName);

      logger.start('HomeScreen へ遷移します…', name: _logName);
      
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

      logger.section('registerUser() 正常終了', name: _logName);

    } catch (e, stack) {
      logger.error('registerUser() エラー発生: $e',
          name: _logName, error: e, stackTrace: stack);

      setState(() => message = e.toString());

      logger.section('registerUser() 異常終了', name: _logName);

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

            // ローディング表示付き登録ボタン
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