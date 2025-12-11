class Friendship {
  final String id; // Unique friendship ID
  final String userId; // ID of the user
  final String friendId; // ID of the friend
  final bool active; // true = accepted, false = pending
  final DateTime createdAt;
  
  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.active,
    required this.createdAt,
  });
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'friendId': friendId,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory Friendship.fromMap(Map<String, dynamic> json) => Friendship(
    id: json['id'] as String,
    userId: json['userId'] as String,
    friendId: json['friendId'] as String,
    active: json['active'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
