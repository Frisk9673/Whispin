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
import '../../constants/responsive.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/string_extensions.dart';
import '../../utils/app_logger.dart';
import '../../services/auth_service.dart';

/// レスポンシブ対応のユーザー登録画面
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

    if (email.isBlank ||
        password.isBlank ||
        confirmPassword.isBlank ||
        telId.isBlank) {
      context.showErrorSnackBar('必須項目が未入力です');
      return;
    }

    if (password != confirmPassword) {
      context.showErrorSnackBar('パスワードが一致しません');
      return;
    }

    if (password.length < AppConstants.passwordMinLength) {
      context.showErrorSnackBar(AppConstants.validationPasswordShort);
      return;
    }

    if (!email.isValidEmail) {
      context.showErrorSnackBar(AppConstants.validationEmailInvalid);
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(telId)) {
      context.showErrorSnackBar('電話番号は半角数字で入力してください');
      return;
    }

    setState(() => loading = true);

    try {
      final storageService = context.read<StorageService>();

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

      await registerService.register(
        user: user,
        password: password,
        storageService: storageService,
      );

      logger.success('ユーザー登録完了', name: _logName);

      if (!mounted) return;

      logger.start('UserProvider.loadUserData() 実行中...', name: _logName);
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserData(email);

      if (userProvider.error != null) {
        logger.error('ユーザー情報読み込みエラー: ${userProvider.error}', name: _logName);

        if (!mounted) return;

        context.showErrorSnackBar('ユーザー情報の読み込みに失敗しました');
        setState(() => loading = false);
        return;
      }

      logger.success('UserProvider.loadUserData() 完了', name: _logName);

      if (!mounted) return;

      context.showSuccessSnackBar('登録が完了しました！');

      final authService = context.read<AuthService>();

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
    final isMobile = context.isMobile;
    final padding = context.responsivePadding;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E1E),
                  Color(0xFF121212),
                ],
              )
            : const LinearGradient(
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
              padding: padding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ロゴ・タイトル
                  _buildHeader(context, isMobile, isDark),
                  SizedBox(height: isMobile ? 32 : 48),

                  // フォームカード
                  _buildFormCard(context, isMobile, isDark),
                  SizedBox(height: isMobile ? 16 : 24),

                  // ログインリンク
                  _buildLoginLink(context, isMobile, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ヘッダーを構築
  Widget _buildHeader(BuildContext context, bool isMobile, bool isDark) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 20 : AppConstants.defaultPadding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
          ),
          child: Icon(
            Icons.person_add_outlined,
            size: isMobile ? 48 : 64,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Text(
          AppConstants.appName,
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.textWhite,
            fontSize: context.responsiveFontSize(32),
          ),
        ),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          '新規登録',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textWhite.withOpacity(0.9),
            fontSize: context.responsiveFontSize(18),
          ),
        ),
      ],
    );
  }

  /// フォームカードを構築
  Widget _buildFormCard(BuildContext context, bool isMobile, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.maxFormWidth,
      ),
      child: Card(
        elevation: AppConstants.cardElevation * 2,
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : AppConstants.defaultPadding),
          child: Column(
            children: [
              _buildTextField(
                controller: emailController,
                label: 'メールアドレス',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isMobile: isMobile,
                isDark: isDark,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              _buildTextField(
                controller: telIdController,
                label: '電話番号',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isMobile: isMobile,
                isDark: isDark,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: lastNameController,
                      label: '姓',
                      icon: Icons.person_outline,
                      isMobile: isMobile,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: _buildTextField(
                      controller: firstNameController,
                      label: '名',
                      icon: Icons.person_outline,
                      isMobile: isMobile,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              _buildTextField(
                controller: nicknameController,
                label: 'ニックネーム（オプション）',
                icon: Icons.badge_outlined,
                isMobile: isMobile,
                isDark: isDark,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              _buildTextField(
                controller: passwordController,
                label: 'パスワード（${AppConstants.passwordMinLength}文字以上）',
                icon: Icons.lock_outlined,
                obscureText: _obscurePassword,
                isMobile: isMobile,
                isDark: isDark,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark ? Colors.grey[400] : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              _buildTextField(
                controller: confirmPasswordController,
                label: 'パスワード確認',
                icon: Icons.lock_outlined,
                obscureText: _obscureConfirmPassword,
                isMobile: isMobile,
                isDark: isDark,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark ? Colors.grey[400] : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // 登録ボタン
              SizedBox(
                width: double.infinity,
                height: isMobile ? 48 : AppConstants.buttonHeight,
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
                      gradient: loading ? null : AppColors.primaryGradient,
                      color: loading 
                        ? (isDark ? const Color(0xFF2C2C2C) : AppColors.divider)
                        : null,
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: loading
                          ? SizedBox(
                              width: isMobile ? 20 : 24,
                              height: isMobile ? 20 : 24,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              '登録',
                              style: AppTextStyles.buttonLarge.copyWith(
                                fontSize: context.responsiveFontSize(18),
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
    );
  }

  /// テキストフィールドを構築
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isMobile,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      enabled: !loading,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLarge.copyWith(
        fontSize: context.responsiveFontSize(16),
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: context.responsiveFontSize(14),
          color: isDark ? Colors.grey[400] : null,
        ),
        prefixIcon: Icon(
          icon,
          size: isMobile ? 20 : 24,
          color: isDark ? Colors.grey[400] : null,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(
            color: isDark 
              ? AppColors.primary.lighten(0.2)
              : AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 12 : 16,
        ),
      ),
    );
  }

  /// ログインリンクを構築
  Widget _buildLoginLink(BuildContext context, bool isMobile, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.maxFormWidth,
      ),
      padding: EdgeInsets.all(isMobile ? 12 : AppConstants.defaultPadding - 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDark ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: loading ? null : () => NavigationHelper.toLogin(context),
        borderRadius: BorderRadius.circular(
          AppConstants.defaultBorderRadius,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 10 : 12,
            horizontal: isMobile ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.05 : 0.1),
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, color: Colors.white, size: isMobile ? 18 : 20),
              SizedBox(width: isMobile ? 6 : 8),
              Flexible(
                child: Text(
                  'すでにアカウントをお持ちの方はこちら',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: context.responsiveFontSize(14),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}