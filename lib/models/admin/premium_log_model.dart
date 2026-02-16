import 'package:cloud_firestore/cloud_firestore.dart';

/// PremiumLog は、プレミアム契約/解約の監査ログを表すモデル。
/// 主に `premium_logs` コレクションで履歴追跡・監査用途に利用する。
///
/// フォーマット規約:
/// - ID 相当 (`email`) はユーザー識別メール文字列。
/// - 日付 (`timestamp`) は Firestore Timestamp。
/// - 列挙相当値 (`detail`) は「契約」「解約」などの文字列コード。
///
/// 関連モデル:
/// - User (`lib/models/user/user.dart`) の premium 状態変更イベントに対応する。
class PremiumLog {
  final String email;
  final DateTime timestamp;
  final String detail; // 契約 or 解約

  PremiumLog({
    required this.email,
    required this.timestamp,
    required this.detail,
  });

  // fromMap: 必須キー=ID/Timestamp/Detail, 任意キー=なし, デフォルト値=なし
  factory PremiumLog.fromMap(Map<String, dynamic> map) {
    return PremiumLog(
      email: map['ID'],
      timestamp: (map['Timestamp'] as Timestamp).toDate(),
      detail: map['Detail'],
    );
  }
}
