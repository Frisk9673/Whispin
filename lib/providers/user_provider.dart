import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart' as app_user;
import '../utils/app_logger.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  static const String _logName = 'UserProvider';

  app_user.User? _currentUser;
  DocumentReference? _userDocRef;
  bool _isLoading = false;
  String? _error;

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _currentUser?.premium ?? false;

  /// ログイン時にユーザー情報を読み込む
  Future<void> loadUserData() async {
    logger.section('loadUserData() 開始', name: _logName);

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authUser = _auth.currentUser;
      if (authUser == null) {
        logger.error('Firebase Auth ユーザーが存在しません', name: _logName);
        _error = 'ログインしていません';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final email = authUser.email;
      if (email == null) {
        logger.error('メールアドレスが取得できません', name: _logName);
        _error = 'メールアドレスが取得できません';
        _isLoading = false;
        notifyListeners();
        return;
      }

      logger.info('ログインユーザー: $email', name: _logName);
      logger.start('Firestoreでユーザー検索中...', name: _logName);

      DocumentSnapshot? userDoc;

      // 方法1: EmailAddressフィールドで検索
      try {
        logger.debug('検索方法1: EmailAddress フィールドで検索', name: _logName);
        final query = await _firestore
            .collection('User')
            .where('EmailAddress', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          userDoc = query.docs.first;
          _userDocRef = userDoc.reference;
          logger.success('EmailAddress で発見: ${userDoc.id}', name: _logName);
        }
      } catch (e) {
        logger.warning('EmailAddress検索失敗: $e', name: _logName);
      }

      // 方法2: idフィールドで検索
      if (userDoc == null) {
        try {
          logger.debug('検索方法2: id フィールドで検索', name: _logName);
          final query = await _firestore
              .collection('User')
              .where('id', isEqualTo: email)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            userDoc = query.docs.first;
            _userDocRef = userDoc.reference;
            logger.success('id で発見: ${userDoc.id}', name: _logName);
          }
        } catch (e) {
          logger.warning('id検索失敗: $e', name: _logName);
        }
      }

      // 方法3: emailフィールドで検索
      if (userDoc == null) {
        try {
          logger.debug('検索方法3: email フィールドで検索', name: _logName);
          final query = await _firestore
              .collection('User')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            userDoc = query.docs.first;
            _userDocRef = userDoc.reference;
            logger.success('email で発見: ${userDoc.id}', name: _logName);
          }
        } catch (e) {
          logger.warning('email検索失敗: $e', name: _logName);
        }
      }

      // 方法4: ドキュメントIDとして直接取得
      if (userDoc == null) {
        try {
          logger.debug('検索方法4: ドキュメントID($email)で直接取得', name: _logName);
          userDoc = await _firestore.collection('User').doc(email).get();

          if (userDoc.exists) {
            _userDocRef = userDoc.reference;
            logger.success('ドキュメントIDで発見: ${userDoc.id}', name: _logName);
          } else {
            userDoc = null;
          }
        } catch (e) {
          logger.warning('ドキュメントID取得失敗: $e', name: _logName);
        }
      }

      // デバッグ: Userコレクション全体を確認
      if (userDoc == null) {
        logger.section('デバッグ: Userコレクションの全ドキュメントを確認', name: _logName);
        try {
          final allUsers = await _firestore.collection('User').limit(5).get();
          logger.info('総ドキュメント数: ${allUsers.docs.length}', name: _logName);

          for (var doc in allUsers.docs) {
            logger.info('ドキュメントID: ${doc.id}', name: _logName);
            final data = doc.data();
            logger.info('  フィールド一覧:', name: _logName);
            data.forEach((key, value) {
              logger.info('    $key: $value', name: _logName);
            });
          }
        } catch (e) {
          logger.error('デバッグ取得エラー: $e', name: _logName, error: e);
        }
      }

      if (userDoc == null || !userDoc.exists) {
        logger.error('ユーザー情報が見つかりません', name: _logName);
        _error = 'ユーザー情報が見つかりません';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // ユーザーデータを変換
      final userData = userDoc.data() as Map<String, dynamic>;
      logger.section('取得したユーザーデータ', name: _logName);
      userData.forEach((key, value) {
        logger.info('  $key: $value', name: _logName);
      });

      _currentUser = app_user.User.fromMap(userData);

      logger.success('ユーザー情報読み込み完了', name: _logName);
      logger.info('  名前: ${_currentUser!.fullName}', name: _logName);
      logger.info('  ニックネーム: ${_currentUser!.displayName}', name: _logName);
      logger.info('  プレミアム: ${_currentUser!.premium}', name: _logName);
      logger.section('loadUserData() 完了', name: _logName);

      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      logger.error('エラー発生: $e', name: _logName, error: e, stackTrace: stack);
      _error = 'ユーザー情報の読み込みに失敗しました: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// プレミアムステータスを更新
  Future<void> updatePremiumStatus(bool isPremium) async {
    logger.section('updatePremiumStatus($isPremium) 開始', name: _logName);

    if (_userDocRef == null) {
      logger.error('ユーザードキュメント参照がありません', name: _logName);
      throw Exception('ユーザー情報が読み込まれていません');
    }

    try {
      // Firestoreを更新
      await _userDocRef!.update({
        'Premium': isPremium,
        'premium': isPremium,
        'LastUpdated_Premium': FieldValue.serverTimestamp(),
        'lastUpdatedPremium': FieldValue.serverTimestamp(),
      });

      logger.success('Firestore更新完了', name: _logName);

      // ローカルのユーザー情報も更新
      if (_currentUser != null) {
        _currentUser = app_user.User(
          id: _currentUser!.id,
          password: _currentUser!.password,
          firstName: _currentUser!.firstName,
          lastName: _currentUser!.lastName,
          nickname: _currentUser!.nickname,
          phoneNumber: _currentUser!.phoneNumber,
          rate: _currentUser!.rate,
          premium: isPremium,
          roomCount: _currentUser!.roomCount,
          createdAt: _currentUser!.createdAt,
          lastUpdatedPremium: DateTime.now(),
          deletedAt: _currentUser!.deletedAt,
        );

        logger.success('ローカルユーザー情報更新完了', name: _logName);
        notifyListeners();
      }

      // Log_Premiumに履歴を追加
      await _firestore.collection('Log_Premium').add({
        'ID': _currentUser!.id,
        'Timestamp': FieldValue.serverTimestamp(),
        'Detail': isPremium ? '加入' : '解約',
      });

      logger.info('Log_Premium に${isPremium ? "加入" : "解約"}ログ追加完了', name: _logName);
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
    _userDocRef = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}