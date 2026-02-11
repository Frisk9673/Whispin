import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/environment.dart';
import '../utils/app_logger.dart';

/// プロフィール画像のアップロード・管理サービス
class ProfileImageService {
  static const String _logName = 'ProfileImageService';
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  /// ギャラリーから画像を選択
  Future<XFile?> pickImageFromGallery() async {
    logger.section('画像選択開始', name: _logName);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        logger.success('画像選択完了: ${image.path}', name: _logName);
        logger.info('ファイルサイズ: ${await image.length()} bytes', name: _logName);
      } else {
        logger.info('画像選択キャンセル', name: _logName);
      }

      return image;
    } catch (e, stack) {
      logger.error('画像選択エラー: $e', 
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// カメラで撮影
  Future<XFile?> takePhoto() async {
    logger.section('カメラ撮影開始', name: _logName);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        logger.success('撮影完了: ${image.path}', name: _logName);
        logger.info('ファイルサイズ: ${await image.length()} bytes', name: _logName);
      } else {
        logger.info('撮影キャンセル', name: _logName);
      }

      return image;
    } catch (e, stack) {
      logger.error('撮影エラー: $e', 
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Firebase Storageに画像をアップロード
  /// 
  /// [userId] ユーザーID（メールアドレス）
  /// [imageFile] アップロードする画像ファイル
  /// 
  /// 戻り値: アップロードされた画像のダウンロードURL
  Future<String> uploadProfileImage({
    required String userId,
    required XFile imageFile,
  }) async {
    logger.section('画像アップロード開始', name: _logName);
    logger.info('userId: $userId', name: _logName);
    logger.info(
      '実行環境: ${kIsWeb ? "web" : "native"}, emulator=${Environment.shouldUseFirebaseEmulator}',
      name: _logName,
    );
    String? uploadFilePath;
    int? uploadBytesLength;
    String? refFullPath;
    TaskState? snapshotState;
    StreamSubscription<TaskSnapshot>? subscription;

    try {
      // ===== 修正: 安全なファイル名生成 =====
      // メールアドレスの @ と . を _ に置換（エンコーディング問題を回避）
      final String safeUserId = userId
          .replaceAll('@', '_at_')
          .replaceAll('.', '_dot_')
          .replaceAll('+', '_plus_');
      
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'profile_$timestamp.jpg';
      final String filePath = 'profile_images/$safeUserId/$fileName';
      uploadFilePath = filePath;

      logger.start('アップロード先: $filePath', name: _logName);
      logger.debug('元ファイルパス: ${imageFile.path}', name: _logName);

      // Storageリファレンスを取得
      final Reference ref = _storage.ref().child(filePath);
      refFullPath = ref.fullPath;

      // メタデータを設定
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId, // 元のメールアドレスを保存
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Web環境とモバイル環境で処理を分岐
      final UploadTask uploadTask;
      
      if (kIsWeb) {
        // Web環境: XFileからbytesを取得
        final bytes = await imageFile.readAsBytes();
        uploadBytesLength = bytes.length;
        logger.info('Web画像bytes: ${bytes.length} bytes', name: _logName);

        if (!Environment.shouldUseFirebaseEmulator) {
          logger.info(
            'PROFILE_UPLOAD_WEB_START bucket=${_storage.bucket}, filePath=$filePath, contentType=${metadata.contentType}, bytesLength=${bytes.length}, authUid=${_auth.currentUser?.uid}, refFullPath=$refFullPath',
            name: _logName,
          );
        }

        if (bytes.isEmpty) {
          logger.error('アップロード中止: 画像bytesが空です', name: _logName);
          throw StateError('画像データが空のためアップロードできません。');
        }

        uploadTask = ref.putData(bytes, metadata);
      } else {
        // モバイル環境: Fileオブジェクトを使用
        final File file = File(imageFile.path);
        final fileExists = await file.exists();
        logger.info('Native画像ファイル存在確認: $fileExists (${file.path})', name: _logName);

        if (!fileExists) {
          logger.error('アップロード中止: 画像ファイルが見つかりません', name: _logName);
          throw StateError('画像ファイルが見つからないためアップロードできません。');
        }

        final int nativeFileLength = await file.length();
        logger.info('Native画像ファイルサイズ: $nativeFileLength bytes', name: _logName);
        uploadBytesLength = nativeFileLength;
        uploadTask = ref.putFile(file, metadata);
      }

      final Duration? uploadTimeout =
          kIsWeb ? const Duration(seconds: 45) : null;

      // 進捗をログ出力
      if (kIsWeb) {
        // firebase_storage_web では snapshotEvents が channel-error を起こすケースがあるため、
        // Webでは進捗監視を無効化してアップロード本体を優先する。
        logger.info('Web環境のため進捗ストリーム監視をスキップ', name: _logName);
      } else {
        try {
          subscription = uploadTask.snapshotEvents.listen(
            (TaskSnapshot snapshot) {
              final total = snapshot.totalBytes;
              final transferred = snapshot.bytesTransferred;
              final progress =
                  total > 0 ? (transferred / total) * 100 : 0.0;

              logger.debug(
                'アップロード進捗: ${progress.toStringAsFixed(1)}% ($transferred/$total)',
                name: _logName,
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              logger.warning(
                'アップロード進捗ストリームエラー: 進捗監視のみ停止し、アップロード本体は継続します。 error=$error, stackTrace=$stackTrace',
                name: _logName,
              );
            },
          );
        } catch (e, stack) {
          logger.warning(
            'アップロード進捗ストリーム購読開始失敗: 進捗監視なしでアップロードを継続します。 error=$e, stackTrace=$stack',
            name: _logName,
          );
        }
      }

      // アップロード完了を待つ
      late final TaskSnapshot snapshot;
      try {
        snapshot = await (uploadTimeout != null
            ? uploadTask.timeout(uploadTimeout)
            : uploadTask);
        snapshotState = snapshot.state;
      } on FirebaseException catch (e, stack) {
        _logFirebaseException(
          searchKey: 'PROFILE_UPLOAD_WEB_FAILURE',
          phase: 'uploadTask.await',
          exception: e,
          stackTrace: stack,
          filePath: uploadFilePath,
          bytesLength: uploadBytesLength,
          refFullPath: refFullPath,
          snapshotState: snapshotState,
        );
        rethrow;
      } on TimeoutException catch (e, stack) {
        logger.error(
          'アップロード失敗(TimeoutException): code=timeout, message=${e.message}, filePath=$uploadFilePath, bytesLength=$uploadBytesLength, kIsWeb=$kIsWeb',
          name: _logName,
          error: e,
          stackTrace: stack,
        );

        try {
          final bool canceled = await uploadTask.cancel();
          logger.warning(
            'タイムアウト後のアップロードキャンセル結果: canceled=$canceled, filePath=$uploadFilePath, bytesLength=$uploadBytesLength, kIsWeb=$kIsWeb',
            name: _logName,
          );
        } catch (cancelError, cancelStack) {
          logger.warning(
            'タイムアウト後のアップロードキャンセル失敗: error=$cancelError, stackTrace=$cancelStack, filePath=$uploadFilePath, bytesLength=$uploadBytesLength, kIsWeb=$kIsWeb',
            name: _logName,
          );
        }

        throw StateError('アップロードがタイムアウトしました');
      }

      logger.success('アップロード完了', name: _logName);

      // ===== 修正: 環境フラグベースのURL取得分岐 =====
      final bool useEmulatorUrl =
          kIsWeb && Environment.shouldUseFirebaseEmulator;
      late final String downloadURL;

      logger.info(
        'URL取得分岐: ${useEmulatorUrl ? "emulator-manual-url" : "getDownloadURL"}',
        name: _logName,
      );

      if (useEmulatorUrl) {
        downloadURL = _buildEmulatorDownloadUrl(filePath);
        logger.info('エミュレーターURL構築: $downloadURL', name: _logName);
      } else {
        try {
          downloadURL = await snapshot.ref.getDownloadURL();
        } on FirebaseException catch (e, stack) {
          _logFirebaseException(
            searchKey: 'PROFILE_UPLOAD_WEB_GET_URL_FAILURE',
            phase: 'getDownloadURL',
            exception: e,
            stackTrace: stack,
            filePath: uploadFilePath,
            bytesLength: uploadBytesLength,
            refFullPath: snapshot.ref.fullPath,
            snapshotState: snapshot.state,
          );

          if (kIsWeb && Environment.shouldUseFirebaseEmulator) {
            logger.warning('フォールバック分岐: emulator-manual-url', name: _logName);
            downloadURL = _buildEmulatorDownloadUrl(filePath);
          } else {
            logger.warning('フォールバック分岐なし: 例外再送出', name: _logName);
            rethrow;
          }
        }
      }
      
      logger.success('ダウンロードURL取得完了', name: _logName);
      logger.debug('URL: $downloadURL', name: _logName);

      logger.section('画像アップロード成功', name: _logName);
      return downloadURL;
      
    } on FirebaseException catch (e, stack) {
      _logFirebaseException(
        searchKey: 'PROFILE_UPLOAD_WEB_FAILURE',
        phase: 'uploadProfileImage.catch',
        exception: e,
        stackTrace: stack,
        filePath: uploadFilePath,
        bytesLength: uploadBytesLength,
        refFullPath: refFullPath,
        snapshotState: snapshotState,
      );

      if (kIsWeb && Environment.shouldUseFirebaseEmulator && e.code == 'object-not-found') {
        // エミュレーター特有のエラー
        logger.warning('catch分岐: object-not-found (再送出して上位に通知)', name: _logName);
      }

      rethrow;

    } on TimeoutException catch (e, stack) {
      logger.error(
        'TimeoutException: code=timeout, message=${e.message}, filePath=$uploadFilePath, bytesLength=$uploadBytesLength, kIsWeb=$kIsWeb',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
      
    } catch (e, stack) {
      logger.error('アップロードエラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    } finally {
      try {
        await subscription?.cancel();
      } catch (e, stack) {
        logger.warning(
          '進捗ストリーム購読解除時エラー: error=$e, stackTrace=$stack',
          name: _logName,
        );
      }
    }
  }

  void _logFirebaseException({
    required String searchKey,
    required String phase,
    required FirebaseException exception,
    required StackTrace stackTrace,
    String? filePath,
    int? bytesLength,
    String? refFullPath,
    TaskState? snapshotState,
  }) {
    logger.error(
      '$searchKey summary phase=$phase, code=${exception.code}, message=${exception.message}, plugin=${exception.plugin}, filePath=$filePath, bytesLength=$bytesLength, refFullPath=$refFullPath, snapshotState=${snapshotState?.name}, kIsWeb=$kIsWeb, emulator=${Environment.shouldUseFirebaseEmulator}',
      name: _logName,
    );

    logger.error(
      '$searchKey detail exception=$exception, code=${exception.code}, message=${exception.message}, plugin=${exception.plugin}, firebaseStackTrace=${exception.stackTrace}, stackTrace=$stackTrace, filePath=$filePath, bytesLength=$bytesLength, bucket=${_storage.bucket}, authUid=${_auth.currentUser?.uid}, refFullPath=$refFullPath, snapshotState=${snapshotState?.name}',
      name: _logName,
      error: exception,
      stackTrace: stackTrace,
    );
  }

  String _buildEmulatorDownloadUrl(String filePath) {
    final bucketName = _storage.bucket;
    final host = Environment.emulatorHost;
    final port = Environment.storageEmulatorPort;

    return 'http://$host:$port/v0/b/$bucketName/o/${Uri.encodeComponent(filePath)}?alt=media';
  }

  /// 既存のプロフィール画像を削除
  /// 
  /// [imageUrl] 削除する画像のURL
  Future<void> deleteProfileImage(String imageUrl) async {
    logger.section('画像削除開始', name: _logName);
    logger.info('URL: $imageUrl', name: _logName);

    try {
      // ===== 修正: エミュレーターURL対応 =====
      if (imageUrl.contains('localhost:9199')) {
        // エミュレーター: URLからパスを抽出
        final uri = Uri.parse(imageUrl);
        final pathMatch = RegExp(r'/o/(.+?)\?').firstMatch(imageUrl);
        
        if (pathMatch != null) {
          final encodedPath = pathMatch.group(1)!;
          final filePath = Uri.decodeComponent(encodedPath);
          
          logger.start('削除中 (エミュレーター): $filePath', name: _logName);
          
          final Reference ref = _storage.ref().child(filePath);
          await ref.delete();
          
          logger.success('画像削除完了', name: _logName);
        } else {
          logger.warning('URLからパス抽出失敗: $imageUrl', name: _logName);
        }
      } else {
        // 本番環境: 通常のrefFromURL
        final Reference ref = _storage.refFromURL(imageUrl);
        
        logger.start('削除中: ${ref.fullPath}', name: _logName);
        
        await ref.delete();
        
        logger.success('画像削除完了', name: _logName);
      }
      
      logger.section('画像削除成功', name: _logName);
      
    } catch (e, stack) {
      logger.error('削除エラー: $e', 
          name: _logName, error: e, stackTrace: stack);
      // 削除エラーは致命的ではないため、ログのみ
    }
  }

  /// ユーザーの全プロフィール画像を削除（アカウント削除時）
  /// 
  /// [userId] ユーザーID
  Future<void> deleteAllUserImages(String userId) async {
    logger.section('ユーザー画像全削除開始', name: _logName);
    logger.info('userId: $userId', name: _logName);

    try {
      // 安全なユーザーIDに変換
      final String safeUserId = userId
          .replaceAll('@', '_at_')
          .replaceAll('.', '_dot_')
          .replaceAll('+', '_plus_');
      
      final String folderPath = 'profile_images/$safeUserId';
      
      final Reference folderRef = _storage.ref().child(folderPath);
      final ListResult result = await folderRef.listAll();
      
      logger.info('削除対象: ${result.items.length}件', name: _logName);
      
      // 全ファイルを削除
      for (final Reference fileRef in result.items) {
        logger.debug('削除中: ${fileRef.name}', name: _logName);
        await fileRef.delete();
      }
      
      logger.success('ユーザー画像全削除完了', name: _logName);
      logger.section('削除処理成功', name: _logName);
      
    } catch (e, stack) {
      logger.error('全削除エラー: $e', 
          name: _logName, error: e, stackTrace: stack);
      // エラーは致命的ではないため続行
    }
  }
}
