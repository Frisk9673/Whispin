import 'package:flutter/material.dart';

/// BuildContext型向けの拡張メソッド。
///
/// 主用途: 画面情報・テーマ取得、UI操作（ダイアログ/スナックバー/ナビゲーション）。
/// 区分: UI向け。
extension ContextExtensions on BuildContext {
  // ===== MediaQuery Access =====

  /// MediaQueryデータを取得
  /// 境界条件: このBuildContext配下にMediaQueryがない場合は例外。
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// 画面サイズを取得
  /// 境界条件: レイアウト確定前は意図しないサイズになる場合がある。
  Size get screenSize => mediaQuery.size;

  /// 画面幅を取得
  /// 境界条件: 横向き/分割表示時は値が大きく変化する。
  double get screenWidth => screenSize.width;

  /// 画面高さを取得
  /// 境界条件: キーボード表示中は実効領域と見た目が一致しない場合がある。
  double get screenHeight => screenSize.height;

  /// パディング（セーフエリア）を取得
  /// 境界条件: セーフエリアが不要なデバイスでは `EdgeInsets.zero` 相当。
  EdgeInsets get padding => mediaQuery.padding;

  // ===== Theme Access =====

  /// ThemeDataを取得
  /// 境界条件: Themeが見つからないツリーでは例外。
  ThemeData get theme => Theme.of(this);

  /// ColorSchemeを取得
  /// 境界条件: テーマ設定に依存するため実際の色は環境で変わる。
  ColorScheme get colorScheme => theme.colorScheme;

  /// CardThemeDataを取得
  /// 境界条件: 未設定プロパティはThemeData側デフォルト値が返る。
  CardThemeData get cardTheme => theme.cardTheme;

  /// InputDecorationThemeを取得
  /// 境界条件: 未設定プロパティはThemeData側デフォルト値が返る。
  InputDecorationThemeData get inputDecorationTheme => theme.inputDecorationTheme;

  /// ダークモード判定
  /// 境界条件: Brightnessが`dark`の時のみ`true`。
  bool get isDark => theme.brightness == Brightness.dark;

  /// サーフェスカラー
  /// 境界条件: Material 3のColorScheme構成に依存。
  Color get surfaceColor => colorScheme.surface;

  // ===== スナックバー =====

  /// スナックバーを表示
  /// 境界条件: `message` が空文字でも表示される（空行に見える）。
  /// 例: `context.showSnackBar('保存しました')`。
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
  /// 境界条件: `message` が空文字でも緑色背景で表示される。
  ///
  /// 使用箇所: 複数の画面で使用
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// エラースナックバー
  /// 境界条件: `message` が空文字でも赤色背景で表示される。
  ///
  /// 使用箇所: 複数の画面で使用
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  /// 警告スナックバー
  /// 境界条件: `message` が空文字でも橙色背景で表示される。
  ///
  /// 使用箇所: 複数の画面で使用
  void showWarningSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.orange);
  }

  /// 情報スナックバー
  /// 境界条件: `message` が空文字でも青色背景で表示される。
  ///
  /// 使用箇所: 複数の画面で使用
  void showInfoSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.blue);
  }

  // ===== ローディングダイアログ =====

  /// ローディングダイアログを表示
  /// 境界条件: `message == null` の場合は `'読み込み中...'` を表示。
  ///
  /// 使用箇所:
  /// - lib/screens/user/friend_list_screen.dart
  /// - lib/screens/user/block_list_screen.dart
  /// - その他非同期処理中の表示
  void showLoadingDialog({String? message}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      useRootNavigator: true,
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
  /// 境界条件: 閉じる対象がない場合は何も閉じずログ出力のみ。
  ///
  /// 使用箇所: showLoadingDialogとペアで使用
  void hideLoadingDialog() {
    final navigator = Navigator.of(this, rootNavigator: true);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    debugPrint(
      '[ContextExtensions] hideLoadingDialog was called, but there is no route to pop.',
    );
  }

  // ===== 確認ダイアログ =====

  /// 確認ダイアログを表示
  /// 境界条件: ダイアログを閉じた結果が `null` の場合は `false` 扱い。
  ///
  /// 使用箇所:
  /// - lib/screens/user/profile.dart
  /// - lib/screens/user/friend_list_screen.dart
  /// - その他削除/変更確認
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

  /// カスタムダイアログを表示
  /// 境界条件: `barrierDismissible` が `false` の場合は外側タップで閉じない。
  /// 例: `context.showCustomDialog(child: MyDialog())`。
  ///
  /// 使用箇所:
  /// - lib/screens/user/chat_screen.dart
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

  // ===== ナビゲーション =====

  /// 戻る
  /// 境界条件: pop可能でない状態で呼ぶとNavigator側で例外になる場合がある。
  /// 例: `if (context.canPop) context.pop();`。
  void pop<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// 戻れるか確認
  /// 境界条件: ルート画面など戻り先がない場合は `false`。
  bool get canPop => Navigator.of(this).canPop();
}
