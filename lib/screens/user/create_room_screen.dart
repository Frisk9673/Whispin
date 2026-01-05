import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../constants/app_constants.dart';
import 'chat_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  final AuthService authService;
  final ChatService chatService;
  final StorageService storageService;

  const CreateRoomScreen({
    Key? key,
    required this.authService,
    required this.chatService,
    required this.storageService,
  }) : super(key: key);

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _topicController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateRoom() async {
    final topic = _topicController.text.trim();

    if (topic.isEmpty) {
      setState(() {
        _errorMessage = 'ルーム名を入力してください';
      });
      return;
    }

    if (topic.length > AppConstants.roomNameMaxLength) {
      setState(() {
        _errorMessage = 'ルーム名は${AppConstants.roomNameMaxLength}文字以内で入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = widget.authService.currentUser?.id ?? '';
      final room = await widget.chatService.createRoom(topic, currentUserId);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              roomId: room.id,
              authService: widget.authService,
              chatService: widget.chatService,
              storageService: widget.storageService,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ルーム作成に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ルーム作成'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF667EEA).withOpacity(0.1),
              const Color(0xFF764BA2).withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.add_circle_outline,
                  size: 80,
                  color: Color(0xFF667EEA),
                ),
                const SizedBox(height: 24),
                Text(
                  '新しいルームを作成',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF667EEA),
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Card(
                  elevation: AppConstants.cardElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.defaultPadding - 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _topicController,
                          decoration: InputDecoration(
                            labelText: 'ルーム名',
                            hintText: 'チャットのテーマを入力',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                            ),
                            prefixIcon: const Icon(Icons.title),
                            counterText: '${_topicController.text.length}/${AppConstants.roomNameMaxLength}',
                          ),
                          maxLength: AppConstants.roomNameMaxLength,
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade900),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleCreateRoom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'ルームを作成',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'ルーム情報',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• 最大2人まで参加可能\n'
                          '• ${AppConstants.defaultChatDurationMinutes}分間のチャット時間\n'
                          '• 残り${AppConstants.extensionRequestThresholdMinutes}分以下で延長リクエスト可能\n'
                          '• 両者退出で自動削除',
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}