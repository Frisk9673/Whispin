import 'package:flutter/material.dart';
import 'admin_login_controller.dart';
import 'admin_home_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  late final AdminLoginController controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = AdminLoginController();
  }

  Future<void> _onLogin() async {
    setState(() => _isLoading = true);
    final success = await controller.login();
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      // 成功 → 管理者ホームへ（履歴消して戻れないように）
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログイン失敗：メールまたはパスワードが違います'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理者ログイン')),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller.emailController,
                decoration: const InputDecoration(labelText: 'メールアドレス', prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'パスワード', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _onLogin,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ログイン'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
