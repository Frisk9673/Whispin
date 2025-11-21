import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';

class AdminLoginController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AdminAuthService();

  Future<bool> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return false;
    return await authService.login(email, password);
  }

  Future<void> logout() async {
    await authService.logout();
  }
}
