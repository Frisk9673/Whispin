import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/premium_log_model.dart';

class PremiumLogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Log_Premium 全件取得
  Future<List<PremiumLog>> fetchLogs() async {
    final snapshot = await _db.collection('Log_Premium')
        .orderBy('Timestamp', descending: true)
        .get();

    // デバッグ: 取得したデータをコンソール出力
    print('=== fetchLogs snapshot ===');
    for (var doc in snapshot.docs) {
      print(doc.data());
    }

    final logs = snapshot.docs.map((d) => PremiumLog.fromMap(d.data())).toList();
    print('=== fetchLogs mapped logs ===');
    for (var log in logs) {
      print('${log.telId}, ${log.detail}, ${log.timestamp}');
    }

    return logs;
  }

  /// 電話番号でフィルタ
  Future<List<PremiumLog>> fetchLogsByTel(String tel) async {
    final snapshot = await _db.collection('Log_Premium')
        .where('ID', isEqualTo: tel)
        .orderBy('Timestamp', descending: true)
        .get();

    // デバッグ: 取得したデータをコンソール出力
    print('=== fetchLogsByTel snapshot for $tel ===');
    for (var doc in snapshot.docs) {
      print(doc.data());
    }

    final logs = snapshot.docs.map((d) => PremiumLog.fromMap(d.data())).toList();
    print('=== fetchLogsByTel mapped logs ===');
    for (var log in logs) {
      print('${log.telId}, ${log.detail}, ${log.timestamp}');
    }

    return logs;
  }

  /// 対象ユーザ取得
  Future<UserModel?> fetchUser(String tel) async {
    final doc = await _db.collection('User').doc(tel).get();

    print('=== fetchUser for $tel ===');
    if (!doc.exists) {
      print('User not found');
      return null;
    }
    print(doc.data());

    return UserModel.fromMap(doc.data()!);
  }
}
