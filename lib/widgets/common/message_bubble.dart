import 'package:flutter/material.dart';

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
