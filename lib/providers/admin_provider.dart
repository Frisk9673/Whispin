import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../utils/app_logger.dart';

class AdminProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  static const String _logName = 'AdminProvider';

  int paidMemberCount = 0;
  bool isLoading = false;

  AdminProvider({required UserRepository userRepository})
      : _userRepository = userRepository {
    loadPaidMemberCount();
  }

  /// 有料会員数を取得して状態を更新
  Future<void> loadPaidMemberCount() async {
    logger.section('loadPaidMemberCount() 開始', name: _logName);

    isLoading = true;
    logger.debug('isLoading = true -> notifyListeners()', name: _logName);
    notifyListeners();

    try {
      logger.start('UserRepository.countPremiumUsers() 呼び出し中...', name: _logName);

      // Repository経由でプレミアム会員数を取得
      final count = await _userRepository.countPremiumUsers();
      paidMemberCount = count;

      logger.success('有料会員数取得完了: $count 人', name: _logName);
    } catch (e, stack) {
      logger.error(
        'loadPaidMemberCount エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      paidMemberCount = 0;
    } finally {
      isLoading = false;
      logger.debug('isLoading = false -> notifyListeners()', name: _logName);
      notifyListeners();
    }

    logger.section('loadPaidMemberCount() 完了', name: _logName);
  }

  /// 外部から明示的に再読み込みするための別名
  Future<void> refresh() async {
    logger.info('refresh() - 再読み込みを開始', name: _logName);
    await loadPaidMemberCount();
  }
}