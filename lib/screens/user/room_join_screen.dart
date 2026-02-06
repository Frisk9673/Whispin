import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whispin/repositories/user_repository.dart';
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
import '../../constants/responsive.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

/// レスポンシブ対応のルーム参加画面（ダークモード対応版）
class RoomJoinScreen extends StatefulWidget {
  const RoomJoinScreen({super.key});

  @override
  State<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends State<RoomJoinScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _blockRepository = BlockRepository();

  bool _isLoading = false;
  bool _isSearching = false;
  List<ChatRoom> _searchResults = [];
  static const String _logName = 'RoomJoinScreen';

  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = context.read<ChatService>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchRooms() async {
    final searchQuery = _searchController.text.trim();

    if (searchQuery.isEmpty) {
      context.showErrorSnackBar('ルーム名を入力してください');
      return;
    }

    // キーボードを閉じる
    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      logger.section('ルーム検索開始', name: _logName);

      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        context.showErrorSnackBar('ログインしてください');
        setState(() => _isSearching = false);
        return;
      }

      final currentUserEmail = currentUser.id;

      logger.start('ChatService.searchRooms() 実行中...', name: _logName);

      final results = await _chatService.searchRooms(
        searchQuery: searchQuery,
        currentUserId: currentUserEmail,
        blockRepository: _blockRepository,
      );

      setState(() {
        _searchResults = results;
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

      logger.start('ChatService.joinRoomWithUserUpdate() 実行中...',
          name: _logName);

      await _chatService.joinRoomWithUserUpdate(
        roomId: room.id,
        currentUserId: currentUserEmail,
        userRepository: context.read<UserRepository>(),
      );

      logger.success('ルーム参加成功', name: _logName);

      setState(() => _isLoading = false);

      if (!mounted) return;

      context.showSuccessSnackBar(
        'ルーム "${room.topic}" に参加しました\nチャットが開始されました（${AppConstants.defaultChatDurationMinutes}分間）',
      );

      await NavigationHelper.toChat(
        context,
        roomId: room.id,
        authService: context.read<AuthService>(),
        chatService: _chatService,
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
    final isMobile = context.isMobile;
    final padding = context.responsiveHorizontalPadding;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: Column(
        children: [
          // 検索ヘッダー
          _buildSearchHeader(context, isMobile, padding, isDark),

          // 検索結果リスト
          Expanded(
            child: _buildSearchResults(context, isMobile, padding, isDark),
          ),
        ],
      ),
    );
  }

  /// 検索ヘッダーを構築
  Widget _buildSearchHeader(
    BuildContext context,
    bool isMobile,
    EdgeInsets padding,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        isMobile ? 12 : AppConstants.defaultPadding,
        padding.right,
        isMobile ? 12 : AppConstants.defaultPadding,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                  style: TextStyle(
                    color: context.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'ルーム名で検索',
                    labelStyle: TextStyle(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    hintText: '例: 雑談、趣味の話、など',
                    hintStyle: TextStyle(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  onSubmitted: (_) => _searchRooms(),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              _buildSearchButton(isMobile, isDark),
            ],
          ),

          SizedBox(height: isMobile ? 8 : 12),

          // ヒントテキスト
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: isMobile ? 14 : 16,
                color: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  'ルーム名で検索できます（部分一致）',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
                    fontSize: context.responsiveFontSize(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 検索ボタンを構築
  Widget _buildSearchButton(bool isMobile, bool isDark) {
    return ElevatedButton(
      onPressed: (_isLoading || _isSearching) ? null : _searchRooms,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? AppColors.primary.withOpacity(0.9)
            : AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: isDark
            ? AppColors.darkInput
            : Colors.grey.shade300,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 14 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.defaultBorderRadius,
          ),
        ),
        elevation: isDark ? 2 : 4,
      ),
      child: _isSearching
          ? SizedBox(
              width: isMobile ? 18 : 20,
              height: isMobile ? 18 : 20,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              '検索',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: context.responsiveFontSize(15),
              ),
            ),
    );
  }

  /// 検索結果を構築
  Widget _buildSearchResults(
    BuildContext context,
    bool isMobile,
    EdgeInsets padding,
    bool isDark,
  ) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: isDark
                  ? AppColors.primary.lighten(0.2)
                  : AppColors.primary,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              '検索中...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                fontSize: context.responsiveFontSize(15),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(isMobile, isDark);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        isMobile ? 12 : AppConstants.defaultPadding,
        padding.right,
        isMobile ? 12 : AppConstants.defaultPadding,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final room = _searchResults[index];
        return _buildRoomCard(room, isMobile, isDark);
      },
    );
  }

  /// 空の状態を構築
  Widget _buildEmptyState(bool isMobile, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.textSecondary.withOpacity(0.1)
                  : AppColors.textSecondary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.search_off,
              size: isMobile ? 64 : 80,
              color: isDark ? Colors.grey[600] : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            _searchController.text.isEmpty
                ? 'ルーム名を入力して検索してください'
                : '該当するルームが見つかりませんでした',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              fontSize: context.responsiveFontSize(16),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ルームカードを構築
  Widget _buildRoomCard(ChatRoom room, bool isMobile, bool isDark) {
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      elevation: AppConstants.cardElevation,
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: isDark
            ? BorderSide(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: _isLoading ? null : () => _joinRoom(room),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ルーム名
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.8),
                                AppColors.secondary.withOpacity(0.8),
                              ],
                            )
                          : AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chat_bubble,
                      color: AppColors.textWhite,
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Text(
                      room.topic,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: context.responsiveFontSize(18),
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isMobile ? 10 : 12),

              // ステータス
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: isMobile ? 14 : 16,
                    color: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
                  ),
                  SizedBox(width: isMobile ? 3 : 4),
                  Text(
                    '参加待ち',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
                      fontSize: context.responsiveFontSize(13),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isMobile ? 10 : 12),

              // 参加ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _joinRoom(room),
                  icon: Icon(Icons.login, size: isMobile ? 18 : 20),
                  label: Text(
                    'このルームに参加',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(15),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.primary.withOpacity(0.9)
                        : AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    disabledBackgroundColor: isDark
                        ? AppColors.darkInput
                        : Colors.grey.shade300,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: isDark ? 2 : 4,
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
