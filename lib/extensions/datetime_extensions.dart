import 'package:intl/intl.dart';

/// DateTime型の拡張メソッド
extension DateTimeExtensions on DateTime {
  // ===== 相対時間表記 =====
  
  /// 相対的な時間表記（〜前）
  /// 
  /// 使用箇所: 
  /// - lib/screens/user/question_chat_user.dart
  /// - lib/screens/user/notifications.dart
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

  // ===== 時間計算 =====
  
  /// 残り時間を計算
  /// 
  /// 使用箇所:
  /// - lib/screens/user/chat_screen.dart
  /// - lib/services/chat_service.dart
  Duration timeUntil(DateTime other) {
    return other.difference(this);
  }

  // ===== 日付操作 =====
  
  /// 日付の開始時刻 (00:00:00)
  /// 
  /// 使用箇所:
  /// - 日付範囲検索などで使用
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// 日付の終了時刻 (23:59:59.999)
  /// 
  /// 使用箇所:
  /// - 日付範囲検索などで使用
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  // ===== 日付比較 =====
  
  /// 今日か
  /// 
  /// 使用箇所:
  /// - チャット画面のメッセージ表示
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

  /// 過去か
  bool get isPast {
    return isBefore(DateTime.now());
  }

  /// 未来か
  bool get isFuture {
    return isAfter(DateTime.now());
  }

  // ===== Duration変換 =====
  
  /// N日後
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  /// N日前
  DateTime subtractDays(int days) {
    return subtract(Duration(days: days));
  }

  // ===== ユーティリティ =====
  
  /// 同じ日付か比較
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

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
}