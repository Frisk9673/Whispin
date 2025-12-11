import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../widgets/evaluation_dialog.dart';
import 'home_screen.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final AuthService authService;
  final ChatService chatService;
  final StorageService storageService;

  const ChatScreen({
    Key? key,
    required this.roomId,
    required this.authService,
    required this.chatService,
    required this.storageService,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  Timer? _updateTimer;
  ChatRoom? _currentRoom;
  Message? _myMessage;
  Message? _partnerMessage;
  bool _partnerHasLeft = false;

  @override
  void initState() {
    super.initState();
    _loadRoom();
    if (_currentRoom != null) {
      widget.chatService
          .startRoomTimer(_currentRoom!.id, _currentRoom!.expiresAt);
    }
    _startUpdateTimer();
  }

  void _loadRoom() {
    try {
      _currentRoom = widget.storageService.rooms.firstWhere(
        (r) => r.id == widget.roomId,
      );
      _loadMessages();
    } catch (e) {
      print('Error loading room: $e');
    }
  }

  void _loadMessages() {
    final currentUserId = widget.authService.currentUser?.id ?? '';
    final roomMessages = widget.storageService.messages
        .where((m) => m.roomId == widget.roomId)
        .toList();

    _myMessage =
        roomMessages.where((m) => m.userId == currentUserId).fold<Message?>(
              null,
              (prev, curr) =>
                  prev == null || curr.timestamp.isAfter(prev.timestamp)
                      ? curr
                      : prev,
            );

    _partnerMessage =
        roomMessages.where((m) => m.userId != currentUserId).fold<Message?>(
              null,
              (prev, curr) =>
                  prev == null || curr.timestamp.isAfter(prev.timestamp)
                      ? curr
                      : prev,
            );
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _loadRoom();

      if (_currentRoom == null) {
        timer.cancel();
        if (mounted) {
          _handleRoomDisappeared();
        }
        return;
      }

      _loadMessages();

      final currentUserId = widget.authService.currentUser?.id ?? '';
      final partnerId = _currentRoom!.id1 == currentUserId
          ? _currentRoom!.id2
          : _currentRoom!.id1;

      if ((partnerId?.isEmpty ?? true) && !_partnerHasLeft) {
        setState(() {
          _partnerHasLeft = true;
        });
        _showPartnerLeftDialog();
      }

      final now = DateTime.now();
      if (_currentRoom!.expiresAt.isBefore(now)) {
        timer.cancel();
        _handleRoomExpired();
        return;
      }

      setState(() {});
    });
  }

  void _handleRoomDisappeared() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('ルームが削除されました'),
        content: Text('このルームは削除されました。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    authService: widget.authService,
                    storageService: widget.storageService,
                  ),
                ),
                (route) => false,
              );
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatRemainingTime() {
    if (_currentRoom == null) return '0:00';

    final now = DateTime.now();
    final remaining = _currentRoom!.expiresAt.difference(now);

    if (remaining.isNegative) {
      return '0:00';
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool _canRequestExtension() {
    if (_currentRoom == null) return false;

    final now = DateTime.now();
    final remaining = _currentRoom!.expiresAt.difference(now);
    return remaining.inMinutes <= 2 &&
        _currentRoom!.extensionCount < _currentRoom!.extension;
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_messageController.text.trim().length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メッセージは100文字以内で入力してください')),
      );
      return;
    }

    await widget.chatService.sendMessage(
      widget.roomId,
      widget.authService.currentUser!.id,
      widget.authService.currentUser!.nickname,
      _messageController.text.trim(),
    );

    _messageController.clear();
    _loadMessages();
    setState(() {});
  }

  Future<void> _requestExtension() async {
    try {
      final request = await widget.chatService.requestExtension(
        widget.roomId,
        widget.authService.currentUser!.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('延長リクエストを送信しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _handleLeave() async {
    final currentUserId = widget.authService.currentUser?.id ?? '';
    await widget.chatService.leaveRoom(widget.roomId, currentUserId);

    if (mounted) {
      await _showEvaluationDialog();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            authService: widget.authService,
            storageService: widget.storageService,
          ),
        ),
        (route) => false,
      );
    }
  }

  void _handleRoomExpired() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('チャット時間終了'),
        content: Text('10分間のチャット時間が終了しました。'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _showEvaluationDialog();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    authService: widget.authService,
                    storageService: widget.storageService,
                  ),
                ),
                (route) => false,
              );
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPartnerLeftDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('相手が退出しました'),
        content: Text('退出ボタンを押してください'),
        actions: [
          TextButton(
            onPressed: _handleLeave,
            child: Text('退出する'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEvaluationDialog() async {
    final currentUserId = widget.authService.currentUser?.id ?? '';

    final rawPartnerId = (_currentRoom!.id1 == currentUserId
        ? _currentRoom!.id2
        : _currentRoom!.id1);

    final partnerId = rawPartnerId ?? '';

    if (partnerId.isEmpty) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EvaluationDialog(
        partnerId: partnerId,
        currentUserId: currentUserId,
        storageService: widget.storageService,
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoom == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoom!.topic),
        backgroundColor: Color(0xFF667EEA),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                _formatRemainingTime(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_canRequestExtension())
            IconButton(
              icon: Icon(Icons.access_time),
              onPressed: _requestExtension,
              tooltip: '延長リクエスト',
            ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _handleLeave,
            tooltip: '退出',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF667EEA).withOpacity(0.1),
                    Color(0xFF764BA2).withOpacity(0.1),
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 4,
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '相手のメッセージ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    _partnerMessage?.text ?? 'ユーザーを待っています...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: Card(
                        elevation: 4,
                        color: Colors.purple.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'あなたのメッセージ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    _myMessage?.text ?? '',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'メッセージを入力...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixText: '${_messageController.text.length}/100',
                    ),
                    maxLength: 100,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Color(0xFF667EEA),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
