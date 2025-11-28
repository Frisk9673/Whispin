class Message {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String text;
  final DateTime timestamp;
  
  Message({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.text,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'userId': userId,
    'username': username,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    roomId: json['roomId'] as String,
    userId: json['userId'] as String,
    username: json['username'] as String,
    text: json['text'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
