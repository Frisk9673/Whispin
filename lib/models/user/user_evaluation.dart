/// UserEvaluation は、ユーザー間の評価（好意/非好意）を表すモデル。
/// 主に `user_evaluations` コレクションでレート集計や信頼度判定に利用する。
///
/// フォーマット規約:
/// - ID (`id`, `evaluatorId`, `evaluatedId`) は User.id 準拠の文字列。
/// - 日付 (`createdAt`) は ISO8601 文字列で保存。
/// - 列挙相当値 (`rating`) は 'up' | 'down' | null。
///
/// 関連モデル:
/// - User (`lib/models/user/user.dart`) の被評価/評価者関係を表現する。
class UserEvaluation {
  final String id; // Unique evaluation ID
  final String evaluatorId; // User who gave the evaluation
  final String evaluatedId; // User who was evaluated
  final String? rating; // 'up' or 'down' or null
  final DateTime createdAt;

  UserEvaluation({
    required this.id,
    required this.evaluatorId,
    required this.evaluatedId,
    this.rating,
    required this.createdAt,
  });

  // toMap: 必須キー=id/evaluatorId/evaluatedId/createdAt, 任意キー=rating, デフォルト値=rating:null
  Map<String, dynamic> toMap() => {
        'id': id,
        'evaluatorId': evaluatorId,
        'evaluatedId': evaluatedId,
        'rating': rating,
        'createdAt': createdAt.toIso8601String(),
      };

  // fromMap: 必須キー=id/evaluatorId/evaluatedId/createdAt, 任意キー=rating, デフォルト値=rating:null
  factory UserEvaluation.fromMap(Map<String, dynamic> json) => UserEvaluation(
        id: json['id'] as String,
        evaluatorId: json['evaluatorId'] as String,
        evaluatedId: json['evaluatedId'] as String,
        rating: json['rating'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
