import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/user_auth_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_storage_service.dart';
import '../../providers/user_provider.dart';
import '../../screens/user/home_screen.dart';
import '../account_create/account_create_screen.dart';
import '../admin/admin_login_screen.dart';
import '../../utils/app_logger.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({super.key});

  @override
  State<UserLoginPage> createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final userAuthService = UserAuthService();

  String message = '';
  bool _isLoading = false;
  static const String _logName = 'UserLoginPage';

  Future<void> _login() async {
    logger.section('_login() 開始', name: _logName);
    logger.info('入力されたメール: ${emailController.text}', name: _logName);
    
    setState(() {
      _isLoading = true;
      message = '';
    });

    try {
      logger.start('FirebaseAuth でログイン処理中...', name: _logName);

      final loginResult = await userAuthService.loginUser(
        email: emailController.text,
        password: passwordController.text,
      );

      logger.success('Auth ログイン成功: $loginResult', name: _logName);

      if (!mounted) {
        logger.warning('画面非表示状態で終了', name: _logName);
        return;
      }

      // 論理削除チェック
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        logger.start('Firestore からユーザ情報取得中: ${user.email}', name: _logName);
        final query = await FirebaseFirestore.instance
            .collection('User')
            .where('EmailAddress', isEqualTo: user.email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final userData = query.docs.first.data();
          final isDeleted = userData['IsDeleted'] ?? false;
          logger.info('取得したユーザ情報: $userData', name: _logName);

          if (isDeleted) {
            logger.error('論理削除済みアカウントです', name: _logName);
            await FirebaseAuth.instance.signOut();
            setState(() {
              message = "このアカウントは削除済みです";
              _isLoading = false;
            });
            logger.warning('ログイン中断: 論理削除アカウント', name: _logName);
            return;
          }
        } else {
          logger.warning('ユーザ情報がFirestoreに存在しません', name: _logName);
        }
      }

      // UserProviderでユーザー情報を読み込む
      logger.start('UserProviderでユーザー情報読み込み開始...', name: _logName);
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserData();

      if (userProvider.error != null) {
        logger.error('UserProvider読み込みエラー: ${userProvider.error}', name: _logName);
        setState(() {
          message = "ユーザー情報の読み込みに失敗しました";
          _isLoading = false;
        });
        return;
      }

      logger.success('UserProvider読み込み完了', name: _logName);
      logger.start('正常ログイン → HomeScreen へ遷移', name: _logName);
      
      // Services を Provider から取得
      final authService = context.read<AuthService>();
      final storageService = context.read<FirestoreStorageService>();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            authService: authService,
            storageService: storageService,
          ),
        ),
      );

      logger.section('_login() 正常終了', name: _logName);

    } catch (e, stack) {
      logger.error('ログイン処理で例外発生: $e', 
        name: _logName, 
        error: e, 
        stackTrace: stack,
      );
      setState(() {
        message = "ログインエラー: $e";
        _isLoading = false;
      });
      logger.section('_login() 異常終了', name: _logName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
              enabled: !_isLoading,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),

            // ローディング表示付きログインボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('ログイン中...'),
                        ],
                      )
                    : const Text('ログイン'),
              ),
            ),

            const SizedBox(height: 20),
            Text(message, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 10),
            TextButton(
              onPressed: _isLoading ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserRegisterPage()),
                );
              },
              child: const Text("新規登録はこちら"),
            ),

            TextButton(
              onPressed: _isLoading ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              },
              child: const Text(
                '管理者ログインはこちら',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}