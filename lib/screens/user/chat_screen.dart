import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whispin/models/extension_request.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../services/invitation_service.dart';
import '../../providers/user_provider.dart';
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
  late InvitationService _invitationService;
  List<ExtensionRequest> _pendingExtensionRequests = [];
  static const String _logName = 'ChatScreen';

  String _getCurrentUserId() {
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
    _invitationService = InvitationService(widget.storageService);

    final userId = _getCurrentUserId();
    logger.info('初期化時のユーザーID: $userId', name: _logName);

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

      final myId = _getCurrentUserId();

      if (_partnerUserId == null && _currentRoom != null) {
        _partnerUserId =
            _currentRoom!.id1 == myId ? _currentRoom!.id2 : _currentRoom!.id1;
      }
    } catch (e) {
      logger.error('ルーム読み込みエラー: $e', name: _logName, error: e);
    }
  }

  // ===== 招待機能（InvitationServiceに移譲） =====

  /// フレンド招待ダイアログを表示
  Future<void> _showInviteFriendDialog() async {
    final currentUserId = _getCurrentUserId();

    await _invitationService.showInviteFriendDialog(
      context: context,
      roomId: widget.roomId,
      currentUserId: currentUserId,
    );
  }

  // ===== コメント取得ロジック =====

  String _getMyComment() {
    if (_currentRoom == null) return '';

    final currentUserId = _getCurrentUserId();

    if (_currentRoom!.id1 == currentUserId) {
      return _currentRoom!.comment1 ?? '';
    } else if (_currentRoom!.id2 == currentUserId) {
      return _currentRoom!.comment2 ?? '';
    }

    return '';
  }

  String _getPartnerComment() {
    if (_currentRoom == null) return AppConstants.waitingForUser;

    final currentUserId = _getCurrentUserId();

    if (_currentRoom!.id1 == currentUserId) {
      return _currentRoom!.comment2 ?? AppConstants.waitingForUser;
    } else if (_currentRoom!.id2 == currentUserId) {
      return _currentRoom!.comment1 ?? AppConstants.waitingForUser;
    }

    return AppConstants.waitingForUser;
  }

  // ===== 延長リクエスト確認 =====

  void _checkExtensionRequests() {
    if (_currentRoom == null) return;

    final currentUserId = _getCurrentUserId();
    if (currentUserId.isEmpty) return;

    final newRequests = widget.storageService.extensionRequests
        .where((req) =>
            req.roomId == widget.roomId &&
            req.status == AppConstants.extensionStatusPending &&
            req.requesterId != currentUserId)
        .toList();

    if (newRequests.isNotEmpty &&
        newRequests.length != _pendingExtensionRequests.length) {
      _pendingExtensionRequests = newRequests;

      final latestRequest = newRequests.last;
      _showExtensionRequestDialog(latestRequest);
    } else if (newRequests.isEmpty) {
      _pendingExtensionRequests.clear();
    }
  }

  Future<void> _showExtensionRequestDialog(ExtensionRequest request) async {
    logger.section('延長リクエストダイアログ表示', name: _logName);
    logger.info('requestId: ${request.id}', name: _logName);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('延長リクエスト'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '相手がチャット時間の延長を希望しています。',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '延長すると${AppConstants.extensionDurationMinutes}分間追加されます',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '拒否',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('承認'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _approveExtension(request.id);
    } else if (result == false) {
      await _rejectExtension(request.id);
    }
  }

  Future<void> _approveExtension(String requestId) async {
    logger.section('延長承認処理開始', name: _logName);
    logger.info('requestId: $requestId', name: _logName);

    try {
      await widget.chatService.approveExtension(requestId);

      if (!mounted) return;

      context.showSuccessSnackBar(
          'チャット時間が${AppConstants.extensionDurationMinutes}分延長されました');

      _loadRoom();
      setState(() {});

      logger.success('延長承認完了', name: _logName);
    } catch (e, stack) {
      logger.error('延長承認エラー: $e', name: _logName, error: e, stackTrace: stack);

      if (!mounted) return;
      context.showErrorSnackBar('延長の承認に失敗しました: $e');
    }
  }

  Future<void> _rejectExtension(String requestId) async {
    logger.section('延長拒否処理開始', name: _logName);
    logger.info('requestId: $requestId', name: _logName);

    try {
      await widget.chatService.rejectExtension(requestId);

      if (!mounted) return;

      context.showInfoSnackBar('延長リクエストを拒否しました');

      logger.success('延長拒否完了', name: _logName);
    } catch (e, stack) {
      logger.error('延長拒否エラー: $e', name: _logName, error: e, stackTrace: stack);

      if (!mounted) return;
      context.showErrorSnackBar('延長の拒否に失敗しました: $e');
    }
  }

  // ===== 更新タイマー =====

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _loadRoom();

      _checkExtensionRequests();

      if (_currentRoom == null) {
        timer.cancel();
        if (mounted) {
          _handleRoomDisappeared();
        }
        return;
      }

      final isChatStarted = _currentRoom!.startedAt
          .isBefore(DateTime.now().add(const Duration(days: 300)));

      if (!isChatStarted) {
        setState(() {});
        return;
      }

      final currentUserId = _getCurrentUserId();
      final partnerId = _currentRoom!.id1 == currentUserId
          ? _currentRoom!.id2
          : _currentRoom!.id1;

      if ((partnerId?.isEmpty ?? true) && !_partnerHasLeft) {
        setState(() {
          _partnerHasLeft = true;
        });
        _showPartnerLeftDialog();
      }

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

  Future<void> _handleRoomExpired() async {
    if (!mounted) return;

    logger.section('チャット時間終了処理開始', name: _logName);

    final isPrivateRoom = _currentRoom?.private ?? false;

    // ===== 1. まず時間切れダイアログを表示 =====
    await context.showCustomDialog(
      barrierDismissible: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('チャット時間終了'),
          ],
        ),
        content: Text(
          '時間切れです。',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              context.pop(); // ダイアログを閉じる

              if (!mounted) return;

              // ===== 2. 評価（Publicルームのみ） =====
              if (!isPrivateRoom) {
                logger.info('評価ダイアログを表示します', name: _logName);
                await _showEvaluationDialog();
              }

              if (!mounted) return;

              // ===== 3. ホームへ =====
              logger.info('ホーム画面へ遷移', name: _logName);
              await NavigationHelper.toHome(
                context,
                authService: widget.authService,
                storageService: widget.storageService,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              '退出する',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    logger.section('チャット時間終了処理完了', name: _logName);
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

    final isChatStarted = _currentRoom!.startedAt
        .isBefore(DateTime.now().add(const Duration(days: 300)));

    if (!isChatStarted) {
      return AppConstants.waitingStatus;
    }

    final remaining = DateTime.now().timeUntil(_currentRoom!.expiresAt);

    if (remaining.isNegative) {
      return '0:00';
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool _canRequestExtension() {
    if (_currentRoom == null) return false;

    final isChatStarted = _currentRoom!.startedAt
        .isBefore(DateTime.now().add(const Duration(days: 300)));

    if (!isChatStarted) return false;

    final remaining = DateTime.now().timeUntil(_currentRoom!.expiresAt);
    return remaining.inMinutes <=
            AppConstants.extensionRequestThresholdMinutes &&
        _currentRoom!.extensionCount < _currentRoom!.extension;
  }

  // ===== メッセージ送信 =====

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (_messageController.text.trim().length > AppConstants.messageMaxLength) {
      context.showWarningSnackBar(
          'メッセージは${AppConstants.messageMaxLength}文字以内で入力してください');
      return;
    }

    final currentUserId = _getCurrentUserId();

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
    final currentUserId = _getCurrentUserId();

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
    final currentUserId = _getCurrentUserId();

    if (currentUserId.isEmpty) {
      logger.error('退出処理失敗: ユーザーIDが空', name: _logName);
      context.showErrorSnackBar('ユーザー情報の取得に失敗しました');
      return;
    }

    logger.info('退出処理: userId=$currentUserId, roomId=${widget.roomId}',
        name: _logName);

    if (mounted) {
      final isPrivateRoom = _currentRoom?.private ?? false;

      if (!isPrivateRoom) {
        await _showEvaluationDialog();
      } else {
        logger.info('Privateルームのため評価ダイアログをスキップ', name: _logName);
      }

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

    final isChatStarted = _currentRoom!.startedAt
        .isBefore(DateTime.now().add(const Duration(days: 300)));

    final currentUserId = _getCurrentUserId();
    final partnerId = _currentRoom!.id1 == currentUserId
        ? _currentRoom!.id2
        : _currentRoom!.id1;
    final hasPartner = partnerId != null && partnerId.isNotEmpty;

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
                      child: GestureDetector(
                        onTap: !hasPartner && _currentRoom!.private
                            ? _showInviteFriendDialog
                            : null,
                        child: Card(
                          elevation: AppConstants.cardElevation,
                          color: AppColors.bubbleAdmin,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius,
                            ),
                            side: !hasPartner && _currentRoom!.private
                                ? BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                          child: Container(
                            padding:
                                EdgeInsets.all(AppConstants.defaultPadding),
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '相手のメッセージ',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.info,
                                      ),
                                    ),
                                    if (!hasPartner &&
                                        _currentRoom!.private) ...[
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.person_add,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'タップして招待',
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Center(
                                    child: !hasPartner && _currentRoom!.private
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.person_add,
                                                size: 48,
                                                color: AppColors.primary
                                                    .withOpacity(0.5),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'フレンドを招待',
                                                style: AppTextStyles.titleMedium
                                                    .copyWith(
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'ここをタップして招待を送信',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          )
                                        : SingleChildScrollView(
                                            child: Text(
                                              _getPartnerComment(),
                                              style: AppTextStyles.bodyLarge,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
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
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _getMyComment(),
                                      style: AppTextStyles.bodyLarge,
                                    ),
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
                      suffixText:
                          '${_messageController.text.length}/${AppConstants.messageMaxLength}',
                    ),
                    maxLength: AppConstants.messageMaxLength,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
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
