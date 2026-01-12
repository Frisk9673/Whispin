import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import '../models/user.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';

class UserRegisterService {
  final _auth = fba.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  static const String _logName = 'UserRegisterService';

  /// ユーザー登録処理（StorageService統合版）
  /// 
  /// [user] 登録するユーザー情報
  /// [password] パスワード
  /// [storageService] データ永続化サービス（必須）
  Future<bool> register({
    required User user, 
    required String password,
    required StorageService storageService,
  }) async {
    logger.section('register() 開始', name: _logName);

    try {
      // 入力値ログ
      logger.info('入力されたユーザーデータ（User → toMap）:', name: _logName);
      user.toMap().forEach((key, value) {
        logger.info('  $key: $value', name: _logName);
      });
      logger.info('=============================================', name: _logName);

      logger.start('FirebaseAuth にユーザー作成リクエスト送信中...', name: _logName);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: user.id,
        password: password,
      );

      logger.success('Auth 登録成功!', name: _logName);
      logger.info('  UID: ${credential.user?.uid}', name: _logName);

      final docId = user.phoneNumber ?? user.id;

      logger.start('Firestore(User/$docId) にユーザーデータ登録中...', name: _logName);

      final inputData = {
        ...user.toMap(),
        "createdAt": FieldValue.serverTimestamp(),
      };

      await _firestore.collection('User').doc(docId).set(inputData);

      logger.success('Firestore 登録完了!', name: _logName);

      // ===== ✅ StorageServiceにもユーザーを追加 =====
      logger.start('StorageService にユーザー追加中...', name: _logName);
      
      // 既存ユーザーリストにない場合のみ追加
      final existingUser = storageService.users.firstWhere(
        (u) => u.id == user.id,
        orElse: () => User(id: ''),
      );

      if (existingUser.id.isEmpty) {
        storageService.users.add(user);
        logger.success('StorageService にユーザー追加完了', name: _logName);
      } else {
        logger.warning('StorageService に既に存在するため追加スキップ', name: _logName);
      }

      // StorageServiceを保存
      logger.start('StorageService.save() 実行中...', name: _logName);
      await storageService.save();
      logger.success('StorageService.save() 完了', name: _logName);
      // =======================================

      // Firestore から取得して整合性チェック
      logger.start('Firestore(User/$docId) の保存済みデータ取得中...', name: _logName);

      final doc = await _firestore.collection('User').doc(docId).get();

      if (!doc.exists) {
        logger.warning('Firestore にデータが存在しません！（保存失敗の可能性）', name: _logName);
        return false;
      }

      logger.section('Firestore に保存された実データ', name: _logName);
      final savedData = doc.data()!;
      savedData.forEach((key, value) {
        logger.info('  $key: $value', name: _logName);
      });
      logger.info('=========================================', name: _logName);

      // 自動整合性チェック
      logger.section('自動整合性チェック開始', name: _logName);

      for (final entry in user.toMap().entries) {
        final key = entry.key;
        final inputValue = entry.value;
        final savedValue = savedData[key];

        if (inputValue == savedValue) {
          logger.success('$key → 一致 ($inputValue)', name: _logName);
        } else {
          logger.warning('$key → 不一致', name: _logName);
          logger.info('     入力値: $inputValue', name: _logName);
          logger.info('     Firestore値: $savedValue', name: _logName);
        }
      }

      logger.section('自動整合性チェック終了', name: _logName);
      logger.section('register() 正常終了', name: _logName);
      return true;

    } on fba.FirebaseAuthException catch (e) {
      logger.error('FirebaseAuthException 発生: ${e.code}', 
        name: _logName, 
        error: e,
      );
      logger.section('register() 異常終了（Auth エラー）', name: _logName);
      throw "Auth エラー: ${e.code}";

    } catch (e, stack) {
      logger.error('その他のエラー発生: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      logger.section('register() 異常終了', name: _logName);
      throw "登録エラー: $e";
    }
  }
}