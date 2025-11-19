import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import 'admin_login_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AdminAuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("管理者トップ"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();

              // ログインページへ戻す
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                (_) => false,
              );
            },
          )
        ],
      ),
      body: const Center(
        child: Text(
          "ログイン成功！\nここが管理者ホーム画面です",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
