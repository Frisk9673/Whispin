import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home.dart'; // ← RoomJoinScreen を import

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({super.key});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController tel_idController = TextEditingController(); // ← 電話番号入力欄追加

  String message = '';

  Future<void> registerUser() async {
    final email = emailController.text.trim();

    // Firestore に保存
    try {
      await FirebaseFirestore.instance.collection('User').doc(email).set({
        'email': email,
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'nickname': nicknameController.text,
        'password': passwordController.text,
        'tel_id': tel_idController.text, // ← 電話番号保存
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      setState(() => message = 'Firestore 保存エラー: $e');
      return;
    }

    // バックエンドにユーザー作成リクエスト
    final url = Uri.parse('http://localhost:8081/create_user');

    final body = jsonEncode({
      'email': email,
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'nickname': nicknameController.text,
      'password': passwordController.text,
      'phone': tel_idController.text, // ← 電話番号送信
    });

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['status'] == 'success') {
          // アカウント作成成功 → RoomJoinScreen へ遷移
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoomJoinScreen()),
          );
        } else {
          setState(() => message = 'アカウント作成失敗');
        }
      } else {
        setState(() => message = 'サーバーエラー: ${res.body}');
      }
    } catch (e) {
      setState(() => message = '通信エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー登録')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              controller: tel_idController,
              decoration: const InputDecoration(labelText: '電話番号'),
              keyboardType: TextInputType.phone, // ← 数字入力向け
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: registerUser,
              child: const Text('登録'),
            ),

            const SizedBox(height: 20),
            Text(message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
