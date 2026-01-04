import 'package:intl/intl.dart';

/// DateTime型の拡張メソッド
extension DateTimeExtensions on DateTime {
  // ===== Formatting =====

  /// 日本語形式でフォーマット (yyyy年MM月dd日)
  String get toJapaneseDate {
    return DateFormat('yyyy年MM月dd日', 'ja_JP').format(this);
  }

  /// 日本語形式（曜日付き） (yyyy年MM月dd日 (曜日))
  String get toJapaneseDateWithWeekday {
    return DateFormat('yyyy年MM月dd日 (E)', 'ja_JP').format(this);
  }

  /// 時刻のみ (HH:mm)
  String get toTimeString {
    return DateFormat('HH:mm').format(this);
  }

  /// 日時 (yyyy-MM-dd HH:mm)
  String get toDateTimeString {
    return DateFormat('yyyy-MM-dd HH:mm').format(this);
  }

  /// フル形式 (yyyy-MM-dd HH:mm:ss)
  String get toFullString {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(this);
  }

  /// ISO 8601形式
  String get toIsoString {
    return toIso8601String();
  }

  /// 相対的な時間表記（〜前）
  String get toRelativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.isNegative) {
      return '未来';
    }

    if (difference.inSeconds < 60) {
      return 'たった今';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    }

    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks週間前';
    }

    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$monthsヶ月前';
    }

    final years = (difference.inDays / 365).floor();
    return '$years年前';
  }

  /// チャット用の時刻表示
  String get toChatTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inMinutes < 1) {
      return 'たった今';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes}分前';
    }

    if (difference.inDays < 1 && day == now.day) {
      return DateFormat('HH:mm').format(this);
    }

    if (difference.inDays < 7) {
      return DateFormat('E HH:mm', 'ja_JP').format(this);
    }

    return DateFormat('MM/dd').format(this);
  }

  // ===== Comparison =====

  /// 今日か
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// 昨日か
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// 明日か
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// 今週か
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.startOfDay) && isBefore(endOfWeek.endOfDay);
  }

  /// 今月か
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// 今年か
  bool get isThisYear {
    return year == DateTime.now().year;
  }

  /// 過去か
  bool get isPast {
    return isBefore(DateTime.now());
  }

  /// 未来か
  bool get isFuture {
    return isAfter(DateTime.now());
  }

  /// 範囲内か
  bool isBetween(DateTime start, DateTime end) {
    return (isAfter(start) || isAtSameMomentAs(start)) &&
        (isBefore(end) || isAtSameMomentAs(end));
  }

  // ===== Manipulation =====

  /// 日付の開始時刻 (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// 日付の終了時刻 (23:59:59.999)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// 週の開始日（月曜日）
  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }

  /// 週の終了日（日曜日）
  DateTime get endOfWeek {
    return add(Duration(days: 7 - weekday)).endOfDay;
  }

  /// 月の開始日
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// 月の終了日
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// 年の開始日
  DateTime get startOfYear {
    return DateTime(year, 1, 1);
  }

  /// 年の終了日
  DateTime get endOfYear {
    return DateTime(year, 12, 31, 23, 59, 59, 999);
  }

  /// N日後
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  /// N週間後
  DateTime addWeeks(int weeks) {
    return add(Duration(days: weeks * 7));
  }

  /// Nヶ月後
  DateTime addMonths(int months) {
    return DateTime(year, month + months, day, hour, minute, second);
  }

  /// N年後
  DateTime addYears(int years) {
    return DateTime(year + years, month, day, hour, minute, second);
  }

  /// N日前
  DateTime subtractDays(int days) {
    return subtract(Duration(days: days));
  }

  /// N週間前
  DateTime subtractWeeks(int weeks) {
    return subtract(Duration(days: weeks * 7));
  }

  /// Nヶ月前
  DateTime subtractMonths(int months) {
    return DateTime(year, month - months, day, hour, minute, second);
  }

  /// N年前
  DateTime subtractYears(int years) {
    return DateTime(year - years, month, day, hour, minute, second);
  }

  // ===== Properties =====

  /// 曜日（日本語）
  String get weekdayJapanese {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[weekday - 1];
  }

  /// 月の日数
  int get daysInMonth {
    return DateTime(year, month + 1, 0).day;
  }

  /// 年の日数（うるう年対応）
  int get daysInYear {
    return isLeapYear ? 366 : 365;
  }

  /// うるう年か
  bool get isLeapYear {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// 週末か（土日）
  bool get isWeekend {
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// 平日か
  bool get isWeekday {
    return !isWeekend;
  }

  /// 午前か
  bool get isAM {
    return hour < 12;
  }

  /// 午後か
  bool get isPM {
    return hour >= 12;
  }

  /// 年齢を計算（生年月日から）
  int ageFrom(DateTime birthDate) {
    int age = year - birthDate.year;
    if (month < birthDate.month ||
        (month == birthDate.month && day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// 経過時間を計算
  Duration timeSince(DateTime other) {
    return difference(other);
  }

  /// 残り時間を計算
  Duration timeUntil(DateTime other) {
    return other.difference(this);
  }

  // ===== Utility =====

  /// コピーして時刻のみ変更
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }

  /// 同じ日付か比較
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// 同じ月か比較
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// 同じ年か比較
  bool isSameYear(DateTime other) {
    return year == other.year;
  }
}