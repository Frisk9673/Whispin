import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whispin/routes/app_router.dart';
import '../../screens/admin/premium_log_list_screen.dart';
import '../../providers/admin_provider.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/routes.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../utils/app_logger.dart';

// 対象業務: 管理ハブ（質問管理/チャット監視/ログ閲覧への導線）
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const String _logName = 'AdminHomeScreen';

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appBarForeground =
        Theme.of(context).appBarTheme.foregroundColor ?? colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理画面'),
        automaticallyImplyLeading: false, // 戻るボタンを非表示
        actions: [
          // リフレッシュボタン
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              logger.info('手動リフレッシュ', name: _logName);
              admin.refresh();
            },
            tooltip: '更新',
          ),

          // ログアウトボタン
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () async {
                logger.info('ログアウトボタン押下', name: _logName);

                // ログアウト確認ダイアログ
                final result = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius),
                    ),
                    title: Text('ログアウト', style: textTheme.titleLarge),
                    content: Text(
                      'ログアウトしますか？',
                      style: textTheme.bodyMedium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text(
                          'ログアウト',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (result == true && context.mounted) {
                  NavigationHelper.toAdminLogin(context);
                }
              },
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'ログアウト',
                  style: TextStyle(
                    color: appBarForeground,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.background,
            ],
          ),
        ),
        child: Column(
          children: [
            // 有料会員数表示
            Padding(
              padding:
                  const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
              child: admin.isLoading
                  ? SizedBox(
                      height: 120,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '読み込み中...',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 有料会員数カード
                        Card(
                          elevation: AppConstants.cardElevation,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              logger.info('有料会員数カードタップ → PremiumLogListScreen',
                                  name: _logName);
                              AppRouter.navigateTo(
                                context,
                                AppRoutes.premiumLogs,
                              );
                            },
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius,
                            ),
                            child: Container(
                              padding:
                                  EdgeInsets.all(AppConstants.defaultPadding),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.diamond,
                                    color: AppColors.textWhite,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    children: [
                                      Text(
                                        '有料会員数',
                                        style:
                                            AppTextStyles.titleMedium.copyWith(
                                          color: AppColors.textWhite,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${admin.paidMemberCount}人',
                                        style: AppTextStyles.headlineLarge
                                            .copyWith(
                                          color: AppColors.textWhite,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 機能ボタン
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // お問い合わせボタン（緑）
                            _buildCircleButton(
                              context: context,
                              label: 'お問い合わせ',
                              icon: Icons.support_agent,
                              onPressed: () {
                                logger.info('お問い合わせボタン押下', name: _logName);
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.questionChat);
                              },
                              backgroundColor: Colors.green,
                            ),

                            // 有料会員ログボタン（青）
                            _buildCircleButton(
                              context: context,
                              label: '有料会員\nログ',
                              icon: Icons.receipt_long,
                              backgroundColor: Colors.blue,
                              onPressed: () {
                                logger.info('有料会員ログボタン押下', name: _logName);
                                AppRouter.navigateTo(
                                  context,
                                  AppRoutes.premiumLogs,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // スペーサー
            const Expanded(
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                backgroundColor != null ? null : AppColors.primaryGradient,
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: (backgroundColor ?? AppColors.primary).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 88,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}
