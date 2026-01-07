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
  final confirmPasswordController = TextEditingController();
  final telIdController = TextEditingController();

  bool loading = false;
  String message = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final registerService = UserRegisterService();
  static const String _logName = 'UserRegisterPage';

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    nicknameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    telIdController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    logger.section('registerUser() 開始', name: _logName);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final telId = telIdController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || telId.isEmpty) {
      setState(() => message = "必須項目が未入力です");
      return;
    }

    if (password != confirmPassword) {
      setState(() => message = "パスワードが一致しません");
      return;
    }

    if (password.length < 6) {
      setState(() => message = "パスワードは6文字以上にしてください");
      return;
    }

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

    try {
      setState(() => loading = true);

      logger.start('registerService.register() 実行中...', name: _logName);
      await registerService.register(user, password);
      logger.success('ユーザー登録完了', name: _logName);

      if (!mounted) return;

      // 🔧 修正: emailパラメータを渡す
      logger.start('UserProvider.loadUserData() 実行中...', name: _logName);
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserData(email);

      if (userProvider.error != null) {
        logger.error('ユーザー情報読み込みエラー: ${userProvider.error}', name: _logName);
        setState(() {
          message = "ユーザー情報の読み込みに失敗しました";
          loading = false;
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

      logger.section('registerUser() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('登録エラー: $e', name: _logName, error: e, stackTrace: stack);
      setState(() => message = e.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
                      Icons.person_add_outlined,
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
                    '新規登録',
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
                          _buildTextField(
                            controller: emailController,
                            label: 'メールアドレス',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: telIdController,
                            label: '電話番号',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: lastNameController,
                                  label: '姓',
                                  icon: Icons.person_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: firstNameController,
                                  label: '名',
                                  icon: Icons.person_outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: nicknameController,
                            label: 'ニックネーム（オプション）',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: passwordController,
                            label: 'パスワード（6文字以上）',
                            icon: Icons.lock_outlined,
                            obscureText: _obscurePassword,
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
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: confirmPasswordController,
                            label: 'パスワード確認',
                            icon: Icons.lock_outlined,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
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
                                border: Border.all(color: Colors.red.shade200),
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

                          // 登録ボタン
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: loading ? null : registerUser,
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
                                  gradient: loading
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF667EEA),
                                            Color(0xFF764BA2),
                                          ],
                                        ),
                                  color: loading ? Colors.grey.shade300 : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: loading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          '登録',
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

                  // ログインリンク
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: loading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UserLoginPage(),
                                ),
                              );
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'すでにアカウントをお持ちの方はこちら',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      enabled: !loading,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}