// localStorageフォールバック用の認証ユーザー
class LocalAuthUser {
  final String email;
  final String username;
  final String salt;
  final String passwordHash;
  final String userId;
  final DateTime createdAt;
  
  LocalAuthUser({
    required this.email,
    required this.username,
    required this.salt,
    required this.passwordHash,
    required this.userId,
    required this.createdAt,
  });
  
  Map<String, dynamic> toMap() => {
    'email': email,
    'username': username,
    'salt': salt,
    'passwordHash': passwordHash,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory LocalAuthUser.fromMap(Map<String, dynamic> json) => LocalAuthUser(
    email: json['email'] as String,
    username: json['username'] as String,
    salt: json['salt'] as String,
    passwordHash: json['passwordHash'] as String,
    userId: json['userId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
