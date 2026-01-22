import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/header.dart';
import '../../repositories/chat_room_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/block_repository.dart';
import '../../providers/user_provider.dart';
import '../../models/chat_room.dart';
import '../../routes/navigation_helper.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

class RoomJoinScreen extends StatefulWidget {
  const RoomJoinScreen({super.key});

  @override
  State<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends State<RoomJoinScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _roomRepository = ChatRoomRepository();
  final _userRepository = UserRepository();
  final _blockRepository = BlockRepository();

  bool _isLoading = false;
  bool _isSearching = false;
  List<ChatRoom> _searchResults = [];
  static const String _logName = 'RoomJoinScreen';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ルームを検索（topic名で検索 + ブロックフィルタ）
  Future<void> _searchRooms() async {
    final searchQuery = _searchController.text.trim();

    if (searchQuery.isEmpty) {
      context.showErrorSnackBar('ルーム名を入力してください');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      logger.section('ルーム検索開始', name: _logName);
      logger.info('検索キーワード: $searchQuery', name: _logName);

      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        context.showErrorSnackBar('ログインしてください');
        setState(() => _isSearching = false);
        return;
      }

      final currentUserEmail = currentUser.id;
      logger.info('検索ユーザー: $currentUserEmail', name: _logName);

      // ステップ1: ブロック関係を取得
      logger.start('ブロック関係を取得中...', name: _logName);

      final blockedByMe =
          await _blockRepository.findBlockedUsers(currentUserEmail);
      final blockedMe = await _blockRepository.findBlockedBy(currentUserEmail);

      final blockedUserIds = <String>{
        ...blockedByMe.map((b) => b.blockedId),
        ...blockedMe.map((b) => b.blockerId),
      };

      logger.success('ブロック関係取得: ${blockedUserIds.length}人', name: _logName);
      if (blockedUserIds.isNotEmpty) {
        logger.debug('ブロックユーザー: ${blockedUserIds.join(", ")}', name: _logName);
      }

      // ステップ2: 全ルームを取得
      logger.start('全ルーム取得中...', name: _logName);
      final allRooms = await _roomRepository.findAll();
      logger.success('全ルーム数: ${allRooms.length}件', name: _logName);

      // ステップ3: フィルタリング
      logger.start('フィルタリング中...', name: _logName);

      final now = DateTime.now();
      final filteredRooms = allRooms.where((room) {
        // 3-1. topic名で部分一致検索（大文字小文字区別なし）
        final topicLower = room.topic.toLowerCase();
        final queryLower = searchQuery.toLowerCase();
        if (!topicLower.contains(queryLower)) {
          return false;
        }

        // 3-2. 参加待ち状態でないルームは除外 ★追加
        if (!room.isWaiting) {
          logger.debug('除外: 参加待ちでない - ${room.topic}', name: _logName);
          return false;
        }

        // 3-3. アクティブなルームで期限切れの場合は除外
        if (room.isActive && now.isAfter(room.expiresAt)) {
          logger.debug('除外: 期限切れ - ${room.topic}', name: _logName);
          return false;
        }

        // 3-4. ブロック関係チェック
        final creatorId = room.id1;
        if (creatorId != null && blockedUserIds.contains(creatorId)) {
          logger.debug('除外: ブロック関係 - ${room.topic} (作成者: $creatorId)',
              name: _logName);
          return false;
        }

        return true;
      }).toList();

      // ステップ4: 作成日時でソート（新しい順）
      filteredRooms.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      setState(() {
        _searchResults = filteredRooms;
        _isSearching = false;
      });

      logger.success('検索完了: ${_searchResults.length}件', name: _logName);

      if (_searchResults.isEmpty) {
        context.showInfoSnackBar('該当するルームが見つかりませんでした');
      }

      logger.section('ルーム検索終了', name: _logName);
    } catch (e, stack) {
      logger.error('検索エラー: $e', name: _logName, error: e, stackTrace: stack);
      setState(() => _isSearching = false);
      context.showErrorSnackBar('検索に失敗しました: $e');
    }
  }

  /// ルームに参加
  Future<void> _joinRoom(ChatRoom room) async {
    logger.section('ルーム参加処理開始', name: _logName);
    logger.info('参加先: ${room.topic} (${room.id})', name: _logName);

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        context.showErrorSnackBar('ログインしてください');
        setState(() => _isLoading = false);
        return;
      }

      final currentUserEmail = currentUser.id;

      // Repository経由でルームに参加
      logger.start('Repository経由でルーム参加中...', name: _logName);
      await _roomRepository.joinRoom(room.id, currentUserEmail);
      logger.success('ルーム参加成功', name: _logName);

      // ユーザーのルーム参加回数を更新
      try {
        await _userRepository.incrementRoomCount(currentUserEmail);
        logger.success('ルーム参加回数更新完了', name: _logName);
      } catch (e) {
        logger.warning('ルーム参加回数更新失敗: $e', name: _logName);
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      context.showSuccessSnackBar(
        'ルーム "${room.topic}" に参加しました\nチャットが開始されました（${AppConstants.defaultChatDurationMinutes}分間）',
      );

      // チャット画面へ遷移
      await NavigationHelper.toChat(
        context,
        roomId: room.id,
        authService: context.read<AuthService>(),
        chatService: context.read<ChatService>(),
        storageService: context.read<StorageService>(),
      );

      logger.section('ルーム参加処理完了', name: _logName);
    } catch (e, stack) {
      logger.error('参加エラー: $e', name: _logName, error: e, stackTrace: stack);
      setState(() => _isLoading = false);
      context.showErrorSnackBar('参加に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: '部屋を検索',
        showNotifications: true,
        showProfile: true,
        showPremiumBadge: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 検索ヘッダー
          Container(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 検索バー
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        enabled: !_isLoading && !_isSearching,
                        decoration: InputDecoration(
                          labelText: 'ルーム名で検索',
                          hintText: '例: 雑談、趣味の話、など',
                          prefixIcon:
                              Icon(Icons.search, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius,
                            ),
                          ),
                        ),
                        style: AppTextStyles.bodyLarge,
                        onSubmitted: (_) => _searchRooms(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed:
                          (_isLoading || _isSearching) ? null : _searchRooms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius,
                          ),
                        ),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '検索',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ヒントテキスト
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ルーム名で検索できます（部分一致）',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 検索結果リスト
          Expanded(
            child: _isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          '検索中...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'ルーム名を入力して検索してください'
                                  : '該当するルームが見つかりませんでした',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(AppConstants.defaultPadding),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final room = _searchResults[index];
                          return _buildRoomCard(room);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// ルームカードを構築
  Widget _buildRoomCard(ChatRoom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: _isLoading ? null : () => _joinRoom(room),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ルーム名
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chat_bubble,
                      color: AppColors.textWhite,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      room.topic,
                      style: AppTextStyles.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ステータス
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    '参加待ち',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 参加ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _joinRoom(room),
                  icon: const Icon(Icons.login),
                  label: const Text('このルームに参加'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
