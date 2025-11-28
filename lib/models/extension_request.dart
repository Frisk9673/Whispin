class ExtensionRequest {
  final String id; // Unique request ID
  final String roomId; // Room ID
  final String requesterId; // User who requested extension
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  
  ExtensionRequest({
    required this.id,
    required this.roomId,
    required this.requesterId,
    this.status = 'pending',
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'requesterId': requesterId,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory ExtensionRequest.fromJson(Map<String, dynamic> json) => ExtensionRequest(
    id: json['id'] as String,
    roomId: json['roomId'] as String,
    requesterId: json['requesterId'] as String,
    status: json['status'] as String? ?? 'pending',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
  
  ExtensionRequest copyWith({
    String? id,
    String? roomId,
    String? requesterId,
    String? status,
    DateTime? createdAt,
  }) {
    return ExtensionRequest(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      requesterId: requesterId ?? this.requesterId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
