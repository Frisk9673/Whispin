import 'dart:async';
import '../../repositories/friendship_repository.dart';
import 'invitation_service.dart';
import '../../utils/app_logger.dart';

/// 通知数のキャッシュ＋定期更新を管理するサービス
///
/// Disposeポイント: main.dart で Provider に登録し、アプリライフサイクルで管理する
class NotificationCacheService {
  static const String _logName = 'NotificationCacheService';
  static const Duration _cacheDuration = Duration(minutes: 5);

  final FriendRequestRepository _friendRequestRepository;
  final InvitationService _invitationService;

  // キャッシュデータ
  int _friendRequestCount = 0;
  int _invitationCount = 0;
  DateTime? _lastFetchedAt;
  Timer? _autoRefreshTimer;

  NotificationCacheService({
    required FriendRequestRepository friendRequestRepository,
    required InvitationService invitationService,
  })  : _friendRequestRepository = friendRequestRepository,
        _invitationService = invitationService;

  // ===== ゲッター =====

  int get totalCount => _friendRequestCount + _invitationCount;
  bool get isCacheValid =>
      _lastFetchedAt != null &&
      DateTime.now().difference(_lastFetchedAt!) < _cacheDuration;

  // ===== 取得 =====

  /// キャッシュが有効なら即返す。無効なら実取得して更新する。
  /// [forceRefresh] で強制的に再取得する。
  Future<int> getCount({
    required String userId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && isCacheValid) {
      logger.debug('キャッシュ使用 (残り: ${_remainingSeconds()}秒)', name: _logName);
      return totalCount;
    }

    await _fetch(userId);
    return totalCount;
  }

  // ===== 自動更新 =====

  /// 5分ごとの自動リフレッシュを開始する。
  /// [userId] を渡し、以降のタイマーでも同じユーザーで取得する。
  void startAutoRefresh(String userId) {
    _autoRefreshTimer?.cancel();

    _autoRefreshTimer = Timer.periodic(_cacheDuration, (_) async {
      logger.debug('自動リフレッシュ実行', name: _logName);
      try {
        await _fetch(userId);
      } catch (e) {
        logger.error('自動リフレッシュエラー: $e', name: _logName, error: e);
      }
    });

    logger.info('自動リフレッシュ開始 (間隔: ${_cacheDuration.inMinutes}分)',
        name: _logName);
  }

  /// 自動リフレッシュを停止する。
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    logger.info('自動リフレッシュ停止', name: _logName);
  }

  // ===== キャッシュ無効化 =====

  /// キャッシュを無効にする。次の getCount で再取得になる。
  /// 通知画面から戻った際に呼び出す。
  void invalidateCache() {
    _lastFetchedAt = null;
    logger.debug('キャッシュ無効化', name: _logName);
  }

  // ===== 内部メソッド =====

  Future<void> _fetch(String userId) async {
    logger.debug('Firestore から通知数を取得', name: _logName);

    final friendRequests =
        await _friendRequestRepository.findReceivedRequests(userId);
    final invitations = _invitationService.getReceivedInvitations(userId);

    _friendRequestCount = friendRequests.length;
    _invitationCount = invitations.length;
    _lastFetchedAt = DateTime.now();

    logger.debug(
        'キャッシュ更新: FR=${_friendRequestCount}, Inv=${_invitationCount}, Total=$totalCount',
        name: _logName);
  }

  int _remainingSeconds() {
    if (_lastFetchedAt == null) return 0;
    final remaining = _cacheDuration - DateTime.now().difference(_lastFetchedAt!);
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  // ===== クリーンアップ =====

  void dispose() {
    stopAutoRefresh();
    logger.info('dispose()', name: _logName);
  }
}