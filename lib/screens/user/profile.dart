import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/header.dart';
import '../../providers/user_provider.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _logName = 'ProfileScreen';

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
    logger.info('現在のユーザー: ${userProvider.currentUser?.id}', name: _logName);
    logger.info('現在のプレミアム状態: ${userProvider.isPremium}', name: _logName);

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

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;

    return Scaffold(
      appBar: const CommonHeader(
        title: 'プロフィール',
        showNotifications: true,
        showProfile: false,
        showPremiumBadge: true,
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  // プロフィール画像カード
                  Card(
                    elevation: AppConstants.cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        children: [
                          Container(
                            width: AppConstants.avatarSize,
                            height: AppConstants.avatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              border: Border.all(
                                color: AppColors.cardBackground,
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
                            child: Icon(
                              Icons.account_circle,
                              size: AppConstants.avatarSize,
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            currentUser?.displayName ??
                                AppConstants.defaultNickname,
                            style: AppTextStyles.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ユーザー情報カード
                  Card(
                    elevation: AppConstants.cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.badge,
                            'ニックネーム',
                            currentUser?.nickname ??
                                AppConstants.defaultNickname,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.person,
                            '本名',
                            currentUser?.fullName ??
                                AppConstants.defaultNickname,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.phone,
                            '電話番号',
                            currentUser?.phoneNumber ??
                                AppConstants.defaultNickname,
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: userProvider.isPremium
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  userProvider.isPremium
                                      ? Icons.diamond
                                      : Icons.person,
                                  color: userProvider.isPremium
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('会員ステータス',
                                        style: AppTextStyles.labelMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      userProvider.isPremium
                                          ? 'プレミアム会員'
                                          : '通常会員',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: userProvider.isPremium
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
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

                  const SizedBox(height: 24),

                  _buildActionButton(
                    icon: userProvider.isPremium
                        ? Icons.diamond_outlined
                        : Icons.diamond,
                    label: userProvider.isPremium ? 'プレミアム解約' : 'プレミアム加入',
                    gradient: AppColors.primaryGradient,
                    onTap: () => _handlePremiumButton(context, userProvider),
                  ),

                  const SizedBox(height: 12),

                  _buildActionButton(
                    icon: Icons.support_agent,
                    label: 'お問い合わせ',
                    gradient: LinearGradient(
                      colors: [
                        AppColors.info.lighten(0.15),
                        AppColors.info.darken(0.15),
                      ],
                    ),
                    onTap: () => NavigationHelper.toUserChat(context),
                  ),

                  const SizedBox(height: 12),

                  _buildActionButton(
                    icon: Icons.logout,
                    label: 'ログアウト',
                    gradient: LinearGradient(
                      colors: [
                        AppColors.error.lighten(0.15),
                        AppColors.error.darken(0.15),
                      ],
                    ),
                    onTap: _logout,
                  ),
                  const SizedBox(height: 12),

                  _buildActionButton(
                    icon: Icons.delete_forever,
                    label: 'アカウント削除',
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade600,
                        Colors.grey.shade800,
                      ],
                    ),
                    onTap: () {
                      logger.info('アカウント削除ボタン押下', name: _logName);
                      context.showInfoSnackBar('この機能は準備中です');
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelMedium),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: AppColors.textWhite, size: AppConstants.iconSize),
              const SizedBox(width: 12),
              Text(label, style: AppTextStyles.buttonMedium),
            ],
          ),
        ),
      ),
    );
  }
}
