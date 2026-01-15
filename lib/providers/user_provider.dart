import 'package:flutter/material.dart';
import '../models/user.dart' as app_user;
import '../repositories/user_repository.dart';
import '../constants/app_constants.dart';
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

  /// ログイン時にユーザー情報を読み込む
  Future<void> loadUserData(String email) async {
    logger.section('loadUserData() 開始 - email: $email', name: _logName);

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      logger.start('Repository経由でユーザー検索中...', name: _logName);

      // Repository経由でユーザー取得
      _currentUser = await _userRepository.findByEmail(email);

      if (_currentUser == null) {
        logger.error('ユーザーが見つかりません: $email', name: _logName);
        _error = 'ユーザー情報が見つかりません';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 削除済みチェック
      if (_currentUser!.isDeleted) {
        logger.warning('削除済みユーザー: $email', name: _logName);
        _error = 'このアカウントは削除されています';
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
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
      _error = 'ユーザー情報の読み込みに失敗しました: $e';
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

    // Repository経由で更新
    await _userRepository.updatePremiumStatus(
      _currentUser!.id,
      isPremium,
    );

    // ★ 追加：プレミアム契約・解約ログを作成
    if (_currentUser!.phoneNumber != null &&
        _currentUser!.phoneNumber!.isNotEmpty) {
      await _userRepository.createPremiumLog(
        phoneNumber: _currentUser!.phoneNumber!, // ← ここで ! を使う
        isPremium: isPremium,
      );
    }

    logger.success('Repository更新完了', name: _logName);

    // ★ 変更: ローカルのユーザー情報を即座に更新（Firestoreは信頼）
    _currentUser = app_user.User(
      id: _currentUser!.id,
      password: _currentUser!.password,
      firstName: _currentUser!.firstName,
      lastName: _currentUser!.lastName,
      nickname: _currentUser!.nickname,
      phoneNumber: _currentUser!.phoneNumber,
      rate: _currentUser!.rate,
      premium: isPremium, // ★ 更新
      roomCount: _currentUser!.roomCount,
      createdAt: _currentUser!.createdAt,
      lastUpdatedPremium: DateTime.now(), // ★ 更新
      deletedAt: _currentUser!.deletedAt,
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
      );

      notifyListeners();
    } catch (e) {
      logger.error('ルーム参加回数更新エラー: $e', name: _logName, error: e);
      rethrow;
    }
  }
}