import 'package:flutter/material.dart';
import '../constants/routes.dart';

/// ナビゲーションアイテムの定義
class NavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

/// アプリ全体のナビゲーションアイテム定義
class NavigationItems {
  NavigationItems._();

  /// メインナビゲーションアイテム（タブ一覧）
  static const List<NavigationItem> mainItems = [
    NavigationItem(
      label: '部屋に参加',
      icon: Icons.meeting_room_outlined,
      activeIcon: Icons.meeting_room,
      route: AppRoutes.joinRoom,
    ),
    NavigationItem(
      label: '部屋を作成',
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      route: AppRoutes.createRoom,
    ),
    NavigationItem(
      label: 'フレンド',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      route: AppRoutes.friendList,
    ),
    NavigationItem(
      label: 'ブロック',
      icon: Icons.block_outlined,
      activeIcon: Icons.block,
      route: AppRoutes.blockList,
    ),
  ];

  /// 現在のルートからインデックスを取得
  static int getIndexFromRoute(String? routeName) {
    if (routeName == null) return 0;
    
    final index = mainItems.indexWhere((item) => item.route == routeName);
    return index >= 0 ? index : 0;
  }

  /// インデックスからルートを取得
  static String getRouteFromIndex(int index) {
    if (index < 0 || index >= mainItems.length) {
      return mainItems[0].route;
    }
    return mainItems[index].route;
  }
}