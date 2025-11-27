import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/message_input_field.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _service = ChatService();

  @override
  void initState() {
    super.initState();
    Provider.of<ChatProvider>(context, listen: false).loadChat();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);

    if (provider.loading || provider.chatId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("お問い合わせ")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _service.messageStream(provider.chatId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: messages.map((msg) {
                    return MessageBubble(
                      isAdmin: msg.isAdmin,
                      text: msg.text,
                    );
                  }).toList(),
                );
              },
            ),
          ),

          MessageInputField(
            controller: _controller,
            onSend: () {
              provider.send(_controller.text);
              _controller.clear();
            },
          ),
        ],
      ),
    );
  }
}
