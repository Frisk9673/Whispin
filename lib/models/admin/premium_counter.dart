import 'package:cloud_firestore/cloud_firestore.dart';

/// プレミアム会員数カウンター
/// 
/// Firestoreの単一ドキュメントで管理
/// ID: 'counter' (固定)
class PremiumCounter {
  final int count;
  final DateTime lastUpdated;

  PremiumCounter({
    required this.count,
    required this.lastUpdated,
  });

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