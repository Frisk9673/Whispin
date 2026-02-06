import 'package:flutter/material.dart';
import '../../constants/navigation_items.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/app_constants.dart';
import '../../extensions/context_extensions.dart';

/// Web/デスクトップ用サイドナビゲーションバー
class AppSideNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppSideNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ヘッダー部分
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.secondary.withOpacity(0.8),
                      ],
                    )
                  : AppColors.primaryGradient,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ナビゲーションアイテム
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: NavigationItems.mainItems.length,
              itemBuilder: (context, index) {
                final item = NavigationItems.mainItems[index];
                final isSelected = currentIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTap(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.primary.withOpacity(0.2)
                                  : AppColors.primary.withOpacity(0.1))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: isDark
                                      ? AppColors.primary.lighten(0.2)
                                      : AppColors.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.primary.lighten(0.2)
                                      : AppColors.primary)
                                  : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item.label,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.primary.lighten(0.2)
                                          : AppColors.primary)
                                      : (isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[800]),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // フッター（オプション）
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.divider,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Version ${AppConstants.appVersion}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}