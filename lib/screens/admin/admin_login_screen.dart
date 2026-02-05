import 'package:flutter/material.dart';
import '../../services/admin_auth_service.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/routes.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

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
  bool _obscurePassword = true;
  String message = "";
  static const String _logName = 'AdminLoginScreen';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginAdmin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => message = "メールアドレス または パスワードが未入力です");
      logger.warning('入力不足: email=$email, password=${password.isNotEmpty}',
          name: _logName);
      return;
    }

    try {
      setState(() => loading = true);
      logger.section('管理者ログイン処理開始: $email', name: _logName);

      final success = await adminAuth.login(email, password);

      if (!success) {
        logger.error('管理者ログイン失敗: $email', name: _logName);
        setState(() {
          message = "管理者アカウントではありません";
          loading = false;
        });
        return;
      }

      logger.success('管理者ログイン成功: $email', name: _logName);

      if (!mounted) return;

      // NavigationHelperを使用
      await NavigationHelper.toAdminHome(context);
    } catch (e, stack) {
      logger.error('ログインエラー: $e', name: _logName, error: e, stackTrace: stack);
      setState(() {
        message = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              : AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ロゴ
                  Container(
                    padding: EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 64,
                      color: AppColors.textWhite,
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
                    '管理者ログイン',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textWhite.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // フォームカード
                  Card(
                    elevation: AppConstants.cardElevation * 2,
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        children: [
                          // メールアドレス
                          TextField(
                            controller: emailController,
                            enabled: !loading,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: "メールアドレス",
                              labelStyle: TextStyle(
                                color: isDark ? Colors.grey[400] : null,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: isDark ? Colors.grey[400] : null,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF404040)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF404040)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.primary.lighten(0.2)
                                      : AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // パスワード
                          TextField(
                            controller: passwordController,
                            enabled: !loading,
                            obscureText: _obscurePassword,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: "パスワード",
                              labelStyle: TextStyle(
                                color: isDark ? Colors.grey[400] : null,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: isDark ? Colors.grey[400] : null,
                              ),
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
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF404040)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF404040)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.primary.lighten(0.2)
                                      : AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // エラーメッセージ
                          if (message.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.error
                                    .withOpacity(isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                                border: Border.all(
                                  color: AppColors.error
                                      .withOpacity(isDark ? 0.5 : 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: AppTextStyles.error.copyWith(
                                        color: isDark
                                            ? Colors.red[300]
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ログインボタン
                          SizedBox(
                            width: double.infinity,
                            height: AppConstants.buttonHeight,
                            child: ElevatedButton(
                              onPressed: loading ? null : loginAdmin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: loading
                                    ? (isDark
                                        ? const Color(0xFF2C2C2C)
                                        : AppColors.divider)
                                    : AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.defaultBorderRadius,
                                  ),
                                ),
                              ),
                              child: loading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: AppColors.textWhite,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "管理者ログイン",
                                      style: AppTextStyles.buttonLarge,
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
                    padding: EdgeInsets.all(AppConstants.defaultPadding - 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.05 : 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildLinkButton(
                          icon: Icons.login,
                          text: 'ユーザログインはこちら',
                          onTap: loading
                              ? null
                              : () => NavigationHelper.toLogin(context),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildLinkButton(
                          icon: Icons.person_add_outlined,
                          text: 'ユーザ新規登録はこちら',
                          onTap: loading
                              ? null
                              : () => NavigationHelper.toRegister(context),
                          isDark: isDark,
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
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isDark ? 0.05 : 0.1),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textWhite, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}