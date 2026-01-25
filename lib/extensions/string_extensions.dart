/// String型の拡張メソッド
extension StringExtensions on String {
  // ===== バリデーション =====

  /// メールアドレスとして有効か
  /// 
  /// 使用箇所:
  /// - lib/screens/user/account_create_screen.dart
  /// - lib/screens/user/user_login_page.dart
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// 空文字列または空白のみでないか
  /// 
  /// 使用箇所:
  /// - 複数のフォームバリデーション
  bool get isNotBlank {
    return trim().isNotEmpty;
  }

  /// 空文字列または空白のみか
  /// 
  /// 使用箇所:
  /// - 複数のフォームバリデーション
  bool get isBlank {
    return trim().isEmpty;
  }

  // ===== 文字列操作 =====

  /// 最大文字数で切り捨て（省略記号付き）
  /// 
  /// 使用箇所:
  /// - UI表示での長文省略
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// 最初の文字を大文字にする
  /// 
  /// 使用箇所:
  /// - アバター表示での頭文字取得
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}