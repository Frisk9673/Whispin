import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firestoreから有料会員数を取得
  Future<int> fetchPaidMemberCount() async {
    print('📊 [AdminService] fetchPaidMemberCount() 開始');
    
    try {
      // User コレクションから Premium: true のユーザーを検索
      final querySnapshot = await _firestore
          .collection('User')
          .where('Premium', isEqualTo: true)
          .get();
      
      // 削除済みユーザーを除外してカウント
      final count = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['DeletedAt'] == null;
      }).length;
      
      print('✅ [AdminService] 有料会員数: $count 人');
      return count;
      
    } catch (e) {
      print('❌ [AdminService] エラー発生: $e');
      rethrow;
    }
  }
}