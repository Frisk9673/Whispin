// screens/admin/admin_home_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_logout_service.dart';
import 'admin_login_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logoutService = AdminLogoutService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("管理者トップ"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await logoutService.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
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
