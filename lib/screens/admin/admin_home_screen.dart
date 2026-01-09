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

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});
  
  static const String _logName = 'AdminHomeScreen';

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理画面'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        automaticallyImplyLeading: false, // 戻るボタンを非表示
        actions: [
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
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    title: Text('ログアウト', style: AppTextStyles.titleLarge),
                    content: Text(
                      'ログアウトしますか？',
                      style: AppTextStyles.bodyMedium,
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
              child: const Align(
                alignment: Alignment.center,
                child: Text(
                  'ログアウト',
                  style: TextStyle(
                    color: Colors.white,
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
              AppColors.backgroundLight,
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: Column(
          children: [
            // 有料会員数表示
            Padding(
              padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
              child: admin.isLoading
                  ? const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
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
                              logger.info('有料会員数カードタップ → PremiumLogListScreen', name: _logName);
                              AppRouter.navigateTo(
                                context,
                                AppRoutes.premiumLogs,
                              );
                            },
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius,
                            ),
                            child: Container(
                              padding: EdgeInsets.all(AppConstants.defaultPadding),
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
                                        style: AppTextStyles.titleMedium.copyWith(
                                          color: AppColors.textWhite,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${admin.paidMemberCount}人',
                                        style: AppTextStyles.headlineLarge.copyWith(
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
                              label: 'お問い合わせ',
                              icon: Icons.support_agent,
                              onPressed: () {
                                logger.info('お問い合わせボタン押下', name: _logName);
                                Navigator.of(context).pushNamed(AppRoutes.questionChat);
                              },
                              backgroundColor: Colors.green,
                            ),
                            
                            // 有料会員ログボタン（青）
                            _buildCircleButton(
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
            gradient: backgroundColor != null
                ? null
                : AppColors.primaryGradient,
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
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}