import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/common/header.dart';
import '../../widgets/common/unified_widgets.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/responsive.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';
import '../../services/profile_image_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _logName = 'ProfileScreen';
  final ProfileImageService _profileImageService = ProfileImageService();

  Future<void> _logout() async {
    logger.section('ログアウト処理開始', name: _logName);

    try {
      context.read<UserProvider>().clearUser();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      logger.success('ログアウト成功', name: _logName);
      NavigationHelper.toLogin(context);
    } catch (e) {
      logger.error('ログアウトエラー: $e', name: _logName, error: e);
      if (!mounted) return;
      context.showErrorSnackBar('ログアウトエラー: $e');
    }
  }

  Future<void> _handlePremiumButton(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    logger.section('プレミアムボタン押下', name: _logName);

    if (userProvider.currentUser == null) {
      logger.error('currentUserがnull', name: _logName);
      context.showErrorSnackBar('ユーザー情報が読み込まれていません。再ログインしてください。');
      return;
    }

    final isPremium = userProvider.isPremium;

    final result = await context.showConfirmDialog(
      title: isPremium ? 'プレミアム解約' : 'プレミアムプラン加入',
      message: isPremium
          ? '本当に解約しますか？\n\n解約すると以下の特典が利用できなくなります:\n・チャット延長回数が無制限\n・優先サポート\n・広告非表示'
          : 'プレミアムプランに加入しますか？\n\nプレミアム特典:\n・チャット延長回数が無制限\n・優先サポート\n・広告非表示',
      confirmText: '確認',
      cancelText: 'キャンセル',
    );

    if (!result) {
      logger.info('ユーザーがキャンセルしました', name: _logName);
      return;
    }

    context.showLoadingDialog(
      message: isPremium ? '解約処理中...' : 'プレミアムに加入中...',
    );

    try {
      await userProvider.updatePremiumStatus(!isPremium);

      context.hideLoadingDialog();

      if (!mounted) return;

      if (isPremium) {
        context.showWarningSnackBar('プレミアムを解約しました');
      } else {
        context.showSuccessSnackBar('プレミアムに加入しました！');
      }
    } catch (e, stack) {
      logger.error(
        'プレミアムステータス更新エラー',
        name: _logName,
        error: e,
        stackTrace: stack,
      );

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showErrorSnackBar('エラーが発生しました。\n\n${e.toString()}');
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    logger.section('アカウント削除開始', name: _logName);

    final userProvider = context.read<UserProvider>();
    final email = userProvider.currentUser?.id;

    if (email == null) {
      context.showErrorSnackBar('ユーザー情報が取得できません');
      return;
    }

    final result = await context.showConfirmDialog(
      title: 'アカウント削除',
      message: '本当にアカウントを削除しますか？\n\nこの操作は取り消せません。',
      confirmText: '削除する',
      cancelText: 'キャンセル',
    );

    if (!result) return;

    context.showLoadingDialog(message: 'アカウントを削除しています...');

    try {
      logger.start('UserProvider.deleteAccount() 実行中...', name: _logName);
      await userProvider.deleteAccount();
      logger.success('UserProvider.deleteAccount() 完了', name: _logName);

      logger.start('Firebase Auth ログアウト中...', name: _logName);
      await FirebaseAuth.instance.signOut();
      logger.success('Firebase Auth ログアウト完了', name: _logName);

      context.hideLoadingDialog();

      if (!mounted) return;

      logger.success('アカウント削除処理完了', name: _logName);

      NavigationHelper.toLogin(context);
    } catch (e, stack) {
      logger.error(
        'アカウント削除失敗',
        name: _logName,
        error: e,
        stackTrace: stack,
      );

      context.hideLoadingDialog();
      
      if (!mounted) return;
      
      context.showErrorSnackBar(e.toString());
    }
  }

  Future<void> _showProfileImageActionSheet() async {
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.currentUser?.id;

    if (userId == null || userId.isEmpty) {
      context.showErrorSnackBar('ユーザー情報が読み込まれていません。');
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (bottomSheetContext) {
        final isDark = bottomSheetContext.isDark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () => Navigator.pop(bottomSheetContext, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('カメラで撮影'),
                onTap: () => Navigator.pop(bottomSheetContext, 'camera'),
              ),
              if (userProvider.profileImageUrl != null &&
                  userProvider.profileImageUrl!.isNotEmpty)
                ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: isDark ? Colors.red[300] : Colors.red,
                  ),
                  title: Text(
                    '画像を削除',
                    style: TextStyle(color: isDark ? Colors.red[300] : Colors.red),
                  ),
                  onTap: () => Navigator.pop(bottomSheetContext, 'delete'),
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('キャンセル'),
                onTap: () => Navigator.pop(bottomSheetContext),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'delete') {
      await _removeProfileImage();
      return;
    }

    XFile? pickedImage;
    try {
      if (action == 'gallery') {
        pickedImage = await _profileImageService.pickImageFromGallery();
      } else if (action == 'camera') {
        pickedImage = await _profileImageService.takePhoto();
      }

      if (pickedImage == null) return;

      await _uploadProfileImage(pickedImage);
    } catch (e, stack) {
      logger.error('プロフィール画像操作エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      if (!mounted) return;
      context.showErrorSnackBar('画像の処理に失敗しました。');
    }
  }

  Future<void> _uploadProfileImage(XFile imageFile) async {
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.currentUser?.id;

    if (userId == null || userId.isEmpty) {
      context.showErrorSnackBar('ユーザー情報が読み込まれていません。');
      return;
    }

    final previousImageUrl = userProvider.profileImageUrl;

    context.showLoadingDialog(message: 'プロフィール画像をアップロード中...');

    try {
      final downloadUrl = await _profileImageService.uploadProfileImage(
        userId: userId,
        imageFile: imageFile,
      );

      await userProvider.updateProfileImageUrl(downloadUrl);

      if (previousImageUrl != null && previousImageUrl.isNotEmpty) {
        await _profileImageService.deleteProfileImage(previousImageUrl);
      }

      if (!mounted) return;
      context.showSuccessSnackBar('プロフィール画像を更新しました');
    } catch (e, stack) {
      logger.error('プロフィール画像アップロード失敗: $e',
          name: _logName, error: e, stackTrace: stack);
      if (!mounted) return;
      context.showErrorSnackBar('プロフィール画像の更新に失敗しました。');
    } finally {
      if (mounted) {
        try {
          context.hideLoadingDialog();
        } catch (e, stack) {
          logger.warning(
            'ローディングダイアログのクローズに失敗: error=$e,stackTrace=$stack',
            name: _logName,
          );
        }
      }
    }
  }

  Future<void> _removeProfileImage() async {
    final userProvider = context.read<UserProvider>();
    final imageUrl = userProvider.profileImageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      context.showWarningSnackBar('削除する画像がありません。');
      return;
    }

    final result = await context.showConfirmDialog(
      title: 'プロフィール画像を削除',
      message: '現在のプロフィール画像を削除しますか？',
      confirmText: '削除する',
      cancelText: 'キャンセル',
    );

    if (!result) return;

    context.showLoadingDialog(message: 'プロフィール画像を削除中...');

    try {
      await userProvider.updateProfileImageUrl(null);
      await _profileImageService.deleteProfileImage(imageUrl);

      if (!mounted) return;
      context.hideLoadingDialog();
      context.showSuccessSnackBar('プロフィール画像を削除しました');
    } catch (e, stack) {
      logger.error('プロフィール画像削除失敗: $e',
          name: _logName, error: e, stackTrace: stack);
      if (!mounted) return;
      context.hideLoadingDialog();
      context.showErrorSnackBar('プロフィール画像の削除に失敗しました。');
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isMobile) {
    final isDark = context.isDark;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: isMobile ? 20 : 24,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: context.responsiveFontSize(12),
                  color: isDark ? Colors.grey[400] : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: context.responsiveFontSize(16),
                  color: isDark ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggleCard(BuildContext context, bool isMobile) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = context.isDark;
    
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.primary,
                size: isMobile ? 20 : 24,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'テーマ設定',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: context.responsiveFontSize(12),
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDark ? 'ダークモード' : 'ライトモード',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontSize: context.responsiveFontSize(16),
                      color: isDark ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              onChanged: (_) async {
                await themeProvider.setThemeMode(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                );
                
                if (!mounted) return;
                
                context.showSuccessSnackBar(
                  isDark 
                    ? 'ライトモードに変更しました' 
                    : 'ダークモードに変更しました'
                );
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;
    final isMobile = context.isMobile;
    final padding = context.responsivePadding;
    final isDark = context.isDark;

    return Scaffold(
      appBar: const CommonHeader(
        title: 'プロフィール',
        showNotifications: true,
        showProfile: false,
        showPremiumBadge: true,
      ),
      body: userProvider.isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: padding,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: context.maxContainerWidth,
                  ),
                  child: Column(
                    children: [
                      // プロフィール画像カード
                      Card(
                        elevation: AppConstants.cardElevation,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: padding,
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: isMobile ? 100 : AppConstants.avatarSize,
                                    height: isMobile ? 100 : AppConstants.avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.primaryGradient,
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkSurface
                                            : AppColors.cardBackground,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: (userProvider.profileImageUrl != null &&
                                            userProvider.profileImageUrl!.isNotEmpty)
                                        ? Image.network(
                                            userProvider.profileImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) {
                                              return Icon(
                                                Icons.account_circle,
                                                size: isMobile ? 100 : AppConstants.avatarSize,
                                                color: AppColors.textWhite,
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.account_circle,
                                            size: isMobile ? 100 : AppConstants.avatarSize,
                                            color: AppColors.textWhite,
                                          ),
                                  ),
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _showProfileImageActionSheet,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark
                                                  ? AppColors.darkSurface
                                                  : AppColors.cardBackground,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 16 : 24),
                              Text(
                                currentUser?.displayName ??
                                    AppConstants.defaultNickname,
                                style: AppTextStyles.headlineMedium.copyWith(
                                  fontSize: context.responsiveFontSize(24),
                                  color: isDark ? Colors.white : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isMobile ? 16 : 24),

                      // テーマ切り替えカード
                      _buildThemeToggleCard(context, isMobile),

                      SizedBox(height: isMobile ? 16 : 24),

                      // ユーザー情報カード
                      Card(
                        elevation: AppConstants.cardElevation,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 16 : 20),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.badge,
                                'ニックネーム',
                                currentUser?.nickname ??
                                    AppConstants.defaultNickname,
                                isMobile,
                              ),
                              Divider(height: isMobile ? 20 : 24),
                              _buildInfoRow(
                                Icons.person,
                                '本名',
                                currentUser?.fullName ??
                                    AppConstants.defaultNickname,
                                isMobile,
                              ),
                              Divider(height: isMobile ? 20 : 24),
                              _buildInfoRow(
                                Icons.phone,
                                '電話番号',
                                currentUser?.phoneNumber ??
                                    AppConstants.defaultNickname,
                                isMobile,
                              ),
                              Divider(height: isMobile ? 20 : 24),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                                    decoration: BoxDecoration(
                                      color: userProvider.isPremium
                                          ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1)
                                          : (isDark 
                                            ? AppColors.darkInput
                                            : AppColors.inputBackground),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      userProvider.isPremium
                                          ? Icons.diamond
                                          : Icons.person,
                                      color: userProvider.isPremium
                                          ? AppColors.primary
                                          : (isDark ? Colors.grey[400] : AppColors.textSecondary),
                                      size: isMobile ? 20 : 24,
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 12 : 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '会員ステータス',
                                          style: AppTextStyles.labelMedium.copyWith(
                                            fontSize: context.responsiveFontSize(12),
                                            color: isDark ? Colors.grey[400] : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          userProvider.isPremium
                                              ? 'プレミアム会員'
                                              : '通常会員',
                                          style: AppTextStyles.titleMedium.copyWith(
                                            color: userProvider.isPremium
                                                ? AppColors.primary
                                                : (isDark ? Colors.grey[400] : AppColors.textSecondary),
                                            fontSize: context.responsiveFontSize(16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isMobile ? 16 : 24),

                      // アクションボタン
                      GradientButton(
                        icon: userProvider.isPremium
                            ? Icons.diamond_outlined
                            : Icons.diamond,
                        label: userProvider.isPremium ? 'プレミアム解約' : 'プレミアム加入',
                        onPressed: () => _handlePremiumButton(context, userProvider),
                        height: isMobile ? 48 : AppConstants.buttonHeight,
                      ),

                      SizedBox(height: isMobile ? 10 : 12),

                      GradientButton(
                        icon: Icons.support_agent,
                        label: 'お問い合わせ',
                        gradient: LinearGradient(
                          colors: [
                            AppColors.info.lighten(0.15),
                            AppColors.info.darken(0.15),
                          ],
                        ),
                        onPressed: () => NavigationHelper.toUserChat(context),
                        height: isMobile ? 48 : AppConstants.buttonHeight,
                      ),

                      SizedBox(height: isMobile ? 10 : 12),

                      GradientButton(
                        icon: Icons.logout,
                        label: 'ログアウト',
                        gradient: LinearGradient(
                          colors: [
                            AppColors.error.lighten(0.15),
                            AppColors.error.darken(0.15),
                          ],
                        ),
                        onPressed: _logout,
                        height: isMobile ? 48 : AppConstants.buttonHeight,
                      ),

                      SizedBox(height: isMobile ? 10 : 12),

                      GradientButton(
                        icon: Icons.delete_forever,
                        label: 'アカウント削除',
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade600,
                            Colors.grey.shade800,
                          ],
                        ),
                        onPressed: () => _deleteAccount(context),
                        height: isMobile ? 48 : AppConstants.buttonHeight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
