import 'package:flutter/material.dart';

// Context拡張メソッド

/// BuildContext に対するレスポンシブ対応の拡張メソッド
///
/// 使用例:
/// ```dart
/// if (context.isMobile) {
///   // モバイル専用処理
/// }
///
/// final padding = context.responsiveValue(
///   mobile: 16,
///   tablet: 24,
/// );
/// ```
extension ResponsiveContext on BuildContext {
  // デバイス判定

  /// モバイルデバイスかどうか
  bool get isMobile => ResponsiveHelper.isMobile(this);

  /// タブレットデバイスかどうか
  bool get isTablet => ResponsiveHelper.isTablet(this);

  /// デスクトップデバイスかどうか
  bool get isDesktop => ResponsiveHelper.isDesktop(this);

  /// 大画面デスクトップかどうか
  bool get isLargeDesktop => ResponsiveHelper.isLargeDesktop(this);

  // 画面サイズ

  /// 画面の幅
  double get screenWidth => ResponsiveHelper.getWidth(this);

  /// 画面の高さ
  double get screenHeight => ResponsiveHelper.getHeight(this);

  /// 画面のサイズ
  Size get screenSize => ResponsiveHelper.getSize(this);

  // レスポンシブ値

  /// デバイスサイズに応じた値を返す
  double responsiveValue({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return ResponsiveHelper.getResponsiveValue(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// デバイスサイズに応じたint値を返す
  int responsiveIntValue({
    required int mobile,
    int? tablet,
    int? desktop,
  }) {
    return ResponsiveHelper.getResponsiveIntValue(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// デバイスサイズに応じたウィジェットを返す
  Widget responsiveWidget({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    return ResponsiveHelper.getResponsiveWidget(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  // スペーシング

  /// デバイスサイズに応じたパディング
  EdgeInsets get responsivePadding {
    return ResponsiveHelper.getResponsivePadding(this);
  }

  /// デバイスサイズに応じた水平パディング
  EdgeInsets get responsiveHorizontalPadding {
    return ResponsiveHelper.getResponsiveHorizontalPadding(this);
  }

  /// デバイスサイズに応じた垂直パディング
  EdgeInsets get responsiveVerticalPadding {
    return ResponsiveHelper.getResponsiveVerticalPadding(this);
  }

  // フォント

  /// デバイスサイズに応じたフォントスケールファクター
  double get fontScaleFactor => ResponsiveHelper.getFontScaleFactor(this);

  /// デバイスサイズに応じたフォントサイズ
  double responsiveFontSize(double baseFontSize) {
    return ResponsiveHelper.getResponsiveFontSize(this, baseFontSize);
  }

  // Grid設定

  /// デバイスサイズに応じたGridカラム数
  int get gridCrossAxisCount {
    return ResponsiveHelper.getGridCrossAxisCount(this);
  }

  /// デバイスサイズに応じたGridスペーシング
  double get gridSpacing => ResponsiveHelper.getGridSpacing(this);

  // コンテナ幅

  /// デバイスサイズに応じた最大コンテナ幅
  double get maxContainerWidth {
    return ResponsiveHelper.getMaxContainerWidth(this);
  }

  /// デバイスサイズに応じた最大フォーム幅
  double get maxFormWidth => ResponsiveHelper.getMaxFormWidth(this);

  // 向き判定

  /// 横向き（ランドスケープ）かどうか
  bool get isLandscape => ResponsiveHelper.isLandscape(this);

  /// 縦向き（ポートレート）かどうか
  bool get isPortrait => ResponsiveHelper.isPortrait(this);

  // 安全領域

  /// 画面のパディング（SafeArea用）
  EdgeInsets get safeAreaPadding => ResponsiveHelper.getPadding(this);

  /// 画面のビューインセット（キーボード等）
  EdgeInsets get viewInsets => ResponsiveHelper.getViewInsets(this);

  /// キーボードが表示されているか
  bool get isKeyboardVisible => ResponsiveHelper.isKeyboardVisible(this);

  // デバッグ

  /// デバイス情報（デバッグ用）
  String get deviceInfo => ResponsiveHelper.getDeviceInfo(this);
}

/// レスポンシブデザインのブレークポイント定数
class ResponsiveBreakpoints {
  // プライベートコンストラクタ
  ResponsiveBreakpoints._();

  /// モバイルの上限（600px未満）
  static const double mobile = 600;

  /// タブレットの上限（900px未満）
  static const double tablet = 900;

  /// デスクトップの下限（900px以上）
  static const double desktop = 900;

  /// 大画面デスクトップの下限（1200px以上）
  static const double largeDesktop = 1200;
}

/// レスポンシブデザインのヘルパークラス
class ResponsiveHelper {
  // プライベートコンストラクタ
  ResponsiveHelper._();

  // デバイス判定

  /// モバイルデバイスかどうか（幅 < 600px）
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }

  /// タブレットデバイスかどうか（600px <= 幅 < 900px）
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile &&
        width < ResponsiveBreakpoints.desktop;
  }

  /// デスクトップデバイスかどうか（幅 >= 900px）
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
  }

  /// 大画面デスクトップかどうか（幅 >= 1200px）
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >=
        ResponsiveBreakpoints.largeDesktop;
  }

  // 画面サイズ取得

  /// 画面の幅を取得
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 画面の高さを取得
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 画面のサイズを取得
  static Size getSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  // レスポンシブ値の取得

  /// デバイスサイズに応じた値を返す
  ///
  /// 使用例:
  /// ```dart
  /// final padding = ResponsiveHelper.getResponsiveValue(
  ///   context,
  ///   mobile: 16,
  ///   tablet: 24,
  ///   desktop: 32,
  /// );
  /// ```
  static double getResponsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// デバイスサイズに応じたint値を返す
  static int getResponsiveIntValue(
    BuildContext context, {
    required int mobile,
    int? tablet,
    int? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// デバイスサイズに応じたウィジェットを返す
  ///
  /// 使用例:
  /// ```dart
  /// ResponsiveHelper.getResponsiveWidget(
  ///   context,
  ///   mobile: MobileLayout(),
  ///   tablet: TabletLayout(),
  ///   desktop: DesktopLayout(),
  /// );
  /// ```
  static Widget getResponsiveWidget(
    BuildContext context, {
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  // スペーシング

  /// デバイスサイズに応じたパディングを返す
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final value = getResponsiveValue(
      context,
      mobile: mobile ?? 16,
      tablet: tablet ?? 24,
      desktop: desktop ?? 32,
    );
    return EdgeInsets.all(value);
  }

  /// デバイスサイズに応じた水平パディングを返す
  static EdgeInsets getResponsiveHorizontalPadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final value = getResponsiveValue(
      context,
      mobile: mobile ?? 16,
      tablet: tablet ?? 24,
      desktop: desktop ?? 32,
    );
    return EdgeInsets.symmetric(horizontal: value);
  }

  /// デバイスサイズに応じた垂直パディングを返す
  static EdgeInsets getResponsiveVerticalPadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final value = getResponsiveValue(
      context,
      mobile: mobile ?? 16,
      tablet: tablet ?? 24,
      desktop: desktop ?? 32,
    );
    return EdgeInsets.symmetric(vertical: value);
  }

  // フォントサイズ

  /// デバイスサイズに応じたフォントスケールファクターを返す
  static double getFontScaleFactor(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
  }

  /// デバイスサイズに応じたフォントサイズを返す
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    final scaleFactor = getFontScaleFactor(context);
    return baseFontSize * scaleFactor;
  }

  // アイコンサイズ

  /// デバイスサイズに応じたアイコンサイズを返す
  static double getResponsiveIconSize(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    return getResponsiveValue(
      context,
      mobile: mobile ?? 24,
      tablet: tablet ?? 28,
      desktop: desktop ?? 32,
    );
  }

  // GridView設定

  /// デバイスサイズに応じたGridViewのカラム数を返す
  static int getGridCrossAxisCount(
    BuildContext context, {
    int? mobile,
    int? tablet,
    int? desktop,
  }) {
    return getResponsiveIntValue(
      context,
      mobile: mobile ?? 2,
      tablet: tablet ?? 3,
      desktop: desktop ?? 4,
    );
  }

  /// デバイスサイズに応じたGridViewのスペーシングを返す
  static double getGridSpacing(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 16,
      tablet: 20,
      desktop: 24,
    );
  }

  // コンテナ幅制限

  /// デバイスサイズに応じた最大コンテナ幅を返す
  ///
  /// モバイル: 画面幅いっぱい
  /// タブレット: 600px
  /// デスクトップ: 800px
  static double getMaxContainerWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: double.infinity,
      tablet: 600,
      desktop: 800,
    );
  }

  /// デバイスサイズに応じたフォーム最大幅を返す
  static double getMaxFormWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: double.infinity,
      tablet: 500,
      desktop: 600,
    );
  }

  // 向き判定

  /// 横向き（ランドスケープ）かどうか
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// 縦向き（ポートレート）かどうか
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // 安全領域

  /// 画面のパディング（SafeArea用）を取得
  static EdgeInsets getPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// 画面のビューインセット（キーボード等）を取得
  static EdgeInsets getViewInsets(BuildContext context) {
    return MediaQuery.of(context).viewInsets;
  }

  /// キーボードが表示されているかどうか
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  // デバッグ用

  /// デバイス情報を文字列で返す（デバッグ用）
  static String getDeviceInfo(BuildContext context) {
    final size = getSize(context);
    final deviceType = isMobile(context)
        ? 'Mobile'
        : isTablet(context)
            ? 'Tablet'
            : 'Desktop';
    final orientation = isLandscape(context) ? 'Landscape' : 'Portrait';

    return '''
Device: $deviceType
Width: ${size.width.toStringAsFixed(0)}px
Height: ${size.height.toStringAsFixed(0)}px
Orientation: $orientation
''';
  }
}
