import 'package:flutter/material.dart';
import 'components/speech_bubble.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Text(
                        'Whispin',
                        style: TextStyle(
                          fontSize: 32,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 2, color: Colors.black26),
                ],
              ),
            ),

            // Messages area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 12.0),
                child: ListView(
                  children: const [
                    SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SpeechBubble(
                        name: '本名A',
                        text: '',
                        isMe: false,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SpeechBubble(
                              name: '本名A',
                              text: '',
                              isMe: false,
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SpeechBubble(
                              name: 'あなた',
                              text: '',
                              isMe: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SpeechBubble(
                              name: '本名A',
                              text: '',
                              isMe: false,
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SpeechBubble(
                              name: 'あなた',
                              text: '',
                              isMe: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Separator line
            Container(height: 2, color: Colors.black26),

            // Keyboard placeholder
            Container(
              height: 180,
              color: Colors.white,
              alignment: Alignment.center,
              child: const Text(
                'キーボード',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
