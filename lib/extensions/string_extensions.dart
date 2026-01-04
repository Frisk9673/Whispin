import 'dart:convert';

/// String型の拡張メソッド
extension StringExtensions on String {
  // ===== Validation =====

  /// メールアドレスとして有効か
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// 電話番号として有効か（日本の形式）
  bool get isValidPhoneNumber {
    // 日本の電話番号形式をチェック（ハイフンあり/なし両対応）
    final phoneRegex = RegExp(
      r'^(0[5-9]0-?\d{4}-?\d{4}|0\d{1,4}-?\d{1,4}-?\d{4})$',
    );
    return phoneRegex.hasMatch(this);
  }

  /// 空文字列または空白のみでないか
  bool get isNotBlank {
    return trim().isNotEmpty;
  }

  /// 空文字列または空白のみか
  bool get isBlank {
    return trim().isEmpty;
  }

  /// 数字のみで構成されているか
  bool get isNumeric {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// 英字のみで構成されているか
  bool get isAlphabetic {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  /// 英数字のみで構成されているか
  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  // ===== Transformation =====

  /// 最初の文字を大文字にする
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// 各単語の最初の文字を大文字にする
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// 最大文字数で切り捨て（省略記号付き）
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// 指定文字数でパディング
  String padLeftZero(int width) {
    return padLeft(width, '0');
  }

  /// スネークケースに変換
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  /// キャメルケースに変換
  String get toCamelCase {
    return split('_')
        .asMap()
        .map((i, word) {
          if (i == 0) return MapEntry(i, word.toLowerCase());
          return MapEntry(i, word.capitalize);
        })
        .values
        .join('');
  }

  /// パスカルケースに変換
  String get toPascalCase {
    return split('_').map((word) => word.capitalize).join('');
  }

  // ===== Parsing =====

  /// int型に変換（失敗時はnull）
  int? toIntOrNull() {
    return int.tryParse(this);
  }

  /// double型に変換（失敗時はnull）
  double? toDoubleOrNull() {
    return double.tryParse(this);
  }

  /// DateTime型に変換（失敗時はnull）
  DateTime? toDateTimeOrNull() {
    return DateTime.tryParse(this);
  }

  // ===== String Manipulation =====

  /// 指定文字列を削除
  String remove(String pattern) {
    return replaceAll(pattern, '');
  }

  /// 空白文字を全て削除
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// 最初のN文字を取得
  String takeFirst(int n) {
    if (length <= n) return this;
    return substring(0, n);
  }

  /// 最後のN文字を取得
  String takeLast(int n) {
    if (length <= n) return this;
    return substring(length - n);
  }

  /// 指定文字列で囲む
  String wrap(String prefix, [String? suffix]) {
    return '$prefix$this${suffix ?? prefix}';
  }

  /// 引用符で囲む
  String get quoted => wrap('"');

  /// 括弧で囲む
  String get parenthesized => wrap('(', ')');

  // ===== Encoding/Decoding =====

  /// Base64エンコード
  String get toBase64 {
    return base64.encode(utf8.encode(this));
  }

  /// Base64デコード
  String get fromBase64 {
    try {
      return utf8.decode(base64.decode(this));
    } catch (e) {
      return this;
    }
  }

  // ===== Comparison =====

  /// 大文字小文字を無視して比較
  bool equalsIgnoreCase(String other) {
    return toLowerCase() == other.toLowerCase();
  }

  /// 指定文字列で始まる（大文字小文字無視）
  bool startsWithIgnoreCase(String pattern) {
    return toLowerCase().startsWith(pattern.toLowerCase());
  }

  /// 指定文字列で終わる（大文字小文字無視）
  bool endsWithIgnoreCase(String pattern) {
    return toLowerCase().endsWith(pattern.toLowerCase());
  }

  /// 指定文字列を含む（大文字小文字無視）
  bool containsIgnoreCase(String pattern) {
    return toLowerCase().contains(pattern.toLowerCase());
  }

  // ===== Utility =====

  /// 逆順にする
  String get reversed {
    return split('').reversed.join('');
  }

  /// 指定回数繰り返す
  String repeat(int count) {
    if (count <= 0) return '';
    return List.filled(count, this).join();
  }

  /// マスク処理（一部を隠す）
  String mask({
    int visibleStart = 3,
    int visibleEnd = 3,
    String maskChar = '*',
  }) {
    if (length <= visibleStart + visibleEnd) return this;

    final start = substring(0, visibleStart);
    final end = substring(length - visibleEnd);
    final masked = maskChar * (length - visibleStart - visibleEnd);

    return '$start$masked$end';
  }

  /// メールアドレスをマスク
  String get maskedEmail {
    if (!isValidEmail) return this;

    final parts = split('@');
    final local = parts[0];
    final domain = parts[1];

    if (local.length <= 2) return this;

    final maskedLocal = '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}';
    return '$maskedLocal@$domain';
  }

  /// 電話番号をマスク
  String get maskedPhone {
    final cleaned = removeWhitespace().replaceAll('-', '');
    if (cleaned.length < 8) return this;

    return mask(visibleStart: 3, visibleEnd: 4);
  }
}

