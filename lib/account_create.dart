import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: UserRegisterPage(),
    );
  }
}

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

  String message = '';

  Future<void> registerUser() async {
    final url = Uri.parse('http://10.0.2.2:8080/createUser'); // エミュレータの場合は 10.0.2.2

    final body = jsonEncode({
      'email': emailController.text,
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'nickname': nicknameController.text,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        setState(() {
          message = 'ユーザー作成成功';
        });
      } else {
        setState(() {
          message = 'ユーザー作成失敗: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        message = 'エラー: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー登録')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス(ID)'),
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
