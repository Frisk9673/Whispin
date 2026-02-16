/// Administrator は、管理者アカウント情報と権限ロールを表すモデル。
/// 主に `administrators`（または同等の管理者ドキュメント）用途で利用する。
///
/// フォーマット規約:
/// - ID 相当 (`email`) はメールアドレス文字列。
/// - 日付 (`lastLogin`) は ISO8601 文字列を想定。
/// - 列挙相当値 (`role`) は 'admin' などの文字列コード。
///
/// 関連モデル:
/// - QuestionChat/Message (`lib/models/admin_user/...`) の対応者権限判定に利用される。
class Administrator {
  final String email;
  final String password;
  final String role;
  final DateTime? lastLogin;

  Administrator({
    required this.email,
    required this.password,
    required this.role,
    this.lastLogin,
  });

  // fromFirestore(fromMap 相当): 必須キー=なし(email は引数で受領), 任意キー=Password/Role/LastLogin
  // デフォルト値=password:'', role:'admin', lastLogin:null
  factory Administrator.fromFirestore(String email, Map<String, dynamic> data) {
    return Administrator(
      email: email,
      password: data['Password'] as String? ?? '',
      role: data['Role'] as String? ?? 'admin',
      lastLogin: data['LastLogin'] != null
          ? DateTime.tryParse(data['LastLogin'])
          : null,
    );
  }

  bool get isAdmin => role == 'admin';
}
