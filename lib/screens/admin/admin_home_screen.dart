// screens/admin/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_logout_service.dart';
import 'admin_login_screen.dart';
import '../../screens/admin/premium_log_list_screen.dart';
import '../../providers/premium_log_provider.dart';

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "ログイン成功！\nここが管理者ホーム画面です",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => PremiumLogProvider(),
                      child: const PremiumLogListScreen(),
                    ),
                  ),
                );
              },
              child: const Text("プレミアム契約ログ一覧へ"),
            ),
          ],
        ),
      ),
    );
  }
}
