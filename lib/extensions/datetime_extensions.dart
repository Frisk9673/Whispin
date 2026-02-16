import 'package:intl/intl.dart';

/// DateTime型向けの拡張メソッド。
///
/// 主用途: 日時の表示フォーマット・比較・演算。
/// 区分: ドメイン向け（時間計算）+ UI向け（表示文字列化）。
extension DateTimeExtensions on DateTime {
  // ===== 相対時間表記 =====
  
  /// 相対的な時間表記（〜前）
  /// 境界条件: 未来日時の場合は `'未来'` を返す。
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
    // 境界条件: `other` が過去日時の場合、負のDurationを返す。
    // 例: `DateTime.now().timeUntil(deadline)` で締切までの残り時間を取得。
    return other.difference(this);
  }

  // ===== 日付操作 =====
  
  /// 日付の開始時刻 (00:00:00)
  /// 境界条件: タイムゾーン情報は元のDateTimeのローカル/UTC性を引き継ぐ。
  /// 
  /// 使用箇所:
  /// - 日付範囲検索などで使用
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// 日付の終了時刻 (23:59:59.999)
  /// 境界条件: ミリ秒は999固定（マイクロ秒は0）。
  /// 
  /// 使用箇所:
  /// - 日付範囲検索などで使用
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  // ===== 日付比較 =====
  
  /// 今日か
  /// 境界条件: 年/月/日が完全一致した場合のみ `true`。
  /// 
  /// 使用箇所:
  /// - チャット画面のメッセージ表示
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// 昨日か
  /// 境界条件: 日付のみ比較するため時刻部分は無視。
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// 過去か
  /// 境界条件: `DateTime.now()` と同一時刻の場合は `false`。
  bool get isPast {
    return isBefore(DateTime.now());
  }

  /// 未来か
  /// 境界条件: `DateTime.now()` と同一時刻の場合は `false`。
  bool get isFuture {
    return isAfter(DateTime.now());
  }

  // ===== Duration変換 =====
  
  /// N日後
  /// 境界条件: 負数を渡すと実質的に「N日前」と同等になる。
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  /// N日前
  /// 境界条件: 負数を渡すと実質的に「N日後」と同等になる。
  DateTime subtractDays(int days) {
    return subtract(Duration(days: days));
  }

  // ===== ユーティリティ =====
  
  /// 同じ日付か比較
  /// 境界条件: 時刻は比較せず、年/月/日のみで判定。
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// 日本語形式でフォーマット (yyyy年MM月dd日)
  /// 境界条件: null非許容（extension対象がnon-null DateTime）。
  String get toJapaneseDate {
    return DateFormat('yyyy年MM月dd日', 'ja_JP').format(this);
  }

  /// 日本語形式（曜日付き） (yyyy年MM月dd日 (曜日))
  /// 境界条件: ロケール `ja_JP` が未初期化だと期待通りの曜日表記にならない場合がある。
  String get toJapaneseDateWithWeekday {
    return DateFormat('yyyy年MM月dd日 (E)', 'ja_JP').format(this);
  }

  /// 時刻のみ (HH:mm)
  /// 境界条件: 秒以下は切り捨て、24時間表記固定。
  String get toTimeString {
    return DateFormat('HH:mm').format(this);
  }
}
