import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart' as app_user;

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  app_user.User? _currentUser;
  DocumentReference? _userDocRef; // ドキュメント参照を保持
  bool _isLoading = false;
  String? _error;

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _currentUser?.premium ?? false;

  /// ログイン時にユーザー情報を読み込む
  Future<void> loadUserData() async {
    print('\n=== UserProvider.loadUserData() 開始 ===');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authUser = _auth.currentUser;
      if (authUser == null) {
        print('❌ Firebase Auth ユーザーが存在しません');
        _error = 'ログインしていません';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final email = authUser.email;
      if (email == null) {
        print('❌ メールアドレスが取得できません');
        _error = 'メールアドレスが取得できません';
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('📧 ログインユーザー: $email');
      print('🔍 Firestoreでユーザー検索中...');

      DocumentSnapshot? userDoc;

      // 方法1: EmailAddressフィールドで検索
      try {
        print('  → 検索方法1: EmailAddress フィールドで検索');
        final query = await _firestore
            .collection('User')
            .where('EmailAddress', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          userDoc = query.docs.first;
          _userDocRef = userDoc.reference;
          print('  ✅ EmailAddress で発見: ${userDoc.id}');
        }
      } catch (e) {
        print('  ⚠️ EmailAddress検索失敗: $e');
      }

      // 方法2: idフィールドで検索
      if (userDoc == null) {
        try {
          print('  → 検索方法2: id フィールドで検索');
          final query = await _firestore
              .collection('User')
              .where('id', isEqualTo: email)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            userDoc = query.docs.first;
            _userDocRef = userDoc.reference;
            print('  ✅ id で発見: ${userDoc.id}');
          }
        } catch (e) {
          print('  ⚠️ id検索失敗: $e');
        }
      }

      // 方法3: emailフィールドで検索
      if (userDoc == null) {
        try {
          print('  → 検索方法3: email フィールドで検索');
          final query = await _firestore
              .collection('User')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            userDoc = query.docs.first;
            _userDocRef = userDoc.reference;
            print('  ✅ email で発見: ${userDoc.id}');
          }
        } catch (e) {
          print('  ⚠️ email検索失敗: $e');
        }
      }

      // 方法4: ドキュメントIDとして直接取得
      if (userDoc == null) {
        try {
          print('  → 検索方法4: ドキュメントID($email)で直接取得');
          userDoc = await _firestore.collection('User').doc(email).get();

          if (userDoc.exists) {
            _userDocRef = userDoc.reference;
            print('  ✅ ドキュメントIDで発見: ${userDoc.id}');
          } else {
            userDoc = null;
          }
        } catch (e) {
          print('  ⚠️ ドキュメントID取得失敗: $e');
        }
      }

      // デバッグ: Userコレクション全体を確認
      if (userDoc == null) {
        print('\n📋 デバッグ: Userコレクションの全ドキュメントを確認');
        try {
          final allUsers = await _firestore.collection('User').limit(5).get();

          print('  総ドキュメント数: ${allUsers.docs.length}');

          for (var doc in allUsers.docs) {
            print('  ドキュメントID: ${doc.id}');
            final data = doc.data();
            print('    フィールド一覧:');
            data.forEach((key, value) {
              print('      $key: $value');
            });
          }
        } catch (e) {
          print('  ❌ デバッグ取得エラー: $e');
        }
      }

      if (userDoc == null || !userDoc.exists) {
        print('❌ ユーザー情報が見つかりません');
        _error = 'ユーザー情報が見つかりません';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // ユーザーデータを変換
      final userData = userDoc.data() as Map<String, dynamic>;
      print('📄 取得したユーザーデータ:');
      userData.forEach((key, value) {
        print('  $key: $value');
      });

      _currentUser = app_user.User.fromMap(userData);

      print('✅ ユーザー情報読み込み完了');
      print('  名前: ${_currentUser!.fullName}');
      print('  ニックネーム: ${_currentUser!.displayName}');
      print('  プレミアム: ${_currentUser!.premium}');
      print('=== UserProvider.loadUserData() 完了 ===\n');

      _isLoading = false;
      notifyListeners();
    } catch (e, stack) {
      print('❌ エラー発生: $e');
      print('スタックトレース: $stack');
      _error = 'ユーザー情報の読み込みに失敗しました: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// プレミアムステータスを更新
  Future<void> updatePremiumStatus(bool isPremium) async {
    print('\n=== UserProvider.updatePremiumStatus($isPremium) 開始 ===');

    if (_userDocRef == null) {
      print('❌ ユーザードキュメント参照がありません');
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

      print('✅ Firestore更新完了');

      // ローカルのユーザー情報も更新
      if (_currentUser != null) {
        // User モデルに copyWith がない場合は再作成
        _currentUser = app_user.User(
          id: _currentUser!.id,
          password: _currentUser!.password,
          firstName: _currentUser!.firstName,
          lastName: _currentUser!.lastName,
          nickname: _currentUser!.nickname,
          phoneNumber: _currentUser!.phoneNumber,
          rate: _currentUser!.rate,
          premium: isPremium, // 更新
          roomCount: _currentUser!.roomCount,
          createdAt: _currentUser!.createdAt,
          lastUpdatedPremium: DateTime.now(), // 更新
          deletedAt: _currentUser!.deletedAt,
        );

        print('✅ ローカルユーザー情報更新完了');
        notifyListeners();
      }

      // Log_Premiumに履歴を追加
      await _firestore.collection('Log_Premium').add({
        'ID': _currentUser!.id,
        'Timestamp': FieldValue.serverTimestamp(),
        'Detail': isPremium ? '加入' : '解約',
      });

      print('📝 Log_Premium に${isPremium ? "加入" : "解約"}ログ追加完了');
      print('=== UserProvider.updatePremiumStatus() 完了 ===\n');
    } catch (e, stack) {
      print('❌ エラー発生: $e');
      print('スタックトレース: $stack');
      rethrow;
    }
  }

  /// ユーザー情報をクリア（ログアウト時）
  void clearUser() {
    print('🗑️ UserProvider.clearUser() - ユーザー情報をクリア');
    _currentUser = null;
    _userDocRef = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
