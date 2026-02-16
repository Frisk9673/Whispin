// localStorageフォールバック用の認証ユーザー
// 主にクライアント側保存（localStorage/JSON）用途で、Firestore 永続化の主モデルではない。
//
// フォーマット規約:
// - ID (`userId`, `email`) は文字列 ID。
// - 日付 (`createdAt`) は ISO8601 文字列で保存。
// - 列挙相当値はなし。
//
// 関連モデル:
// - User (`lib/models/user/user.dart`) の認証キャッシュ/フォールバック表現として利用する。
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

  // toMap: 必須キー=email/username/salt/passwordHash/userId/createdAt, 任意キー=なし, デフォルト値=なし
  Map<String, dynamic> toMap() => {
        'email': email,
        'username': username,
        'salt': salt,
        'passwordHash': passwordHash,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
      };

  // fromMap: 必須キー=email/username/salt/passwordHash/userId/createdAt, 任意キー=なし, デフォルト値=なし
  factory LocalAuthUser.fromMap(Map<String, dynamic> json) => LocalAuthUser(
        email: json['email'] as String,
        username: json['username'] as String,
        salt: json['salt'] as String,
        passwordHash: json['passwordHash'] as String,
        userId: json['userId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
