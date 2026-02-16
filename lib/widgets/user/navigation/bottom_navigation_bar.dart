import 'package:flutter/material.dart';
import '../../../constants/navigation_items.dart';
import '../../../constants/colors.dart';
import '../../../extensions/context_extensions.dart';

/// モバイル用ボトムナビゲーションバー
class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  /// ルート遷移の実行責務は親に委譲し、このWidgetはindex通知のみを担当する。
  final ValueChanged<int> onTap;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: context.colorScheme.surface,
          selectedItemColor: isDark
              ? AppColors.primary.lighten(0.2)
              : AppColors.primary,
          unselectedItemColor: isDark
              ? Colors.grey[600]
              : Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: NavigationItems.mainItems
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}