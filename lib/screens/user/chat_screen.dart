import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../models/chat_room.dart';
import '../../widgets/evaluation_dialog.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/datetime_extensions.dart';
import '../../utils/app_logger.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final AuthService authService;
  final ChatService chatService;
  final StorageService storageService;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.authService,
    required this.chatService,
    required this.storageService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  Timer? _updateTimer;
  ChatRoom? _currentRoom;
  bool _partnerHasLeft = false;
  static const String _logName = 'ChatScreen';

  @override
  void initState() {
    super.initState();
    _loadRoom();
    if (_currentRoom != null) {
      widget.chatService.startRoomTimer(_currentRoom!.id, _currentRoom!.expiresAt);
    }
    _startUpdateTimer();
  }

  void _loadRoom() {
    try {
      _currentRoom = widget.storageService.rooms.firstWhere(
        (r) => r.id == widget.roomId,
      );
    } catch (e) {
      logger.error('ルーム読み込みエラー: $e', name: _logName, error: e);
    }
  }

  // ===== コメント取得ロジック =====

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

  String _getPartnerComment() {
    if (_currentRoom == null) return AppConstants.waitingForUser;

    final currentUserId = widget.authService.currentUser?.id ?? '';

    if (_currentRoom!.id1 == currentUserId) {
      return _currentRoom!.comment2 ?? AppConstants.waitingForUser;
    } else if (_currentRoom!.id2 == currentUserId) {
      return _currentRoom!.comment1 ?? AppConstants.waitingForUser;
    }

    return AppConstants.waitingForUser;
  }

  // ===== 更新タイマー =====

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

      // チャット開始チェック
      final isChatStarted = _currentRoom!.startedAt.isBefore(
        DateTime.now().add(const Duration(days: 300))
      );

      if (!isChatStarted) {
        setState(() {});
        return;
      }

      // 相手の退出チェック
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

      // 時間切れチェック
      if (_currentRoom!.expiresAt.isBefore(DateTime.now())) {
        timer.cancel();
        _handleRoomExpired();
        return;
      }

      setState(() {});
    });
  }

  // ===== ルーム状態ハンドラー =====

  void _handleRoomDisappeared() {
    // 🔧 拡張メソッド使用
    context.showCustomDialog(
      barrierDismissible: false,
      child: AlertDialog(
        title: const Text('ルームが削除されました'),
        content: const Text('このルームは削除されました。'),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // ダイアログを閉じる
              // 🔧 NavigationHelper使用
              NavigationHelper.toHome(
                context,
                authService: widget.authService,
                storageService: widget.storageService,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleRoomExpired() {
    if (!mounted) return;

    // 🔧 拡張メソッド使用
    context.showCustomDialog(
      barrierDismissible: false,
      child: AlertDialog(
        title: const Text('チャット時間終了'),
        content: Text(
          '${AppConstants.defaultChatDurationMinutes}分間のチャット時間が終了しました。'
        ),
        actions: [
          TextButton(
            onPressed: () async {
              context.pop(); // ダイアログを閉じる
              await _showEvaluationDialog();
              // 🔧 NavigationHelper使用
              NavigationHelper.toHome(
                context,
                authService: widget.authService,
                storageService: widget.storageService,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPartnerLeftDialog() {
    context.showCustomDialog(
      barrierDismissible: false,
      child: AlertDialog(
        title: const Text('相手が退出しました'),
        content: const Text('退出ボタンを押してください'),
        actions: [
          TextButton(
            onPressed: _handleLeave,
            child: const Text('退出する'),
          ),
        ],
      ),
    );
  }

  // ===== タイマー関連 =====

  String _formatRemainingTime() {
    if (_currentRoom == null) return AppConstants.waitingStatus;

    // チャット開始前チェック
    final isChatStarted = _currentRoom!.startedAt.isBefore(
      DateTime.now().add(const Duration(days: 300))
    );

    if (!isChatStarted) {
      return AppConstants.waitingStatus;
    }

    // 🔧 DateTime拡張メソッド使用
    final remaining = _currentRoom!.expiresAt.timeUntil(DateTime.now());

    if (remaining.isNegative) {
      return '0:00';
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool _canRequestExtension() {
    if (_currentRoom == null) return false;

    final isChatStarted = _currentRoom!.startedAt.isBefore(
      DateTime.now().add(const Duration(days: 300))
    );

    if (!isChatStarted) return false;

    final remaining = _currentRoom!.expiresAt.timeUntil(DateTime.now());
    return remaining.inMinutes <= AppConstants.extensionRequestThresholdMinutes &&
        _currentRoom!.extensionCount < _currentRoom!.extension;
  }

  // ===== メッセージ送信 =====

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    if (_messageController.text.trim().length > AppConstants.messageMaxLength) {
      // 🔧 拡張メソッド使用
      context.showWarningSnackBar(
        'メッセージは${AppConstants.messageMaxLength}文字以内で入力してください'
      );
      return;
    }

    try {
      await widget.chatService.sendComment(
        widget.roomId,
        widget.authService.currentUser!.id,
        _messageController.text.trim(),
      );

      _messageController.clear();
      _loadRoom();
      setState(() {});
      
    } catch (e) {
      if (!mounted) return;
      // 🔧 拡張メソッド使用
      context.showErrorSnackBar('送信エラー: $e');
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
      // 🔧 拡張メソッド使用
      context.showSuccessSnackBar('延長リクエストを送信しました');
      
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('エラー: $e');
    }
  }

  // ===== 退出処理 =====

  Future<void> _handleLeave() async {
    final currentUserId = widget.authService.currentUser?.id ?? '';
    await widget.chatService.leaveRoom(widget.roomId, currentUserId);

    if (mounted) {
      await _showEvaluationDialog();
      // 🔧 NavigationHelper使用
      NavigationHelper.toHome(
        context,
        authService: widget.authService,
        storageService: widget.storageService,
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

    // 🔧 拡張メソッド使用
    await context.showCustomDialog(
      barrierDismissible: false,
      child: EvaluationDialog(
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
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // チャット開始前チェック
    final isChatStarted = _currentRoom!.startedAt.isBefore(
      DateTime.now().add(const Duration(days: 300))
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoom!.topic),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        automaticallyImplyLeading: false,
        actions: [
          // タイマー表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                _formatRemainingTime(),
                style: AppTextStyles.titleMedium.copyWith(
                  color: isChatStarted 
                      ? AppColors.textWhite 
                      : AppColors.textWhite.withOpacity(0.7),
                ),
              ),
            ),
          ),
          // 延長ボタン
          if (_canRequestExtension())
            IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: _requestExtension,
              tooltip: '延長リクエスト',
            ),
          // 退出ボタン
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleLeave,
            tooltip: '退出',
          ),
        ],
      ),
      body: Column(
        children: [
          // 待機中メッセージ
          if (!isChatStarted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.warning.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    '相手の参加を待っています...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.warning,
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
                    AppColors.backgroundLight,
                    AppColors.backgroundSecondary,
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    // 相手のメッセージパネル
                    Expanded(
                      child: Card(
                        elevation: AppConstants.cardElevation,
                        color: AppColors.bubbleAdmin,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius,
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(AppConstants.defaultPadding),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '相手のメッセージ',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    _getPartnerComment(),
                                    style: AppTextStyles.bodyLarge,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 自分のメッセージパネル
                    Expanded(
                      child: Card(
                        elevation: AppConstants.cardElevation,
                        color: AppColors.primary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius,
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(AppConstants.defaultPadding),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'あなたのメッセージ',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    _getMyComment(),
                                    style: AppTextStyles.bodyLarge,
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
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixText: '${_messageController.text.length}/${AppConstants.messageMaxLength}',
                    ),
                    maxLength: AppConstants.messageMaxLength,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (_) => _sendMessage(),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: Icon(Icons.send, color: AppColors.textWhite),
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