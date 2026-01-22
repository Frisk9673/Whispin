import 'package:flutter/material.dart';

/// BuildContext型の拡張メソッド
extension ContextExtensions on BuildContext {
  // ===== Theme Access =====

  /// テーマデータを取得
  ThemeData get theme => Theme.of(this);

  /// テキストテーマを取得
  TextTheme get textTheme => theme.textTheme;

  /// カラースキームを取得
  ColorScheme get colorScheme => theme.colorScheme;

  /// プライマリーカラー
  Color get primaryColor => colorScheme.primary;

  /// セカンダリーカラー
  Color get secondaryColor => colorScheme.secondary;

  /// 背景色
  Color get backgroundColor => colorScheme.surface;

  /// エラーカラー
  Color get errorColor => colorScheme.error;

  // ===== MediaQuery Access =====

  /// MediaQueryデータを取得
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// 画面サイズを取得
  Size get screenSize => mediaQuery.size;

  /// 画面幅を取得
  double get screenWidth => screenSize.width;

  /// 画面高さを取得
  double get screenHeight => screenSize.height;

  /// パディング（セーフエリア）を取得
  EdgeInsets get padding => mediaQuery.padding;

  /// ビューインセット（キーボード等）を取得
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// 画面の向きを取得
  Orientation get orientation => mediaQuery.orientation;

  /// ポートレート（縦向き）か
  bool get isPortrait => orientation == Orientation.portrait;

  /// ランドスケープ（横向き）か
  bool get isLandscape => orientation == Orientation.landscape;

  // ===== Responsive Design =====

  /// モバイルデバイスか（幅 < 768px）
  bool get isMobile => screenWidth < 768;

  /// タブレットデバイスか（768px <= 幅 < 1024px）
  bool get isTablet => screenWidth >= 768 && screenWidth < 1024;

  /// デスクトップか（幅 >= 1024px）
  bool get isDesktop => screenWidth >= 1024;

  /// 小さい画面か（幅 < 600px）
  bool get isSmallScreen => screenWidth < 600;

  /// 中サイズ画面か（600px <= 幅 < 1200px）
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;

  /// 大きい画面か（幅 >= 1200px）
  bool get isLargeScreen => screenWidth >= 1200;

  /// レスポンシブ値を取得
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  // ===== Navigation =====

  /// 画面遷移
  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// 画面遷移（置き換え）
  Future<T?> pushReplacement<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// 画面遷移（全スタッククリア）
  Future<T?> pushAndRemoveUntil<T>(
    Widget page, {
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => page),
      predicate ?? (route) => false,
    );
  }

  /// 戻る
  void pop<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// 戻れるか確認
  bool get canPop => Navigator.of(this).canPop();

  /// ルートまで戻る
  void popUntilRoot() {
    Navigator.of(this).popUntil((route) => route.isFirst);
  }

  // ===== Dialogs & Overlays =====

  /// ダイアログを表示
  Future<T?> showCustomDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (_) => child,
    );
  }

  /// ボトムシートを表示
  Future<T?> showCustomBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = false,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => child,
    );
  }

  /// スナックバーを表示
  void showSnackBar(
    String message, {
    Duration? duration,
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
        action: action,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 成功スナックバー
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// エラースナックバー
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  /// 警告スナックバー
  void showWarningSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.orange);
  }

  /// 情報スナックバー
  void showInfoSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.blue);
  }

  /// ローディングダイアログを表示
  void showLoadingDialog({String? message}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message ?? '読み込み中...'),
            ],
          ),
        ),
      ),
    );
  }

  /// ローディングダイアログを閉じる
  void hideLoadingDialog() {
    if (canPop) pop();
  }

  /// 確認ダイアログを表示
  Future<bool> showConfirmDialog({
    String? title,
    required String message,
    String confirmText = 'OK',
    String cancelText = 'キャンセル',
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (_) => AlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(_).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(_).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ===== Focus =====

  /// キーボードを閉じる
  void unfocus() {
    FocusScope.of(this).unfocus();
  }

  /// フォーカスを外す
  void removeFocus() {
    FocusScope.of(this).requestFocus(FocusNode());
  }

  // ===== Scaffold =====

  /// ScaffoldMessengerを取得
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);

  /// Scaffoldを取得
  ScaffoldState? get scaffold {
    try {
      return Scaffold.of(this);
    } catch (_) {
      return null;
    }
  }

  // ===== Form =====

  /// FormStateを取得
  FormState? get form {
    try {
      return Form.of(this);
    } catch (_) {
      return null;
    }
  }

  /// フォームをバリデート
  bool validateForm() {
    return form?.validate() ?? false;
  }

  /// フォームをリセット
  void resetForm() {
    form?.reset();
  }

  /// フォームを保存
  void saveForm() {
    form?.save();
  }

  // ===== Locale =====

  /// 現在のロケールを取得
  Locale get locale => Localizations.localeOf(this);

  /// 言語コードを取得
  String get languageCode => locale.languageCode;

  /// 国コードを取得
  String? get countryCode => locale.countryCode;

  // ===== Misc =====

  /// ウィジェットのサイズを取得
  Size? get widgetSize {
    final renderBox = findRenderObject() as RenderBox?;
    return renderBox?.size;
  }

  /// ウィジェットの位置を取得
  Offset? get widgetPosition {
    final renderBox = findRenderObject() as RenderBox?;
    return renderBox?.localToGlobal(Offset.zero);
  }
}
