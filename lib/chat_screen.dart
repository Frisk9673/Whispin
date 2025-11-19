import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------
            // ヘッダー
            // -----------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Whispin",
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'Cursive',
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey,
                  ),
                ],
              ),
            ),

            // -----------------------------
            // メッセージ部分
            // -----------------------------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 管理者メッセージ
                  _adminBubble("① 管理者：お問い合わせありがとうございます。"),
                  const SizedBox(height: 12),

                  _adminBubble("② 管理者：こちらにご入力ください。"),
                  const SizedBox(height: 12),

                  // あなたのメッセージ
                  _myBubble("あなた：はい、わかりました！"),
                  const SizedBox(height: 12),

                  _adminBubble("管理者：続けて入力どうぞ。"),
                  const SizedBox(height: 12),

                  _myBubble("あなた：〇〇について教えてください。"),
                ],
              ),
            ),

            // -----------------------------
            // キーボード風エリア
            // -----------------------------
            Container(
              height: 80,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black12),
                ),
              ),
              child: const Center(
                child: Text(
                  "キーボード",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------
  // 吹き出し（管理者）
  // --------------------------------
  Widget _adminBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(right: 40),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      ),
    );
  }

  // --------------------------------
  // 吹き出し（あなた）
  // --------------------------------
  Widget _myBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(left: 40),
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      ),
    );
  }
}
