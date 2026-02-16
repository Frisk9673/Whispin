import 'package:flutter/material.dart';

/// アプリ全体で使用するカラーパレット
class AppColors {
  // インスタンス化を防ぐ
  AppColors._();

  // ===== UIテーマ系（ブランド・状態・画面トーン） =====

  // 基本カラー
  // 主要CTAやブランド印象を統一するため、全画面で同じ基調色を採用する。
  static const Color primary = Color(0xFF667EEA);
  // primary とのグラデーション時に視認性と奥行きが両立する補助色を固定する。
  static const Color secondary = Color(0xFF764BA2);

  // グラデーション
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, secondary],
  );

  // 背景色
  static Color get backgroundLight => primary.withValues(alpha: 0.1);
  static Color get backgroundSecondary => secondary.withValues(alpha: 0.1);

  // ダークモード
  // 純黒を避けてコントラスト疲れを抑えるため、Material準拠の暗色値を使用する。
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkInput = Color(0xFF2C2C2C);
  static const Color darkBorder = Color(0xFF404040);
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkSurface, darkBackground],
  );

  // テキスト
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.grey;
  static const Color textWhite = Colors.white;
  static Color get textDisabled => Colors.grey.shade400;

  // ステータス
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  // UI
  static Color get cardBackground => Colors.white;
  static Color get divider => Colors.grey.shade300;
  static Color get border => Colors.black87;
  static Color get inputBackground => Colors.grey.shade50;

  // プレミアム
  static const Color premiumGold = Colors.amber;
  static const Color premiumIcon = Color(0xFF667EEA);

  // シャドウ
  static Color get shadowLight => Colors.black.withValues(alpha: 0.05);
  static Color get shadowMedium => Colors.black.withValues(alpha: 0.1);
  static Color get shadowDark => Colors.black.withValues(alpha: 0.2);

  // メッセージバブル
  static Color get bubbleAdmin => Colors.grey.shade200;
  static const Color bubbleUser = primary;

  // 管理画面
  static Color get adminBackground => Colors.grey.shade100;
  static const Color adminPrimary = primary;
}

/// カラーテーマ関連のヘルパー拡張
extension ColorExtension on Color {
  /// 透明度をパーセントで調整したカラーを返す
  Color withOpacityPercent(int percent) {
    return withValues(alpha: percent / 100);
  }

  /// 明度を調整したカラーを返す
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// 暗度を調整したカラーを返す
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
