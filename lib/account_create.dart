import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home.dart'; 
import 'login.dart'; // ← ログイン画面

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({super.key});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final nicknameController = TextEditingController();
  final passwordController = TextEditingController();
  final telIdController = TextEditingController();

  bool loading = false;
  String message = '';

  Future<void> registerUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final telId = telIdController.text.trim();

    if (email.isEmpty || password.isEmpty || telId.isEmpty) {
      setState(() => message = "必須項目が未入力です");
      return;
    }

    try {
      setState(() => loading = true);

      // ① Auth に登録（エミュレータに飛ぶ）
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ② Firestore にユーザー情報を登録（主キーは TEL_ID）
      await FirebaseFirestore.instance
          .collection('User')
          .doc(telId)
          .set({
        "TEL_ID": telId,
        "EmailAddress": email,
        "FirstName": firstNameController.text.trim(),
        "LastName": lastNameController.text.trim(),
        "Nickname": nicknameController.text.trim(),
        "Rate": 0,
        "Premium": false,
        "RoomCount": 3,
        "CreateAt": FieldValue.serverTimestamp(),
        "LastUpdated_Premium": null,
        "DeletedAt": null,
      });

      // 登録成功 → Home（RoomJoinScreen）へ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoomJoinScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => message = "Auth エラー: ${e.code}");
    } catch (e) {
      setState(() => message = "登録エラー: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ユーザー登録")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'メールアドレス'),
              ),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: '名'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: '姓'),
              ),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(labelText: 'ニックネーム'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
              ),
              TextField(
                controller: telIdController,
                decoration: const InputDecoration(labelText: '電話番号（TEL_ID）'),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: loading ? null : registerUser,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("登録"),
              ),

              const SizedBox(height: 16),
              Text(message, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 24),

              /// 🔥 本来入っていた “ログイン画面へ戻る” リンク（復活）
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text(
                  "すでにアカウントをお持ちの方はこちら（ログイン）",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
