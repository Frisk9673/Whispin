class Administrator {
  final String email;
  final String password;
  final DateTime? lastLogin;

  Administrator({
    required this.email,
    required this.password,
    this.lastLogin,
  });

  factory Administrator.fromFirestore(String email, Map<String, dynamic> data) {
    return Administrator(
      email: email,
      password: data['Password'] as String? ?? '',
      lastLogin: data['LastLogin'] != null
          ? DateTime.tryParse(data['LastLogin'])
          : null,
    );
  }
}