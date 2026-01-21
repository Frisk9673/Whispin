import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ 追加
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../providers/user_provider.dart'; // ✅ 追加
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
  String? _partnerUserId;
  static const String _logName = 'ChatScreen';

  // ✅ 修正: 現在のユーザーIDを確実に取得するヘルパーメソッド
  String _getCurrentUserId() {
    // 1. UserProviderから取得を試みる（最優先）
    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.currentUser?.id;
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }
    } catch (e) {
      logger.warning('UserProvider取得失敗: $e', name: _logName);
    }

    logger.error('ユーザーIDが取得できません', name: _logName);
    return '';
  }

  @override
  void initState() {
    super.initState();
    
    // ✅ 追加: ユーザーID取得確認
    final userId = _getCurrentUserId();
    logger.info('初期化時のユーザーID: $userId', name: _logName);
    
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
      
      final myId = _getCurrentUserId();

      if (_partnerUserId == null && _currentRoom != null) {
        _partnerUserId =
          _currentRoom!.id1 == myId ? _currentRoom!.id2 : _currentRoom!.id1;
      }
    } catch (e) {
      logger.error('ルーム読み込みエラー: $e', name: _logName, error: e);
    }
  }

  // ===== コメント取得ロジック =====

  String _getMyComment() {
    if (_currentRoom == null) return '';

    final currentUserId = _getCurrentUserId(); // ✅ 修正

    if (_currentRoom!.id1 == currentUserId) {
      return _currentRoom!.comment1 ?? '';
    } else if (_currentRoom!.id2 == currentUserId) {
      return _currentRoom!.comment2 ?? '';
    }

    return '';
  }

  String _getPartnerComment() {
    if (_currentRoom == null) return AppConstants.waitingForUser;

    final currentUserId = _getCurrentUserId(); // ✅ 修正

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
      final currentUserId = _getCurrentUserId(); // ✅ 修正
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
    context.showCustomDialog(
      barrierDismissible: false,
      child: AlertDialog(
        title: const Text('ルームが削除されました'),
        content: const Text('このルームは削除されました。'),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
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
              context.pop();
              await _showEvaluationDialog();
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
            onPressed: () async {
              Navigator.of(context).pop();
              await _handleLeave();
            },
            child: const Text('退出する'),
          ),
        ],
      ),
    );
  }

  // ===== タイマー関連 =====

  String _formatRemainingTime() {
    if (_currentRoom == null) return AppConstants.waitingStatus;

    final isChatStarted = _currentRoom!.startedAt.isBefore(
      DateTime.now().add(const Duration(days: 300))
    );

    if (!isChatStarted) {
      return AppConstants.waitingStatus;
    }

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
      context.showWarningSnackBar(
        'メッセージは${AppConstants.messageMaxLength}文字以内で入力してください'
      );
      return;
    }

    final currentUserId = _getCurrentUserId(); // ✅ 修正
    
    // ✅ 追加: ユーザーID検証
    if (currentUserId.isEmpty) {
      logger.error('メッセージ送信失敗: ユーザーIDが空', name: _logName);
      context.showErrorSnackBar('ユーザー情報の取得に失敗しました');
      return;
    }

    logger.debug('メッセージ送信: userId=$currentUserId', name: _logName);

    try {
      await widget.chatService.sendComment(
        widget.roomId,
        currentUserId,
        _messageController.text.trim(),
      );

      _messageController.clear();
      _loadRoom();
      setState(() {});
      
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('送信エラー: $e');
    }
  }

  // ===== 延長リクエスト =====

  Future<void> _requestExtension() async {
    final currentUserId = _getCurrentUserId(); // ✅ 修正
    
    // ✅ 追加: ユーザーID検証
    if (currentUserId.isEmpty) {
      logger.error('延長リクエスト失敗: ユーザーIDが空', name: _logName);
      context.showErrorSnackBar('ユーザー情報の取得に失敗しました');
      return;
    }

    try {
      await widget.chatService.requestExtension(
        widget.roomId,
        currentUserId,
      );

      if (!mounted) return;
      context.showSuccessSnackBar('延長リクエストを送信しました');
      
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('エラー: $e');
    }
  }

  // ===== 退出処理 =====

  Future<void> _handleLeave() async {
    final currentUserId = _getCurrentUserId(); // ✅ 修正
    
    // ✅ 追加: ユーザーID検証
    if (currentUserId.isEmpty) {
      logger.error('退出処理失敗: ユーザーIDが空', name: _logName);
      context.showErrorSnackBar('ユーザー情報の取得に失敗しました');
      return;
    }

    logger.info('退出処理: userId=$currentUserId, roomId=${widget.roomId}', name: _logName);

    // ✅ 修正: 評価ダイアログを先に表示してから退出処理
    if (mounted) {
      await _showEvaluationDialog();
      
      // 評価ダイアログ後に退出処理
      await widget.chatService.leaveRoom(widget.roomId, currentUserId);
      
      if (mounted) {
        NavigationHelper.toHome(
          context,
          authService: widget.authService,
          storageService: widget.storageService,
        );
      }
    }
  }

  // ===== 評価ダイアログ =====

  Future<void> _showEvaluationDialog() async {
    final currentUserId = _getCurrentUserId();

    if (_partnerUserId == null || _partnerUserId!.isEmpty) {
      logger.warning('評価ダイアログ: パートナーIDなし', name: _logName);
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EvaluationDialog(
        partnerId: _partnerUserId!,
        currentUserId: currentUserId,
        storageService: widget.storageService,
      ),
    );
    logger.info('評価ダイアログ閉じた', name: _logName);
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
          if (_canRequestExtension())
            IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: _requestExtension,
              tooltip: '延長リクエスト',
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleLeave,
            tooltip: '退出',
          ),
        ],
      ),
      body: Column(
        children: [
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