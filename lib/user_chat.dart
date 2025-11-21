import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  String? chatId; // 作成した QuestionChat のID
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _createOrGetChat();
  }

  // 🔥 QuestionChat を自動作成 or 既存取得
  Future<void> _createOrGetChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final tel = user.phoneNumber ?? user.email ?? "unknown";

    // 1. 既に問い合わせチャットがあるか確認
    final check = await FirebaseFirestore.instance
        .collection("QuestionChat")
        .where("UserID", isEqualTo: tel)
        .limit(1)
        .get();

    if (check.docs.isNotEmpty) {
      setState(() {
        chatId = check.docs.first.id;
      });
      return;
    }

    // 2. ない場合は新しく作る
    final doc = await FirebaseFirestore.instance
        .collection("QuestionChat")
        .add({
      "UserID": tel,
      "AdminID": null,
      "LastMessage": "",
      "UpdatedAt": FieldValue.serverTimestamp(),
    });

    setState(() {
      chatId = doc.id;
    });
  }

  // 🔥 メッセージ送信
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || chatId == null) return;

    final text = _controller.text.trim();
    _controller.clear();

    final msgDoc = FirebaseFirestore.instance
        .collection("QuestionChat")
        .doc(chatId)
        .collection("Messages")
        .doc();

    await msgDoc.set({
      "ID": msgDoc.id,
      "IsAdmin": false, // ←ユーザー側の送信
      "Text": text,
      "CreatedAt": FieldValue.serverTimestamp(),
      "Read": false,
    });

    // 最新メッセージ更新
    await FirebaseFirestore.instance
        .collection("QuestionChat")
        .doc(chatId)
        .update({
      "LastMessage": text,
      "UpdatedAt": FieldValue.serverTimestamp()
    });
  }

  @override
  Widget build(BuildContext context) {
    if (chatId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("お問い合わせ")),
      body: Column(
        children: [
          // ---------- メッセージ一覧 ----------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("QuestionChat")
                  .doc(chatId)
                  .collection("Messages")
                  .orderBy("CreatedAt")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: docs.map((msg) {
                    final isAdmin = msg["IsAdmin"] as bool;
                    final text = msg["Text"] as String;

                    return Align(
                      alignment: isAdmin
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              isAdmin ? Colors.grey[300] : Colors.blue[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(text),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // ---------- メッセージ入力 ----------
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: "メッセージを入力"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
