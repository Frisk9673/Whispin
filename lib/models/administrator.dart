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