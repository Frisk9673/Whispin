import 'package:flutter/material.dart';
import '../models/premium_log_model.dart';
import '../services/premium_log_service.dart';

class PremiumLogProvider extends ChangeNotifier {
  final PremiumLogService _service = PremiumLogService();

  List<PremiumLog> logs = [];
  bool isLoading = false;

  /// 初期ロード / 全件ロード
  Future<void> loadAllLogs() async {
    isLoading = true;
    notifyListeners();

    logs = await _service.fetchLogs();

    isLoading = false;
    notifyListeners();
  }

  /// 電話番号でフィルタ（空欄なら全件）
  Future<void> filterByTel(String? tel) async {
    isLoading = true;
    notifyListeners();

    if (tel == null || tel.isEmpty) {
      logs = await _service.fetchLogs();
    } else {
      logs = await _service.fetchLogsByTel(tel);
    }

    isLoading = false;
    notifyListeners();
  }
}
