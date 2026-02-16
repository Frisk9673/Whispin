import 'package:flutter/material.dart';
import '../models/user/user.dart' as app_user;
import '../repositories/user_repository.dart';
import '../utils/app_logger.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  static const String _logName = 'UserProvider';

  // ===== 管理対象state一覧 =====
  // _currentUser: 認証済みユーザーのプロフィール情報。
  // _isLoading: ユーザー関連処理の進行状態。
  // _error: 画面表示用エラーメッセージ。
  app_user.User? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserProvider({required UserRepository userRepository})
      : _userRepository = userRepository;

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _currentUser?.premium ?? false;

  String? get profileImageUrl => _currentUser?.profileImageUrl;

  /// ログイン時にユーザー情報を読み込む
  /// state変更:
  /// - 開始時: _isLoading=true, _error=null
  /// - 成功時: _currentUser 更新
  /// - 失敗時: _error 更新
  /// - 終了時: _isLoading=false
  Future<void> loadUserData(String email) async {
    logger.section('loadUserData() 開始 - email: $email', name: _logName);

    _isLoading = true;
    _error = null;
    // 読み込み開始とエラー解除を画面へ反映する。
    notifyListeners();

    try {
      logger.start('Repository経由でユーザー検索中...', name: _logName);

      // 次は UserRepository.findByEmail() で Firestore の User 取得処理へ渡す。
      _currentUser = await _userRepository.findByEmail(email);

      if (_currentUser == null) {
        logger.error('ユーザーが見つかりません: $email', name: _logName);
        _error = 'ユーザー情報が見つかりません';
        _isLoading = false;
        // エラー表示とローディング解除を即時反映する。
        notifyListeners();
        return;
      }

      if (_currentUser!.isDeleted) {
        logger.warning('削除済みユーザー: $email', name: _logName);
        _error = 'このアカウントは削除されています';
        _currentUser = null;
        return;
      }

      logger.success('ユーザー情報読み込み完了', name: _logName);
      logger.info('  名前: ${_currentUser!.fullName}', name: _logName);
      logger.info('  ニックネーム: ${_currentUser!.displayName}', name: _logName);
      logger.info('  プレミアム: ${_currentUser!.premium}', name: _logName);
      logger.section('loadUserData() 完了', name: _logName);

      _isLoading = false;
      // ユーザー情報ロード完了を画面へ反映する。
      notifyListeners();
    } catch (e, stack) {
      logger.error(
        'エラー発生: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      _error ??= 'ユーザー情報の読み込みに失敗しました: $e';
      _isLoading = false;
      // エラー表示とローディング解除を画面へ反映する。
      notifyListeners();
    }
  }

  /// プレミアムステータスを更新
  /// state変更: 成功時に _currentUser.premium を更新。
  Future<void> updatePremiumStatus(bool isPremium) async {
    logger.section('updatePremiumStatus($isPremium) 開始', name: _logName);

    if (_currentUser == null) {
      logger.error('ユーザー情報が読み込まれていません', name: _logName);
      throw Exception('ユーザー情報が読み込まれていません');
    }

    try {
      logger.info('現在のユーザーID: ${_currentUser!.id}', name: _logName);
      logger.info('現在のプレミアム状態: ${_currentUser!.premium}', name: _logName);
      logger.info('変更後のプレミアム状態: $isPremium', name: _logName);

      // Repository境界: プレミアム状態更新はRepositoryへ委譲する。
      await _userRepository.updatePremiumStatus(
        _currentUser!.id,
        isPremium,
      );

      // プレミアム契約・解約ログを作成
      if (_currentUser!.id.isNotEmpty) {
        // Repository境界: ログ作成はRepositoryへ委譲する。
        await _userRepository.createPremiumLog(
          id: _currentUser!.id,
          isPremium: isPremium,
        );
      }

      logger.success('Repository更新完了', name: _logName);

      // Firestore更新後にローカルの状態を即時反映
      _currentUser = app_user.User(
        id: _currentUser!.id,
        password: _currentUser!.password,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        nickname: _currentUser!.nickname,
        phoneNumber: _currentUser!.phoneNumber,
        rate: _currentUser!.rate,
        premium: isPremium,
        roomCount: _currentUser!.roomCount,
        createdAt: _currentUser!.createdAt,
        lastUpdatedPremium: DateTime.now(),
        deletedAt: _currentUser!.deletedAt,
        fcmToken: _currentUser!.fcmToken,
        fcmTokenUpdatedAt: _currentUser!.fcmTokenUpdatedAt,
        profileImageUrl: _currentUser!.profileImageUrl,
      );

      logger.success('ローカルユーザー情報更新完了', name: _logName);
      logger.info('  premium: ${_currentUser!.premium}', name: _logName);

      // premium表示の更新を画面へ反映する。
      notifyListeners();

      logger.section('updatePremiumStatus() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('エラー発生: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }


  /// プロフィール画像URLを更新
  /// state変更: 成功時に _currentUser.profileImageUrl を更新。
  Future<void> updateProfileImageUrl(String? profileImageUrl) async {
    logger.section('updateProfileImageUrl() 開始', name: _logName);

    if (_currentUser == null) {
      logger.error('ユーザー情報が読み込まれていません', name: _logName);
      throw Exception('ユーザー情報が読み込まれていません');
    }

    try {
      // Repository境界: プロフィール画像URL更新はRepositoryへ委譲する。
      await _userRepository.updateProfileImageUrl(
        _currentUser!.id,
        profileImageUrl,
      );

      _currentUser = app_user.User(
        id: _currentUser!.id,
        password: _currentUser!.password,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        nickname: _currentUser!.nickname,
        phoneNumber: _currentUser!.phoneNumber,
        rate: _currentUser!.rate,
        premium: _currentUser!.premium,
        roomCount: _currentUser!.roomCount,
        createdAt: _currentUser!.createdAt,
        lastUpdatedPremium: _currentUser!.lastUpdatedPremium,
        deletedAt: _currentUser!.deletedAt,
        fcmToken: _currentUser!.fcmToken,
        fcmTokenUpdatedAt: _currentUser!.fcmTokenUpdatedAt,
        profileImageUrl: profileImageUrl,
      );

      // プロフィール画像表示の更新を画面へ反映する。
      notifyListeners();

      logger.section('updateProfileImageUrl() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('プロフィール画像URL更新エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// アカウント削除（論理削除）
  /// state変更: 成功時に _currentUser と _error をクリア。
  Future<void> deleteAccount() async {
    logger.section('deleteAccount() 開始', name: _logName);

    if (_currentUser == null) {
      logger.error('ユーザー情報が存在しません', name: _logName);
      throw Exception('ユーザー情報が存在しません');
    }

    try {
      logger.info(
        'アカウント削除実行: ${_currentUser!.id}',
        name: _logName,
      );

      // Repository境界: 論理削除はRepositoryへ委譲する。
      await _userRepository.softDelete(_currentUser!.id);

      logger.success('Firestore deletedAt 更新完了', name: _logName);

      // 削除後はローカル状態をクリア
      _currentUser = null;
      _error = null;

      // 削除後のログアウト状態を画面へ反映する。
      notifyListeners();

      logger.section('deleteAccount() 完了', name: _logName);
    } catch (e, stack) {
      logger.error(
        'アカウント削除エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// ユーザー情報をクリア（ログアウト時）
  /// state変更: _currentUser/_error/_isLoading を初期状態へ戻す。
  void clearUser() {
    logger.info('clearUser() - ユーザー情報をクリア', name: _logName);
    _currentUser = null;
    _error = null;
    _isLoading = false;
    // ログアウト後の初期表示へ再描画する。
    notifyListeners();
  }

  /// ユーザー評価スコアを更新
  /// state変更: 成功時に _currentUser.rate を更新。
  Future<void> updateRate(double rate) async {
    if (_currentUser == null) return;

    logger.debug('updateRate($rate)', name: _logName);

    try {
      // Repository境界: 評価スコア更新はRepositoryへ委譲する。
      await _userRepository.updateRate(_currentUser!.id, rate);

      _currentUser = app_user.User(
        id: _currentUser!.id,
        password: _currentUser!.password,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        nickname: _currentUser!.nickname,
        phoneNumber: _currentUser!.phoneNumber,
        rate: rate,
        premium: _currentUser!.premium,
        roomCount: _currentUser!.roomCount,
        createdAt: _currentUser!.createdAt,
        lastUpdatedPremium: _currentUser!.lastUpdatedPremium,
        deletedAt: _currentUser!.deletedAt,
        fcmToken: _currentUser!.fcmToken,
        fcmTokenUpdatedAt: _currentUser!.fcmTokenUpdatedAt,
        profileImageUrl: _currentUser!.profileImageUrl,
      );

      // 最新評価スコアの表示へ更新する。
      notifyListeners();
    } catch (e) {
      logger.error('評価スコア更新エラー: $e', name: _logName, error: e);
      rethrow;
    }
  }

  /// ルーム参加回数をインクリメント
  /// state変更: 成功時に _currentUser.roomCount を +1 更新。
  Future<void> incrementRoomCount() async {
    if (_currentUser == null) return;

    logger.debug('incrementRoomCount()', name: _logName);

    try {
      // Repository境界: 参加回数更新はRepositoryへ委譲する。
      await _userRepository.incrementRoomCount(_currentUser!.id);

      _currentUser = app_user.User(
        id: _currentUser!.id,
        password: _currentUser!.password,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        nickname: _currentUser!.nickname,
        phoneNumber: _currentUser!.phoneNumber,
        rate: _currentUser!.rate,
        premium: _currentUser!.premium,
        roomCount: _currentUser!.roomCount + 1,
        createdAt: _currentUser!.createdAt,
        lastUpdatedPremium: _currentUser!.lastUpdatedPremium,
        deletedAt: _currentUser!.deletedAt,
        fcmToken: _currentUser!.fcmToken,
        fcmTokenUpdatedAt: _currentUser!.fcmTokenUpdatedAt,
        profileImageUrl: _currentUser!.profileImageUrl,
      );

      // 参加回数表示の更新を画面へ反映する。
      notifyListeners();
    } catch (e) {
      logger.error('ルーム参加回数更新エラー: $e', name: _logName, error: e);
      rethrow;
    }
  }
}
