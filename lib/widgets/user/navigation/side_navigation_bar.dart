import 'package:flutter/material.dart';
import '../../../constants/navigation_items.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import '../../../constants/app_constants.dart';
import '../../../extensions/context_extensions.dart';

/// Web/デスクトップ用サイドナビゲーションバー
class AppSideNavigationBar extends StatelessWidget {
  final int currentIndex;

  /// ルート遷移の実行責務は親に委譲し、このWidgetは選択index通知のみを担当する。
  final ValueChanged<int> onTap;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AppSideNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      width: isCollapsed ? 72 : 280,
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
          _buildTopArea(context, isDark),

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
                      // 画面遷移自体は親が実施し、ここではタップ結果のみ通知する。
                      onTap: () => onTap(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
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
                        child: isCollapsed
                            ? Center(
                                child: Tooltip(
                                  message: item.label,
                                  child: Icon(
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
                                ),
                              )
                            : Row(
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
                                                ? AppColors.primary.lighten(
                                                    0.2,
                                                  )
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
            child: isCollapsed
                ? Tooltip(
                    message: 'Version ${AppConstants.appVersion}',
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  )
                : Row(
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

  Widget _buildTopArea(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.grey[100] : Colors.grey[900];
    final iconColor = isDark ? Colors.grey[300] : Colors.grey[700];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.divider,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          if (!isCollapsed)
            Text(
              'TOP',
              style: AppTextStyles.titleSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.menu_open : Icons.menu,
              color: iconColor,
            ),
            onPressed: onToggleCollapse,
            tooltip: isCollapsed ? 'サイドバーを展開' : 'サイドバーを収納',
          ),
        ],
      ),
    );
  }
}
