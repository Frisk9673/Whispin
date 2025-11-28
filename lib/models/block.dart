class Block {
  final String id; // Unique block ID
  final String blockerId; // User who blocked
  final String blockedId; // User who was blocked
  final bool active; // Active flag for soft delete
  final DateTime createdAt;
  
  Block({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    this.active = true,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'blockerId': blockerId,
    'blockedId': blockedId,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory Block.fromJson(Map<String, dynamic> json) => Block(
    id: json['id'] as String,
    blockerId: json['blockerId'] as String,
    blockedId: json['blockedId'] as String,
    active: json['active'] as bool? ?? true,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
