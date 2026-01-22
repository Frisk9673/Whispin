import 'package:intl/intl.dart';
import 'dart:math';

/// num型（int, double）の拡張メソッド
extension NumExtensions on num {
  // ===== Formatting =====

  /// 通貨形式でフォーマット（日本円）
  String get toYen {
    return NumberFormat.currency(locale: 'ja_JP', symbol: '¥').format(this);
  }

  /// 通貨形式でフォーマット（記号なし）
  String get toCurrency {
    return NumberFormat.currency(locale: 'ja_JP', symbol: '').format(this);
  }

  /// カンマ区切りの数値形式
  String get toCommaFormat {
    return NumberFormat('#,###').format(this);
  }

  /// パーセント表記
  String toPercent([int decimals = 0]) {
    return NumberFormat.percentPattern('ja_JP')
            .format(this / 100)
            .replaceAll('%', '')
            .padRight(decimals + 1, '0') +
        '%';
  }

  /// 小数点以下N桁でフォーマット
  String toDecimal(int decimals) {
    return toStringAsFixed(decimals);
  }

  /// ファイルサイズ形式（B, KB, MB, GB）
  String get toFileSize {
    if (this < 1024) return '${toInt()} B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 時間形式（秒 → 分:秒）
  String get toTimeString {
    final minutes = (this ~/ 60).toString().padLeft(2, '0');
    final seconds = (this % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 時間形式（秒 → 時:分:秒）
  String get toFullTimeString {
    final hours = (this ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((this % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (this % 60).toInt().toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // ===== Validation =====

  /// 範囲内か確認
  bool isBetween(num min, num max) {
    return this >= min && this <= max;
  }

  /// 正の数か
  bool get isPositive => this > 0;

  /// 負の数か
  bool get isNegative => this < 0;

  /// ゼロか
  bool get isZero => this == 0;

  /// 偶数か（整数のみ）
  bool get isEven => toInt() % 2 == 0;

  /// 奇数か（整数のみ）
  bool get isOdd => toInt() % 2 != 0;

  // ===== Clamping & Rounding =====

  /// 値を範囲内に収める
  num clampTo(num min, num max) {
    return clamp(min, max);
  }

  /// 最小値を保証
  num atLeast(num min) {
    return this < min ? min : this;
  }

  /// 最大値を保証
  num atMost(num max) {
    return this > max ? max : this;
  }

  /// 指定桁数で四捨五入
  double roundToDecimals(int decimals) {
    final factor = 10.0 * decimals;
    return (this * factor).round() / factor;
  }

  /// 最も近い倍数に丸める
  num roundToMultiple(num multiple) {
    return (this / multiple).round() * multiple;
  }

  /// 切り上げ（最も近い倍数）
  num ceilToMultiple(num multiple) {
    return (this / multiple).ceil() * multiple;
  }

  /// 切り下げ（最も近い倍数）
  num floorToMultiple(num multiple) {
    return (this / multiple).floor() * multiple;
  }

  // ===== Conversion =====

  /// Duration型に変換（秒として）
  Duration get seconds => Duration(seconds: toInt());

  /// Duration型に変換（ミリ秒として）
  Duration get milliseconds => Duration(milliseconds: toInt());

  /// Duration型に変換（分として）
  Duration get minutes => Duration(minutes: toInt());

  /// Duration型に変換（時間として）
  Duration get hours => Duration(hours: toInt());

  /// Duration型に変換（日として）
  Duration get days => Duration(days: toInt());

  // ===== Percentage =====

  /// この値が全体の何パーセントか
  double percentOf(num total) {
    if (total == 0) return 0;
    return (this / total) * 100;
  }

  /// 全体からこの割合の値を取得
  double percentFrom(num total) {
    return total * (this / 100);
  }

  // ===== Math Operations =====

  /// 絶対値
  num get absolute => abs();

  /// 符号（1, 0, -1）
  int get sign => this > 0 ? 1 : (this < 0 ? -1 : 0);

  /// 平方根
  double get squareRoot => sqrt(this);

  /// 累乗
  num power(num exponent) => pow(this, exponent);

  /// 平方
  num get squared => this * this;

  /// 立方
  num get cubed => this * this * this;

  // ===== Comparison =====

  /// ほぼ等しいか（誤差許容）
  bool isCloseTo(num other, {double epsilon = 0.0001}) {
    return (this - other).abs() < epsilon;
  }

  // ===== Utility =====

  /// 数値を反復してループ
  void times(void Function(int index) action) {
    for (var i = 0; i < toInt(); i++) {
      action(i);
    }
  }

  /// 範囲を生成
  List<int> rangeTo(int end, {int step = 1}) {
    final start = toInt();
    if (step == 0) throw ArgumentError('Step cannot be zero');

    final result = <int>[];
    if (step > 0) {
      for (var i = start; i <= end; i += step) {
        result.add(i);
      }
    } else {
      for (var i = start; i >= end; i += step) {
        result.add(i);
      }
    }
    return result;
  }

  /// 安全な除算（ゼロ除算を防ぐ）
  double safeDivide(num divisor, {double defaultValue = 0.0}) {
    if (divisor == 0) return defaultValue;
    return this / divisor;
  }

  /// パーセンテージから実数値を計算
  double fromPercent(num base) {
    return base * (this / 100);
  }
}
