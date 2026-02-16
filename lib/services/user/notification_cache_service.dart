import 'dart:async';
import '../../repositories/friendship_repository.dart';
import 'invitation_service.dart';
import '../../utils/app_logger.dart';

/// 【担当ユースケース】
/// - ホーム/通知表示で使う未読件数の即時表示と、定期再取得。
/// - 起動直後は StartupInvitationService の処理結果を反映するためキャッシュ無効化を許可する。
///
/// 【依存するRepository/Service】
/// - [FriendRequestRepository]: 受信フレンド申請件数の取得。
/// - [InvitationService]: 受信招待件数の取得。
///
/// 【主な副作用（DB更新/通知送信）】
/// - DB更新/通知送信は行わず、メモリキャッシュと定期Timerのみを更新する。
///
/// Disposeポイント: main.dart で Provider に登録し、アプリライフサイクルで管理する。
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

  /// 入力: [userId], [forceRefresh]。
  /// 前提条件: userId がログイン中ユーザーであること。
  /// 成功時結果: 有効キャッシュを返すか、再取得して合計件数を返す。
  /// 失敗時挙動: `_fetch` の例外を上位へ伝播する。
  ///
  /// 時系列参照:
  /// 1) アプリ起動時に StartupInvitationService が招待処理
  /// 2) 画面復帰で `invalidateCache()`
  /// 3) 本メソッドで最新件数を再計算
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

  /// 入力: [userId]。
  /// 前提条件: 二重起動を避けるため既存Timerは内部で停止済み。
  /// 成功時結果: 5分間隔の再取得Timerが開始される。
  /// 失敗時挙動: Timer内の取得失敗はログ出力して継続する。
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

  /// 入力: なし。
  /// 前提条件: なし。
  /// 成功時結果: 自動更新Timerを停止する。
  /// 失敗時挙動: 例外は発生しない想定。
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
