// ...existing code...
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/admin/premium_log_list_screen.dart';
import '../../providers/admin_provider.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理画面'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Align(
                alignment: Alignment.center,
                child: Text(
                  'ログアウト',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
            child: admin.isLoading
                ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PremiumLogListScreen()),
                          );
                        },
                        child: Center(
                          child: Text(
                            '有料会員数: ${admin.paidMemberCount}人',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _circleButton(
                            label: 'お問い合わせ',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/contact');
                            },
                            backgroundColor: Colors.green,
                          ),
                          const Spacer(),
                          _circleButton(
                            label: '有料会員\nログ',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PremiumLogListScreen()),
                              );
                            },
                            backgroundColor: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const Expanded(
            child: Center(
              child: Text('管理画面コンテンツ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor ?? Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      child: const SizedBox(
        width: 88,
        height: 88,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '', // ラベルは下の Text に置かれるため空にしています
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// ...existing code...