/// String型向けの拡張メソッド。
///
/// 主用途: 入力バリデーションと表示用文字列整形。
/// 区分: UI向け（フォーム入力・テキスト表示）中心。
extension StringExtensions on String {
  // ===== バリデーション =====

  /// メールアドレスとして有効か
  /// 境界条件: 空文字/空白のみ文字列は `false`。
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
  /// 境界条件: `''` や `'   '` は `false`。
  /// 
  /// 使用箇所:
  /// - 複数のフォームバリデーション
  bool get isNotBlank {
    return trim().isNotEmpty;
  }

  /// 空文字列または空白のみか
  /// 境界条件: `''` や `'   '` は `true`。
  /// 
  /// 使用箇所:
  /// - 複数のフォームバリデーション
  bool get isBlank {
    return trim().isEmpty;
  }

  // ===== 文字列操作 =====

  /// 最大文字数で切り捨て（省略記号付き）
  /// 境界条件: `length <= maxLength` の場合は元文字列をそのまま返す。
  /// 例: `'Flutter'.truncate(5)` は `'Fl...'`。
  /// 
  /// 使用箇所:
  /// - UI表示での長文省略
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// 最初の文字を大文字にする
  /// 境界条件: 空文字列の場合は空文字列をそのまま返す。
  /// 例: `'whispin'.capitalize` は `'Whispin'`。
  /// 
  /// 使用箇所:
  /// - アバター表示での頭文字取得
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
