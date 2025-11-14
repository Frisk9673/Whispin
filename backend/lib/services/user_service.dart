import 'dart:convert';
import 'dart:io';
import 'package:googleapis/firestore/v1.dart' as firestore_api;
import 'package:googleapis_auth/auth_io.dart';

class UserService {
  late final firestore_api.FirestoreApi firestore;

  UserService() {
    _initFirestore();
  }

  /// Firestore 初期化
  Future<void> _initFirestore() async {
    final serviceAccountJson = File('serviceAccountKey.json').readAsStringSync();
    final serviceAccountMap = jsonDecode(serviceAccountJson);

    final credentials = ServiceAccountCredentials.fromJson(serviceAccountMap);

    final client = await clientViaServiceAccount(
      credentials,
      [firestore_api.FirestoreApi.cloudPlatformScope],
    );

    firestore = firestore_api.FirestoreApi(client);
  }

  /// アカウント作成はこのメソッドのみ
  Future<bool> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required String nickname,
  }) async {
    try {
      final document = firestore_api.Document(
        fields: {
          "TEL_ID": firestore_api.Value(stringValue: email),
          "FirstName": firestore_api.Value(stringValue: firstName),
          "LastName": firestore_api.Value(stringValue: lastName),
          "Nickname": firestore_api.Value(stringValue: nickname),
          "Rate": firestore_api.Value(integerValue: '0'),
          "Premium": firestore_api.Value(booleanValue: false),
          "RoomCount": firestore_api.Value(integerValue: '0'),
          "CreatedAt": firestore_api.Value(
            timestampValue: DateTime.now().toUtc().toIso8601String(),
          ),
          "LastUpdated_Premium": firestore_api.Value(nullValue: 'NULL_VALUE'),
          "DeletedAt": firestore_api.Value(nullValue: 'NULL_VALUE'),
        },
      );

      await firestore.projects.databases.documents.createDocument(
        document,
        'projects/kazutxt-firebase-overvie-8d3e4/databases/(default)/documents/users',
        email,
      );

      print('ユーザー作成成功: $email');
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }
}
