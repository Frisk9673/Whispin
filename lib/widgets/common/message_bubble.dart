import 'package:flutter/material.dart';

/// チャット表示用の吹き出しウィジェット。
///
/// - 汎用用途: 1メッセージ単位の左右寄せ・背景色分岐を伴うシンプル表示。
/// - 依存テーマ: Material `Colors` の固定色（`grey[300]` / `blue[200]`）前提。
/// - 禁止用途: 業務依存ステータス（承認状態、優先度、SLA警告など）の表示を直接埋め込まない。
/// - user/admin 利用差分:
///   - user画面: `isAdmin=true` を「相手（管理者）発言」として左寄せ表示。
///   - admin画面: `isAdmin=true` を「自分（管理者）発言」として扱う場合は、呼び出し側で意味を統一する。
class MessageBubble extends StatelessWidget {
  final bool isAdmin;
  final String text;

  const MessageBubble({
    super.key,
    required this.isAdmin,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.grey[300] : Colors.blue[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }
}
