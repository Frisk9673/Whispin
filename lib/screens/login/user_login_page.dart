import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/user_auth_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_storage_service.dart';
import '../../providers/user_provider.dart';
import '../../screens/user/home_screen.dart';
import '../account_create/account_create_screen.dart';
import '../admin/admin_login_screen.dart';
import '../../utils/app_logger.dart';

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
  bool _isLoading = false;
  bool _obscurePassword = true;
  static const String _logName = 'UserLoginPage';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    logger.section('_login() 開始', name: _logName);
    
    setState(() {
      _isLoading = true;
      message = '';
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      logger.info('ログイン試行: $email', name: _logName);

      final loginResult = await userAuthService.loginUser(
        email: email,
        password: password,
      );

      logger.success('Auth ログイン成功', name: _logName);

      if (!mounted) return;

      // 論理削除チェック
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final query = await FirebaseFirestore.instance
            .collection('User')
            .where('EmailAddress', isEqualTo: user.email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final userData = query.docs.first.data();
          final isDeleted = userData['IsDeleted'] ?? false;

          if (isDeleted) {
            logger.warning('削除済みアカウント: $email', name: _logName);
            await FirebaseAuth.instance.signOut();
            setState(() {
              message = "このアカウントは削除済みです";
              _isLoading = false;
            });
            return;
          }
        }
      }

      // 🔧 修正: emailパラメータを渡す
      logger.start('UserProvider.loadUserData() 実行中...', name: _logName);
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserData(email);

      if (userProvider.error != null) {
        logger.error('ユーザー情報読み込みエラー: ${userProvider.error}', name: _logName);
        setState(() {
          message = "ユーザー情報の読み込みに失敗しました";
          _isLoading = false;
        });
        return;
      }

      logger.success('UserProvider.loadUserData() 完了', name: _logName);

      final authService = context.read<AuthService>();
      final storageService = context.read<FirestoreStorageService>();

      logger.start('HomeScreen へ遷移', name: _logName);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            authService: authService,
            storageService: storageService,
          ),
        ),
      );

      logger.section('_login() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('ログインエラー: $e', name: _logName, error: e, stackTrace: stack);
      setState(() {
        message = "ログインに失敗しました";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ロゴ・タイトル
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Whispin',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ログイン',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // フォームカード
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // メールアドレス
                          TextField(
                            controller: emailController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'メールアドレス',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // パスワード
                          TextField(
                            controller: passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'パスワード',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // エラーメッセージ
                          if (message.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: TextStyle(color: Colors.red.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ログインボタン
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: _isLoading
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF667EEA),
                                            Color(0xFF764BA2),
                                          ],
                                        ),
                                  color: _isLoading ? Colors.grey.shade300 : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'ログイン',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // リンクボタン群
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildLinkButton(
                          icon: Icons.person_add_outlined,
                          text: '新規登録はこちら',
                          onTap: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UserRegisterPage(),
                                    ),
                                  );
                                },
                        ),
                        const SizedBox(height: 12),
                        _buildLinkButton(
                          icon: Icons.admin_panel_settings_outlined,
                          text: '管理者ログインはこちら',
                          onTap: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminLoginScreen(),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}