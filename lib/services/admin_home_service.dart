import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _logName = 'AdminService';

  /// Firestoreから有料会員数を取得
  Future<int> fetchPaidMemberCount() async {
    logger.section('fetchPaidMemberCount() 開始', name: _logName);
    
    try {
      logger.start('Firestore User コレクションを検索中...', name: _logName);
      logger.info('検索条件: Premium = true', name: _logName);
      
      // User コレクションから Premium: true のユーザーを検索
      final querySnapshot = await _firestore
          .collection('User')
          .where('Premium', isEqualTo: true)
          .get();
      
      logger.info('取得ドキュメント数: ${querySnapshot.docs.length}', name: _logName);
      
      // 削除済みユーザーを除外してカウント
      final count = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final isDeleted = data['DeletedAt'] != null;
        
        if (isDeleted) {
          logger.debug('削除済みユーザーを除外: ${doc.id}', name: _logName);
        }
        
        return !isDeleted;
      }).length;
      
      logger.success('有料会員数: $count 人', name: _logName);
      logger.section('fetchPaidMemberCount() 完了', name: _logName);
      
      return count;
      
    } catch (e, stack) {
      logger.error('エラー発生: $e', 
        name: _logName, 
        error: e, 
        stackTrace: stack,
      );
      rethrow;
    }
  }
}