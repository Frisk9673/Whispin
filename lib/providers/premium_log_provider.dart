import 'package:flutter/material.dart';
import '../models/premium_log_model.dart';
import '../services/premium_log_service.dart';
import '../utils/app_logger.dart';

class PremiumLogProvider extends ChangeNotifier {
  final PremiumLogService _service = PremiumLogService();
  static const String _logName = 'PremiumLogProvider';

  List<PremiumLog> logs = [];
  bool isLoading = false;

  /// 初期ロード / 全件ロード
  Future<void> loadAllLogs() async {
    logger.section('loadAllLogs() 開始', name: _logName);

    isLoading = true;
    logger.debug('isLoading = true -> notifyListeners()', name: _logName);
    notifyListeners();

    logs = await _service.fetchLogs();
    logger.info('取得件数: ${logs.length} 件', name: _logName);

    isLoading = false;
    logger.debug('isLoading = false -> notifyListeners()', name: _logName);
    notifyListeners();

    logger.section('loadAllLogs() 完了', name: _logName);
  }

  /// メールアドレスでフィルタ（空欄なら全件）
  Future<void> filterByEmail(String? email) async {
    logger.section('filterByEmail() 開始', name: _logName);
    logger.info('入力された email: "$email"', name: _logName);

    isLoading = true;
    logger.debug('isLoading = true -> notifyListeners()', name: _logName);
    notifyListeners();

    if (email == null || email.isEmpty) {
      logger.info('メール未入力なので全件取得します', name: _logName);
      logs = await _service.fetchLogs();
    } else {
      logger.info('メール "$email" のログを取得します', name: _logName);
      logs = await _service.fetchLogsByEmail(email);
    }

    logger.info('取得件数: ${logs.length} 件', name: _logName);

    isLoading = false;
    logger.debug('isLoading = false -> notifyListeners()', name: _logName);
    notifyListeners();

    logger.section('filterByEmail() 完了', name: _logName);
  }
}