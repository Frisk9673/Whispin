import 'package:flutter/material.dart';

/// チャット入力欄の共通ウィジェット。
///
/// - 汎用用途: テキスト入力 + 送信ボタンの最小構成を user/admin 双方で再利用。
/// - 依存テーマ: Material `TextField` / `IconButton` の標準テーマと `InputDecoration`。
/// - 禁止用途: 業務依存の入力制御（承認コード入力、監査用メタ情報入力など）を直接追加しない。
/// - user/admin 利用差分:
///   - user画面: 一般問い合わせ文の送信を想定し、送信前バリデーションは呼び出し側で実施。
///   - admin画面: 返信テンプレート適用や権限チェックは呼び出し側で実施し、本Widgetは入力UIに限定。
class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInputField({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "メッセージを入力"),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
