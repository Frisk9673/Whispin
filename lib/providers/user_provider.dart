import 'package:flutter/material.dart';
import '../models/user.dart' as app_user;
import '../repositories/user_repository.dart';
import '../utils/app_logger.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  static const String _logName = 'UserProvider';

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
  Future<void> loadUserData(String email) async {
    logger.section('loadUserData() 開始 - email: $email', name: _logName);

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      logger.start('Repository経由でユーザー検索中...', name: _logName);

      _currentUser = await _userRepository.findByEmail(email);

      if (_currentUser == null) {
        logger.error('ユーザーが見つかりません: $email', name: _logName);
        _error = 'ユーザー情報が見つかりません';
        _isLoading = false;
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
      notifyListeners();
    }
  }

  /// プレミアムステータスを更新
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

      await _userRepository.updatePremiumStatus(
        _currentUser!.id,
        isPremium,
      );

      // プレミアム契約・解約ログを作成
      if (_currentUser!.id.isNotEmpty) {
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

      notifyListeners();

      logger.section('updatePremiumStatus() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('エラー発生: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }


  /// プロフィール画像URLを更新
  Future<void> updateProfileImageUrl(String? profileImageUrl) async {
    logger.section('updateProfileImageUrl() 開始', name: _logName);

    if (_currentUser == null) {
      logger.error('ユーザー情報が読み込まれていません', name: _logName);
      throw Exception('ユーザー情報が読み込まれていません');
    }

    try {
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

      notifyListeners();

      logger.section('updateProfileImageUrl() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('プロフィール画像URL更新エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// アカウント削除（論理削除）
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

      await _userRepository.softDelete(_currentUser!.id);

      logger.success('Firestore deletedAt 更新完了', name: _logName);

      // 削除後はローカル状態をクリア
      _currentUser = null;
      _error = null;

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
  void clearUser() {
    logger.info('clearUser() - ユーザー情報をクリア', name: _logName);
    _currentUser = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// ユーザー評価スコアを更新
  Future<void> updateRate(double rate) async {
    if (_currentUser == null) return;

    logger.debug('updateRate($rate)', name: _logName);

    try {
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

      notifyListeners();
    } catch (e) {
      logger.error('評価スコア更新エラー: $e', name: _logName, error: e);
      rethrow;
    }
  }

  /// ルーム参加回数をインクリメント
  Future<void> incrementRoomCount() async {
    if (_currentUser == null) return;

    logger.debug('incrementRoomCount()', name: _logName);

    try {
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

      notifyListeners();
    } catch (e) {
      logger.error('ルーム参加回数更新エラー: $e', name: _logName, error: e);
      rethrow;
    }
  }
}
