
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
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'evaluatorId': evaluatorId,
    'evaluatedId': evaluatedId,
    'rating': rating,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory UserEvaluation.fromMap(Map<String, dynamic> json) => UserEvaluation(
    id: json['id'] as String,
    evaluatorId: json['evaluatorId'] as String,
    evaluatedId: json['evaluatedId'] as String,
    rating: json['rating'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
