import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/string_extensions.dart';
import '../../utils/app_logger.dart';

class AuthScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const AuthScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  static const String _logName = 'AuthScreen';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // ===== バリデーション =====

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return AppConstants.validationRequired;
    }
    // 🔧 String拡張メソッド使用
    if (!email.isValidEmail) {
      return AppConstants.validationEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return AppConstants.validationRequired;
    }
    if (password.length < AppConstants.passwordMinLength) {
      return AppConstants.validationPasswordShort;
    }
    if (password.length > AppConstants.passwordMaxLength) {
      return AppConstants.validationMaxLength;
    }
    return null;
  }

  // ===== 認証処理 =====

  Future<void> _handleSubmit() async {
    logger.section('_handleSubmit() 開始', name: _logName);
    logger.info('モード: ${_isLogin ? "ログイン" : "サインアップ"}', name: _logName);

    // バリデーション
    final emailError = _validateEmail(_emailController.text.trim());
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }

    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }

    if (!_isLogin) {
      // サインアップ時の追加バリデーション
      if (_firstNameController.text.trim().isEmpty) {
        setState(() => _errorMessage = '名を入力してください');
        return;
      }
      if (_lastNameController.text.trim().isEmpty) {
        setState(() => _errorMessage = '姓を入力してください');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success = false;

      if (_isLogin) {
        logger.start('ログイン処理開始', name: _logName);
        final user = await widget.authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        success = user != null;
        
        if (success) {
          logger.success('ログイン成功', name: _logName);
        }
      } else {
        logger.start('サインアップ処理開始', name: _logName);
        final newUser = await widget.authService.signup(
          _emailController.text.trim(),
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
          _nicknameController.text.trim(),
          _passwordController.text,
          _passwordController.text,
        );
        success = newUser != null;
        
        if (success) {
          logger.success('サインアップ成功', name: _logName);
        }
      }

      if (success && mounted) {
        // 🔧 NavigationHelper使用
        await NavigationHelper.toHome(
          context,
          authService: widget.authService,
          storageService: widget.storageService,
        );
      } else {
        setState(() {
          _errorMessage = _isLogin
              ? 'メールアドレスまたはパスワードが正しくありません'
              : 'サインアップに失敗しました';
          _isLoading = false;
        });
      }

      logger.section('_handleSubmit() 完了', name: _logName);

    } catch (e, stack) {
      logger.error('認証エラー: $e', name: _logName, error: e, stackTrace: stack);
      
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
        _isLoading = false;
      });
    }
  }

  // ===== モード切り替え =====

  void _toggleMode() {
    logger.info('モード切り替え: ${!_isLogin ? "ログイン" : "サインアップ"}', name: _logName);
    
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    // 🔧 拡張メソッド使用
    final isMobile = context.isMobile;
    final screenWidth = context.screenWidth;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 500,
                ),
                child: Card(
                  elevation: AppConstants.cardElevation * 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // アプリ名
                        Text(
                          AppConstants.appName,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        
                        // サブタイトル
                        Text(
                          _isLogin ? 'ログイン' : 'サインアップ',
                          style: AppTextStyles.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        // メールアドレス
                        TextField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'メールアドレス',
                            prefixIcon: Icon(Icons.email, color: AppColors.primary),
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
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'パスワード',
                            prefixIcon: Icon(Icons.lock, color: AppColors.primary),
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
                        
                        // サインアップ時の追加フィールド
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _firstNameController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: '名',
                              prefixIcon: Icon(Icons.person, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                              ),
                            ),
                            style: AppTextStyles.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _lastNameController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: '姓',
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                              ),
                            ),
                            style: AppTextStyles.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nicknameController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'ニックネーム（オプション）',
                              prefixIcon: Icon(Icons.badge, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                              ),
                            ),
                            style: AppTextStyles.bodyLarge,
                          ),
                        ],
                        
                        // エラーメッセージ
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: AppColors.error),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTextStyles.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // 送信ボタン
                        SizedBox(
                          height: AppConstants.buttonHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.textWhite,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'ログイン' : 'サインアップ',
                                    style: AppTextStyles.buttonMedium,
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // モード切り替えボタン
                        TextButton(
                          onPressed: _isLoading ? null : _toggleMode,
                          child: Text(
                            _isLogin
                                ? 'アカウントをお持ちでない方はこちら'
                                : 'すでにアカウントをお持ちの方はこちら',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}