import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:whispin/services/storage_service.dart';
import '../../services/user_auth_service.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../providers/user_provider.dart';
import '../../repositories/user_repository.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/responsive.dart';
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

      // バリデーション
      if (email.isBlank || password.isBlank) {
        context.showWarningSnackBar("メールアドレスとパスワードを入力してください");
        setState(() {
          message = "メールアドレスとパスワードを入力してください";
          _isLoading = false;
        });
        return;
      }

      if (!email.isValidEmail) {
        context.showErrorSnackBar(AppConstants.validationEmailInvalid);
        setState(() {
          message = AppConstants.validationEmailInvalid;
          _isLoading = false;
        });
        return;
      }

      if (password.length < AppConstants.passwordMinLength) {
        context.showWarningSnackBar(AppConstants.validationPasswordShort);
        setState(() {
          message = AppConstants.validationPasswordShort;
          _isLoading = false;
        });
        return;
      }

      logger.info('ログイン試行: $email', name: _logName);

      final loginResult = await userAuthService.loginUser(
        email: email,
        password: password,
      );

      if (loginResult == null) {
        logger.warning('Auth ログイン結果が null のため中断', name: _logName);

        if (!mounted) return;

        context.showErrorSnackBar('ログインに失敗しました');
        setState(() {
          message = "ログインに失敗しました";
          _isLoading = false;
        });
        return;
      }

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
            
            if (!mounted) return;
            
            context.showErrorSnackBar("このアカウントは削除済みです");
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
        
        if (!mounted) return;
        
        context.showErrorSnackBar('ユーザー情報の読み込みに失敗しました');
        setState(() {
          message = userProvider.error!;
          _isLoading = false;
        });
        return;
      }

      logger.success('UserProvider.loadUserData() 完了', name: _logName);

      // FCMトークンを取得して保存
      try {
        logger.section('FCMトークン保存処理開始', name: _logName);
        
        final fcmService = context.read<FCMService>();
        final fcmToken = fcmService.fcmToken;
        
        if (fcmToken != null && fcmToken.isNotEmpty) {
          logger.info('FCMトークン取得成功', name: _logName);
          logger.debug('Token: ${fcmToken.substring(0, 20)}...', name: _logName);
          
          final userRepository = context.read<UserRepository>();
          await userRepository.updateFCMToken(email, fcmToken);
          
          logger.success('FCMトークン保存完了', name: _logName);
        } else {
          logger.warning('FCMトークンが取得できませんでした', name: _logName);
        }
        
        logger.section('FCMトークン保存処理完了', name: _logName);
      } catch (e, stack) {
        // FCMトークン保存失敗はログインを妨げない
        logger.error('FCMトークン保存エラー（無視）: $e', 
            name: _logName, error: e, stackTrace: stack);
      }

      final authService = context.read<AuthService>();
      final storageService = context.read<StorageService>();

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
      
      if (!mounted) return;
      
      context.showErrorSnackBar('ログインに失敗しました');
      setState(() {
        message = "ログインに失敗しました";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final padding = context.responsivePadding;
    final isDark = context.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.darkSurface,
                  AppColors.darkBackground,
                ],
              )
            : AppColors.primaryGradient,
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

                  // リンクボタン群
                  _buildLinks(context, isMobile, isDark),
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
            Icons.lock_outline,
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
          'ログイン',
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
        color: context.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : AppConstants.defaultPadding),
          child: Column(
            children: [
              // メールアドレス
              TextField(
                controller: emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: context.responsiveFontSize(16),
                  color: context.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'メールアドレス',
                  labelStyle: TextStyle(
                    fontSize: context.responsiveFontSize(14),
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: isMobile ? 20 : 24,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),

              // パスワード
              TextField(
                controller: passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: context.responsiveFontSize(16),
                  color: context.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  labelStyle: TextStyle(
                    fontSize: context.responsiveFontSize(14),
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outlined,
                    size: isMobile ? 20 : 24,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: isMobile ? 20 : 24,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // エラーメッセージ
              if (message.isNotBlank)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                    border: Border.all(
                      color: AppColors.error.withOpacity(isDark ? 0.5 : 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: isMobile ? 18 : 20,
                          ),
                          SizedBox(width: isMobile ? 6 : 8),
                          Text(
                            'エラー',
                            style: AppTextStyles.error.copyWith(
                              fontSize: context.responsiveFontSize(14),
                              color: isDark ? Colors.red[300] : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      Text(
                        message,
                        style: AppTextStyles.error.copyWith(
                          fontSize: context.responsiveFontSize(13),
                          color: isDark ? Colors.red[300] : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),

              // ログインボタン
              SizedBox(
                width: double.infinity,
                height: isMobile ? 48 : AppConstants.buttonHeight,
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
                        ? (isDark ? AppColors.darkInput : AppColors.divider)
                        : null,
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isLoading
                          ? SizedBox(
                              width: isMobile ? 20 : 24,
                              height: isMobile ? 20 : 24,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'ログイン',
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

  /// リンクボタン群を構築
  Widget _buildLinks(BuildContext context, bool isMobile, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.maxFormWidth,
      ),
      padding: EdgeInsets.all(isMobile ? 12 : AppConstants.defaultPadding - 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDark ? 0.05 : 0.1),
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
            isMobile: isMobile,
            isDark: isDark,
          ),
          SizedBox(height: isMobile ? 10 : 12),
          _buildLinkButton(
            icon: Icons.admin_panel_settings_outlined,
            text: '管理者ログインはこちら',
            onTap: _isLoading
                ? null
                : () => NavigationHelper.toAdminLogin(context),
            isMobile: isMobile,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// リンクボタンを構築
  Widget _buildLinkButton({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
    required bool isMobile,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 10 : 12,
          horizontal: isMobile ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isDark ? 0.05 : 0.1),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textWhite, size: isMobile ? 18 : 20),
            SizedBox(width: isMobile ? 6 : 8),
            Flexible(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w500,
                  fontSize: context.responsiveFontSize(14),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
