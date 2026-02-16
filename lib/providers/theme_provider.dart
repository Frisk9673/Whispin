import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// テーマモード管理プロバイダー
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  // ===== 管理対象state一覧 =====
  // _themeMode: 現在のテーマ設定（light/dark/system）。
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// 初期化: SharedPreferencesから保存済みテーマを読み込む
  /// state変更: SharedPreferencesの値に応じて _themeMode を更新。
  Future<void> initialize() async {
    // Service境界: 永続化層(SharedPreferences)の読み取りを実施する。
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    // 初期テーマをUI全体へ反映するため再描画する。
    notifyListeners();
  }

  /// テーマモードを変更
  /// state変更:
  /// - 開始時: _themeMode を指定モードへ更新
  /// - 終了時: 永続化ストレージへ保存
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    // テーマ切り替えを即時反映するため再描画する。
    notifyListeners();

    // Service境界: 永続化層(SharedPreferences)への保存のみを担当する。
    final prefs = await SharedPreferences.getInstance();
    String themeString;

    switch (mode) {
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }

    await prefs.setString(_themeKey, themeString);
  }

  /// ダークモードとライトモードをトグル
  /// state変更: setThemeMode() 経由で _themeMode を更新。
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
