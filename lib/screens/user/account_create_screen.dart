import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whispin/services/storage_service.dart';
import '../../models/user.dart';
import '../../services/account_create_service.dart';
import '../../providers/user_provider.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/routes.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/string_extensions.dart';
import '../../utils/app_logger.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_storage_service.dart';

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

    // ✅ String拡張メソッド使用 - バリデーション
    if (email.isBlank ||
        password.isBlank ||
        confirmPassword.isBlank ||
        telId.isBlank) {
      context.showErrorSnackBar('必須項目が未入力です'); // ✅ context拡張メソッド
      return;
    }

    if (password != confirmPassword) {
      context.showErrorSnackBar('パスワードが一致しません'); // ✅ context拡張メソッド
      return;
    }

    if (password.length < AppConstants.passwordMinLength) {
      context.showErrorSnackBar(AppConstants.validationPasswordShort); // ✅ context拡張メソッド
      return;
    }

    // ✅ String拡張メソッド使用
    if (!email.isValidEmail) {
      context.showErrorSnackBar(AppConstants.validationEmailInvalid); // ✅ context拡張メソッド
      return;
    }

    setState(() => loading = true);

    try {
      // ユーザーオブジェクト作成
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

      logger.start('registerService.register() 実行中...', name: _logName);
      await registerService.register(user, password);
      logger.success('ユーザー登録完了', name: _logName);

      if (!mounted) return;

      // UserProviderにユーザー情報を読み込み
      logger.start('UserProvider.loadUserData() 実行中...', name: _logName);
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserData(email);

      if (userProvider.error != null) {
        logger.error('ユーザー情報読み込みエラー: ${userProvider.error}', name: _logName);

        if (!mounted) return;

        context.showErrorSnackBar('ユーザー情報の読み込みに失敗しました'); // ✅ context拡張メソッド
        setState(() => loading = false);
        return;
      }

      logger.success('UserProvider.loadUserData() 完了', name: _logName);

      if (!mounted) return;

      // ✅ context拡張メソッド使用
      context.showSuccessSnackBar('登録が完了しました！');

      final authService = context.read<AuthService>();
      final storageService = context.read<StorageService>();

      // ホーム画面へ遷移
      logger.start('HomeScreen へ遷移', name: _logName);

      await Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
        arguments: {
          'authService': authService,
          'storageService': storageService,
        },
      );

      logger.section('registerUser() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('登録エラー: $e', name: _logName, error: e, stackTrace: stack);

      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      context.showErrorSnackBar(errorMessage);
      setState(() => loading = false);
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
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ロゴ・タイトル
                  Container(
                    padding: EdgeInsets.all(AppConstants.defaultPadding),
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
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '新規登録',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textWhite.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // フォームカード
                  Card(
                    elevation: AppConstants.cardElevation * 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.defaultPadding),
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
                            label:
                                'パスワード（${AppConstants.passwordMinLength}文字以上）',
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
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 登録ボタン
                          SizedBox(
                            width: double.infinity,
                            height: AppConstants.buttonHeight,
                            child: ElevatedButton(
                              onPressed: loading ? null : registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.defaultBorderRadius,
                                  ),
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: loading
                                      ? null
                                      : AppColors.primaryGradient,
                                  color: loading ? AppColors.divider : null,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.defaultBorderRadius,
                                  ),
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
                                      : Text(
                                          '登録',
                                          style: AppTextStyles.buttonLarge,
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
                    padding: EdgeInsets.all(AppConstants.defaultPadding - 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: loading
                          ? null
                          : () => NavigationHelper.toLogin(context),
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'すでにアカウントをお持ちの方はこちら',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
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
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
      ),
      style: AppTextStyles.bodyLarge,
    );
  }
}