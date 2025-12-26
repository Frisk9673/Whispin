import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../models/chat_room.dart';
import '../../widgets/evaluation_dialog.dart';
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
    } catch (e) {
      print('❌ [ChatScreen] Error loading room: $e');
    }
  }

  // ===== コメント取得ロジック =====

  /// 自分のコメントを取得
  String _getMyComment() {
    if (_currentRoom == null) return '';

    final currentUserId = widget.authService.currentUser?.id ?? '';

    if (_currentRoom!.id1 == currentUserId) {
      return _currentRoom!.comment1 ?? '';
    } else if (_currentRoom!.id2 == currentUserId) {
      return _currentRoom!.comment2 ?? '';
    }

    return '';
  }

  /// 相手のコメントを取得
  String _getPartnerComment() {
    if (_currentRoom == null) return 'ユーザーを待っています...';

    final currentUserId = widget.authService.currentUser?.id ?? '';

    if (_currentRoom!.id1 == currentUserId) {
      // 自分が id1 なら、相手は id2
      return _currentRoom!.comment2 ?? 'ユーザーを待っています...';
    } else if (_currentRoom!.id2 == currentUserId) {
      // 自分が id2 なら、相手は id1
      return _currentRoom!.comment1 ?? 'ユーザーを待っています...';
    }

    return 'ユーザーを待っています...';
  }

  // ===== 更新タイマー =====

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

      // 🔧 修正: startedAt が遠い未来 = まだチャット開始していない(待機中)
      final isChatStarted = _currentRoom!.startedAt.isBefore(
        DateTime.now().add(Duration(days: 300))
      );

      if (!isChatStarted) {
        // チャット開始前(待機中)は退出監視しない
        setState(() {});
        return;
      }

      // 🔧 ここからはチャット開始後の処理
      final currentUserId = widget.authService.currentUser?.id ?? '';
      final partnerId = _currentRoom!.id1 == currentUserId
          ? _currentRoom!.id2
          : _currentRoom!.id1;

      // 相手が退出したかチェック
      if ((partnerId?.isEmpty ?? true) && !_partnerHasLeft) {
        setState(() {
          _partnerHasLeft = true;
        });
        _showPartnerLeftDialog();
      }

      // 時間切れチェック
      final now = DateTime.now();
      if (_currentRoom!.expiresAt.isBefore(now)) {
        timer.cancel();
        _handleRoomExpired();
        return;
      }

      setState(() {});
    });
  }

  // ===== ルーム状態ハンドラー =====

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

  // ===== タイマー関連 =====

  String _formatRemainingTime() {
    if (_currentRoom == null) return '待機中';

    // チャット開始前(待機中)かチェック
    final isChatStarted = _currentRoom!.startedAt.isBefore(
      DateTime.now().add(Duration(days: 300))
    );

    if (!isChatStarted) {
      return '待機中';
    }

    // チャット開始後は残り時間を表示
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

    // チャット開始前は延長ボタンを表示しない
    final isChatStarted = _currentRoom!.startedAt.isBefore(
      DateTime.now().add(Duration(days: 300))
    );

    if (!isChatStarted) return false;

    final now = DateTime.now();
    final remaining = _currentRoom!.expiresAt.difference(now);
    return remaining.inMinutes <= 2 &&
        _currentRoom!.extensionCount < _currentRoom!.extension;
  }

  // ===== メッセージ送信 =====

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_messageController.text.trim().length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メッセージは100文字以内で入力してください')),
      );
      return;
    }

    try {
      // ChatService.sendComment() を使用
      await widget.chatService.sendComment(
        widget.roomId,
        widget.authService.currentUser!.id,
        _messageController.text.trim(),
      );

      _messageController.clear();
      _loadRoom(); // ルーム情報を再読み込み
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('送信エラー: $e')),
      );
    }
  }

  // ===== 延長リクエスト =====

  Future<void> _requestExtension() async {
    try {
      await widget.chatService.requestExtension(
        widget.roomId,
        widget.authService.currentUser!.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('延長リクエストを送信しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  // ===== 退出処理 =====

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

  // ===== 評価ダイアログ =====

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

  // ===== クリーンアップ =====

  @override
  void dispose() {
    _updateTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    if (_currentRoom == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // チャット開始前かチェック
    final isChatStarted = _currentRoom!.startedAt.isBefore(
      DateTime.now().add(Duration(days: 300))
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoom!.topic),
        backgroundColor: Color(0xFF667EEA),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          // タイマー表示（待機中は「待機中」と表示）
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                _formatRemainingTime(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  // 待機中は色を変える（オプション）
                  color: isChatStarted ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ),
          // 延長ボタン（チャット開始後かつ条件を満たす場合のみ表示）
          if (_canRequestExtension())
            IconButton(
              icon: Icon(Icons.access_time),
              onPressed: _requestExtension,
              tooltip: '延長リクエスト',
            ),
          // 退出ボタン
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _handleLeave,
            tooltip: '退出',
          ),
        ],
      ),
      body: Column(
        children: [
          // 待機中メッセージを表示（オプション）
          if (!isChatStarted)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.orange.shade700),
                  SizedBox(width: 8),
                  Text(
                    '相手の参加を待っています...',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
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
                    // 相手のメッセージパネル
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
                                    _getPartnerComment(),
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

                    // 自分のメッセージパネル
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
                                    _getMyComment(),
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

          // メッセージ入力欄
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