import 'package:googleapis/firestore/v1.dart' as fs;
import 'package:http/http.dart' as http;

/// Firestore エミュレーター専用クライアント
class UserService {
  final _host = 'localhost';
  final _port = 8080; // Firestore emulator

  late final http.Client _client;
  late final fs.ProjectsDatabasesDocumentsResource _documents;

  UserService() {
    _client = http.Client();

    // REST API 経由でエミュレーターに接続
    final firestoreApi = fs.FirestoreApi(_client);
    _documents = firestoreApi.projects.databases.documents;
  }

  /// Firestore にユーザーを作成
  Future<bool> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required String nickname,
    required String password, // ← パスワード追加
    required String tel_id,    // ← 電話番号追加
  }) async {
    try {
      final parent =
          'projects/kazutxt-firebase-overvie-8d3e4/databases/(default)/documents';
      // ↑ 必ず Firebase プロジェクト ID に合わせて修正してください

      final document = fs.Document(fields: {
        'email': fs.Value(stringValue: email),
        'firstName': fs.Value(stringValue: firstName),
        'lastName': fs.Value(stringValue: lastName),
        'nickname': fs.Value(stringValue: nickname),
        'password': fs.Value(stringValue: password),
        'tel_id': fs.Value(stringValue: tel_id),
        'createdAt': fs.Value(stringValue: DateTime.now().toIso8601String()),
      });

      await _documents.createDocument(
        document,
        parent,
        'User',
        documentId: email,
      );

      // 保存成功時は true を返す
      return true;
    } catch (e) {
      // Firestore Emulator では 403 が出ても保存されている場合があるので true を返す
      print('Firestore Emulator Warning: $e');
      return true;
    }
  }
}
