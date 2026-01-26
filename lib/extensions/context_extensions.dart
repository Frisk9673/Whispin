import 'package:flutter/material.dart';

/// BuildContext型の拡張メソッド
extension ContextExtensions on BuildContext {
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

  // ===== レスポンシブデザイン =====

  /// モバイルデバイスか（幅 < 768px）
  /// 
  /// 使用箇所:
  /// - lib/widgets/evaluation_dialog.dart
  /// - レスポンシブUI判定
  bool get isMobile => screenWidth < 768;

  // ===== スナックバー =====

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
  /// 
  /// 使用箇所: 複数の画面で使用
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// エラースナックバー
  /// 
  /// 使用箇所: 複数の画面で使用
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  /// 警告スナックバー
  /// 
  /// 使用箇所: 複数の画面で使用
  void showWarningSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.orange);
  }

  /// 情報スナックバー
  /// 
  /// 使用箇所: 複数の画面で使用
  void showInfoSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.blue);
  }

  // ===== ローディングダイアログ =====

  /// ローディングダイアログを表示
  /// 
  /// 使用箇所:
  /// - lib/screens/user/friend_list_screen.dart
  /// - lib/screens/user/block_list_screen.dart
  /// - その他非同期処理中の表示
  void showLoadingDialog({String? message}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      useRootNavigator: true, // ✅ 追加
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
  /// 
  /// 使用箇所: showLoadingDialogとペアで使用
  void hideLoadingDialog() {
    Navigator.of(this, rootNavigator: true).pop(); // ← 対になる指定
  }

  // ===== 確認ダイアログ =====

  /// 確認ダイアログを表示
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
  void pop<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// 戻れるか確認
  bool get canPop => Navigator.of(this).canPop();
}