import 'package:flutter/material.dart';

class SpeechBubble extends StatelessWidget {
  final String name;
  final String text;
  final bool isMe;

  const SpeechBubble(
      {Key? key, required this.name, required this.text, required this.isMe})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? Colors.white : Colors.white;
    final borderColor = Colors.black87;

    final bubble = Container(
      constraints:
          const BoxConstraints(minWidth: 100, maxWidth: 220, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        text.isEmpty ? ' ' : text,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
      ),
    );

    // Tail triangle
    final tail = CustomPaint(
      size: const Size(18, 12),
      painter: _TrianglePainter(color: borderColor, isLeft: !isMe),
    );

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0, left: 4, right: 4),
          child: Text(name, style: const TextStyle(fontSize: 14)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: isMe
              ? [
                  // right aligned: bubble then tail to the left-bottom
                  bubble,
                  const SizedBox(width: 4),
                  tail,
                ]
              : [
                  // left aligned: tail then bubble
                  tail,
                  const SizedBox(width: 4),
                  bubble,
                ],
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool isLeft;
  _TrianglePainter({required this.color, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
    // inner white triangle to simulate border gap
    final innerPaint = Paint()..color = Colors.white;
    final inner = Path();
    final inset = 2.0;
    if (isLeft) {
      inner.moveTo(inset, inset);
      inner.lineTo(size.width - inset, size.height / 2);
      inner.lineTo(inset, size.height - inset);
    } else {
      inner.moveTo(size.width - inset, inset);
      inner.lineTo(inset, size.height / 2);
      inner.lineTo(size.width - inset, size.height - inset);
    }
    inner.close();
    canvas.drawPath(inner, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
