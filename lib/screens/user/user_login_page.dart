import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/user_auth_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_storage_service.dart';
import '../../providers/user_provider.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/string_extensions.dart';
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
      
      // NavigationHelper使用
      await NavigationHelper.toHome(
        context,
        authService: authService,
        storageService: storageService,
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
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
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
                      Icons.lock_outline,
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
                    'ログイン',
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
                          // メールアドレス
                          TextField(
                            controller: emailController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'メールアドレス',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: AppTextStyles.bodyLarge,
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
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                              ),
                            ),
                            style: AppTextStyles.bodyLarge,
                          ),
                          const SizedBox(height: 24),

                          // エラーメッセージ
                          if (message.isNotBlank) // ✅ String拡張メソッド
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                                border: Border.all(
                                  color: AppColors.error.withOpacity(0.3),
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
                                      style: AppTextStyles.error,
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
                              onPressed: _isLoading ? null : _login,
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
                                  gradient: _isLoading
                                      ? null
                                      : AppColors.primaryGradient,
                                  color: _isLoading 
                                      ? AppColors.divider 
                                      : null,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.defaultBorderRadius,
                                  ),
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
                                      : Text(
                                          'ログイン',
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

                  // リンクボタン群
                  Container(
                    padding: EdgeInsets.all(AppConstants.defaultPadding - 4),
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
                              : () => NavigationHelper.toRegister(context),
                        ),
                        const SizedBox(height: 12),
                        _buildLinkButton(
                          icon: Icons.admin_panel_settings_outlined,
                          text: '管理者ログインはこちら',
                          onTap: _isLoading
                              ? null
                              : () => NavigationHelper.toAdminLogin(context),
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
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
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