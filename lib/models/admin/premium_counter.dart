import 'package:cloud_firestore/cloud_firestore.dart';

/// プレミアム会員数カウンター
/// 
/// Firestoreの単一ドキュメントで管理
/// ID: 'counter' (固定)
/// 主に `premium_counter/counter` ドキュメント用途。
///
/// フォーマット規約:
/// - ID は固定ドキュメントID `'counter'` を運用。
/// - 日付 (`lastUpdated`) は Firestore Timestamp / ISO8601 を許容。
/// - 列挙相当値はなし。
///
/// 関連モデル:
/// - AdminPageState (`lib/models/admin/admin_home_model.dart`) の表示値ソースとなる。
class PremiumCounter {
  final int count;
  final DateTime lastUpdated;

  PremiumCounter({
    required this.count,
    required this.lastUpdated,
  });

  // fromMap: 必須キー=なし, 任意キー=count/lastUpdated, デフォルト値=count:0, lastUpdated:now
  factory PremiumCounter.fromMap(Map<String, dynamic> map) {
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return PremiumCounter(
      count: map['count'] as int? ?? 0,
      lastUpdated: _toDate(map['lastUpdated']),
    );
  }

  // toMap: 必須キー=count/lastUpdated, 任意キー=なし, デフォルト値=なし
  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  PremiumCounter copyWith({
    int? count,
    DateTime? lastUpdated,
  }) {
    return PremiumCounter(
      count: count ?? this.count,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'PremiumCounter(count: $count, lastUpdated: $lastUpdated)';
  }
}
