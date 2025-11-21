import 'package:flutter/material.dart';
import '../models/premium_log_model.dart';
import '../services/premium_log_service.dart';

class PremiumLogProvider extends ChangeNotifier {
  final PremiumLogService _service = PremiumLogService();

  List<PremiumLog> logs = [];
  bool loading = false;

  Future<void> loadLogs() async {
    loading = true;
    notifyListeners();

    logs = await _service.fetchLogs();

    loading = false;
    notifyListeners();
  }

  Future<void> searchByTel(String tel) async {
    loading = true;
    notifyListeners();

    logs = await _service.fetchLogsByTel(tel);

    loading = false;
    notifyListeners();
  }
}
