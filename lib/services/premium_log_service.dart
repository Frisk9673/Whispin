import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/premium_log_model.dart';

class PremiumLogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Log_Premium 全件取得
  Future<List<PremiumLog>> fetchLogs() async {
    print("\n\n===============================");
    print("🔥 [fetchLogs] プレミアムログ全件取得 開始");
    print("===============================");

    try {
      final snapshot = await _db.collection('Log_Premium')
          .orderBy('Timestamp', descending: true)
          .get();

      print("📌 Firestore 取得件数: ${snapshot.docs.length}");

      for (var doc in snapshot.docs) {
        print("▶ ドキュメント: ${doc.data()}");
      }

      final logs = snapshot.docs.map((d) => PremiumLog.fromMap(d.data())).toList();

      print("📌 マッピング後ログ件数: ${logs.length}");
      for (var log in logs) {
        print(
            "✔ TEL_ID: ${log.email} / DETAIL: ${log.detail} / TIME: ${log.timestamp}");
      }

      print("✅ [fetchLogs] 完了");
      print("===============================\n\n");

      return logs;
    } catch (e) {
      print("❌ [fetchLogs] エラー発生: $e");
      print("===============================\n\n");
      rethrow;
    }
  }

  /// 電話番号でフィルタ
  Future<List<PremiumLog>> fetchLogsByTel(String tel) async {
    print("\n\n===============================");
    print("🔍 [fetchLogsByTel] 電話番号検索: $tel");
    print("===============================");

    try {
      final snapshot = await _db.collection('Log_Premium')
          .where('ID', isEqualTo: tel)
          .orderBy('Timestamp', descending: true)
          .get();

      print("📌 取得件数: ${snapshot.docs.length}");

      for (var doc in snapshot.docs) {
        print("▶ ドキュメント: ${doc.data()}");
      }

      final logs = snapshot.docs.map((d) => PremiumLog.fromMap(d.data())).toList();

      print("📌 マッピング後ログ件数: ${logs.length}");
      for (var log in logs) {
        print(
            "✔ TEL_ID: ${log.email} / DETAIL: ${log.detail} / TIME: ${log.timestamp}");
      }

      print("✅ [fetchLogsByTel] 完了");
      print("===============================\n\n");

      return logs;
    } catch (e) {
      print("❌ [fetchLogsByTel] エラー発生: $e");
      print("===============================\n\n");
      rethrow;
    }
  }

  /// 対象ユーザ取得
  Future<User?> fetchUser(String tel) async {
    print("\n\n===============================");
    print("👤 [fetchUser] ユーザ取得 TEL_ID: $tel");
    print("===============================");

    try {
      final doc = await _db.collection('User').doc(tel).get();

      if (!doc.exists) {
        print("❌ ユーザデータなし");
        print("===============================\n\n");
        return null;
      }

      print("📌 取得ユーザデータ:");
      print(doc.data());

      print("✅ [fetchUser] 完了");
      print("===============================\n\n");

      return User.fromMap(doc.data()!);
    } catch (e) {
      print("❌ [fetchUser] エラー発生: $e");
      print("===============================\n\n");
      rethrow;
    }
  }
}
