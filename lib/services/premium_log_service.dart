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

    return snapshot.docs.map((d) => PremiumLog.fromMap(d.data())).toList();
  }

  /// 電話番号でフィルタ
  Future<List<PremiumLog>> fetchLogsByTel(String tel) async {
    final snapshot = await _db.collection('Log_Premium')
        .where('ID', isEqualTo: tel)
        .orderBy('Timestamp', descending: true)
        .get();

    return snapshot.docs.map((d) => PremiumLog.fromMap(d.data())).toList();
  }

  /// 対象ユーザ取得
  Future<UserModel?> fetchUser(String tel) async {
    final doc = await _db.collection('User').doc(tel).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }
}
