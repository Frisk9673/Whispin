import 'app_logger.dart';

/// アプリケーション全体で使用する例外の基底クラス
///
/// 共通方針（例外クラスの用途）:
/// - ドメインで想定可能な失敗は `AppException` 派生クラスで表現する。
/// - `message` はユーザー/運用者が状況を理解できる文章にし、`code` は機械判定用に使う。
/// - `originalError` と `stackTrace` は、原因調査が必要な層（service/repository）で保持する。
///
/// throw / rethrow 指針:
/// - 新しい文脈（メッセージ/コード/補足情報）を付与する場合は `throw XxxException(...)`。
/// - 既に適切に分類された例外を上位にそのまま伝搬する場合は `rethrow`。
/// - `catch (e, st)` したら、必要に応じて `originalError: e`, `stackTrace: st` を渡す。
///
/// 主要呼び出し元:
/// - services: 入力検証やユースケース失敗を `ValidationException` 等で送出。
/// - repositories: 通信/永続化失敗を `NetworkException` などへ変換して送出。
/// - routes/UI: `userMessage` を表示し、必要に応じてリカバリー導線へ遷移。
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  /// ログ出力用の詳細メッセージ
  String get detailMessage {
    final buffer = StringBuffer();
    buffer.writeln('[$runtimeType] $message');
    if (code != null) buffer.writeln('Code: $code');
    if (originalError != null) buffer.writeln('Original: $originalError');
    return buffer.toString();
  }

  /// ユーザーに表示する簡潔なメッセージ
  String get userMessage => message;

  /// ログに記録
  void log({String name = 'AppException'}) {
    logger.error(
      detailMessage,
      name: name,
      error: originalError,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => detailMessage;
}

// ===== バリデーション例外 =====

/// バリデーションエラー
///
/// 入力値検証、ビジネスルール違反などで使用
///
/// 使用例:
/// ```dart
/// if (email.isEmpty) {
///   throw ValidationException(
///     message: 'メールアドレスを入力してください',
///     field: 'email',
///   );
/// }
/// ```
class ValidationException extends AppException {
  /// エラーが発生したフィールド名
  final String? field;

  /// 複数フィールドのエラー（フィールド名: エラーメッセージ）
  final Map<String, String>? fieldErrors;

  ValidationException({
    required String message,
    this.field,
    this.fieldErrors,
    String? code,
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'VALIDATION_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  /// 単一フィールドのエラーかどうか
  bool get isSingleFieldError => field != null;

  /// 複数フィールドのエラーかどうか
  bool get isMultiFieldError => fieldErrors != null && fieldErrors!.isNotEmpty;

  /// 特定フィールドのエラーメッセージを取得
  String? getFieldError(String fieldName) {
    if (field == fieldName) return message;
    return fieldErrors?[fieldName];
  }

  @override
  String get detailMessage {
    final buffer = StringBuffer();
    buffer.writeln('[ValidationException] $message');
    if (code != null) buffer.writeln('Code: $code');
    if (field != null) buffer.writeln('Field: $field');
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      buffer.writeln('Field Errors:');
      fieldErrors!.forEach((key, value) {
        buffer.writeln('  - $key: $value');
      });
    }
    if (originalError != null) buffer.writeln('Original: $originalError');
    return buffer.toString();
  }

  /// 複数フィールドエラーを作成するファクトリ
  factory ValidationException.multiField({
    required Map<String, String> errors,
    String? code,
  }) {
    return ValidationException(
      message: '入力内容に誤りがあります',
      fieldErrors: errors,
      code: code,
    );
  }

  /// 必須フィールドエラーを作成するファクトリ
  factory ValidationException.required(String fieldName) {
    return ValidationException(
      message: 'この項目は必須です',
      field: fieldName,
      code: 'REQUIRED_FIELD',
    );
  }

  /// 文字数制限エラーを作成するファクトリ
  factory ValidationException.maxLength({
    required String fieldName,
    required int maxLength,
    int? currentLength,
  }) {
    return ValidationException(
      message: currentLength != null
          ? '$maxLength文字以内で入力してください（現在: $currentLength文字）'
          : '$maxLength文字以内で入力してください',
      field: fieldName,
      code: 'MAX_LENGTH_EXCEEDED',
    );
  }

  /// 最小文字数エラーを作成するファクトリ
  factory ValidationException.minLength({
    required String fieldName,
    required int minLength,
    int? currentLength,
  }) {
    return ValidationException(
      message: currentLength != null
          ? '$minLength文字以上入力してください（現在: $currentLength文字）'
          : '$minLength文字以上入力してください',
      field: fieldName,
      code: 'MIN_LENGTH_NOT_MET',
    );
  }

  /// メールアドレス形式エラー
  factory ValidationException.invalidEmail(String fieldName) {
    return ValidationException(
      message: '有効なメールアドレスを入力してください',
      field: fieldName,
      code: 'INVALID_EMAIL',
    );
  }

  /// パスワード不一致エラー
  factory ValidationException.passwordMismatch() {
    return ValidationException(
      message: 'パスワードが一致しません',
      field: 'passwordConfirm',
      code: 'PASSWORD_MISMATCH',
    );
  }

  /// ビジネスルール違反エラー
  factory ValidationException.businessRule({
    required String message,
    String? field,
    String? code,
  }) {
    return ValidationException(
      message: message,
      field: field,
      code: code ?? 'BUSINESS_RULE_VIOLATION',
    );
  }
}

// ===== ネットワーク例外 =====

/// ネットワークエラー
///
/// API呼び出し、Firestore操作、ネットワーク通信などで使用
///
/// 使用例:
/// ```dart
/// try {
///   await firestore.collection('users').doc(id).get();
/// } catch (e) {
///   throw NetworkException(
///     message: 'データの取得に失敗しました',
///     endpoint: 'users/$id',
///     originalError: e,
///   );
/// }
/// ```
class NetworkException extends AppException {
  /// エンドポイント（Firestoreパス、API URL等）
  final String? endpoint;

  /// HTTPステータスコード（該当する場合）
  final int? statusCode;

  /// リトライ可能かどうか
  final bool isRetryable;

  NetworkException({
    required String message,
    this.endpoint,
    this.statusCode,
    this.isRetryable = true,
    String? code,
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? _generateCode(statusCode),
          originalError: originalError,
          stackTrace: stackTrace,
        );

  static String _generateCode(int? statusCode) {
    if (statusCode == null) return 'NETWORK_ERROR';
    if (statusCode >= 500) return 'SERVER_ERROR';
    if (statusCode >= 400) return 'CLIENT_ERROR';
    return 'NETWORK_ERROR';
  }

  @override
  String get detailMessage {
    final buffer = StringBuffer();
    buffer.writeln('[NetworkException] $message');
    if (code != null) buffer.writeln('Code: $code');
    if (endpoint != null) buffer.writeln('Endpoint: $endpoint');
    if (statusCode != null) buffer.writeln('Status Code: $statusCode');
    buffer.writeln('Retryable: $isRetryable');
    if (originalError != null) buffer.writeln('Original: $originalError');
    return buffer.toString();
  }

  @override
  String get userMessage {
    // リトライ可能な場合はその旨を伝える
    if (isRetryable) {
      return '$message\nもう一度お試しください。';
    }
    return message;
  }

  /// タイムアウトエラーを作成するファクトリ
  factory NetworkException.timeout({
    String? endpoint,
    int? timeoutSeconds,
  }) {
    return NetworkException(
      message: timeoutSeconds != null
          ? '接続がタイムアウトしました（${timeoutSeconds}秒）'
          : '接続がタイムアウトしました',
      endpoint: endpoint,
      code: 'TIMEOUT',
      isRetryable: true,
    );
  }

  /// 接続エラーを作成するファクトリ
  factory NetworkException.connectionFailed({
    String? endpoint,
    Object? originalError,
  }) {
    return NetworkException(
      message: 'ネットワークに接続できません',
      endpoint: endpoint,
      code: 'CONNECTION_FAILED',
      originalError: originalError,
      isRetryable: true,
    );
  }

  /// 認証エラーを作成するファクトリ
  factory NetworkException.unauthorized({
    String? endpoint,
    Object? originalError,
  }) {
    return NetworkException(
      message: '認証に失敗しました',
      endpoint: endpoint,
      statusCode: 401,
      code: 'UNAUTHORIZED',
      originalError: originalError,
      isRetryable: false,
    );
  }

  /// アクセス拒否エラーを作成するファクトリ
  factory NetworkException.forbidden({
    String? endpoint,
    Object? originalError,
  }) {
    return NetworkException(
      message: 'アクセスが拒否されました',
      endpoint: endpoint,
      statusCode: 403,
      code: 'FORBIDDEN',
      originalError: originalError,
      isRetryable: false,
    );
  }

  /// リソース未検出エラーを作成するファクトリ
  factory NetworkException.notFound({
    String? endpoint,
    Object? originalError,
  }) {
    return NetworkException(
      message: 'リソースが見つかりません',
      endpoint: endpoint,
      statusCode: 404,
      code: 'NOT_FOUND',
      originalError: originalError,
      isRetryable: false,
    );
  }

  /// サーバーエラーを作成するファクトリ
  factory NetworkException.serverError({
    String? endpoint,
    int? statusCode,
    Object? originalError,
  }) {
    return NetworkException(
      message: 'サーバーエラーが発生しました',
      endpoint: endpoint,
      statusCode: statusCode ?? 500,
      code: 'SERVER_ERROR',
      originalError: originalError,
      isRetryable: true,
    );
  }
}

// ===== データベース例外 =====

/// データベースエラー
///
/// Firestore操作、ローカルストレージ、データ整合性などで使用
///
/// 使用例:
/// ```dart
/// try {
///   await userRepository.create(user);
/// } catch (e) {
///   throw DatabaseException(
///     message: 'ユーザーの作成に失敗しました',
///     operation: 'CREATE',
///     collection: 'users',
///     originalError: e,
///   );
/// }
/// ```
class DatabaseException extends AppException {
  /// データベース操作の種類
  final DatabaseOperation? operation;

  /// コレクション名（Firestore）またはテーブル名
  final String? collection;

  /// ドキュメントID
  final String? documentId;

  /// データ整合性エラーかどうか
  final bool isIntegrityError;

  DatabaseException({
    required String message,
    this.operation,
    this.collection,
    this.documentId,
    this.isIntegrityError = false,
    String? code,
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? _generateCode(operation),
          originalError: originalError,
          stackTrace: stackTrace,
        );

  static String _generateCode(DatabaseOperation? operation) {
    if (operation == null) return 'DATABASE_ERROR';
    switch (operation) {
      case DatabaseOperation.create:
        return 'DB_CREATE_ERROR';
      case DatabaseOperation.read:
        return 'DB_READ_ERROR';
      case DatabaseOperation.update:
        return 'DB_UPDATE_ERROR';
      case DatabaseOperation.delete:
        return 'DB_DELETE_ERROR';
      case DatabaseOperation.query:
        return 'DB_QUERY_ERROR';
    }
  }

  @override
  String get detailMessage {
    final buffer = StringBuffer();
    buffer.writeln('[DatabaseException] $message');
    if (code != null) buffer.writeln('Code: $code');
    if (operation != null) buffer.writeln('Operation: ${operation!.name}');
    if (collection != null) buffer.writeln('Collection: $collection');
    if (documentId != null) buffer.writeln('Document ID: $documentId');
    buffer.writeln('Integrity Error: $isIntegrityError');
    if (originalError != null) buffer.writeln('Original: $originalError');
    return buffer.toString();
  }

  /// ドキュメント未検出エラーを作成するファクトリ
  factory DatabaseException.notFound({
    required String collection,
    required String documentId,
  }) {
    return DatabaseException(
      message: 'データが見つかりません',
      operation: DatabaseOperation.read,
      collection: collection,
      documentId: documentId,
      code: 'DOCUMENT_NOT_FOUND',
    );
  }

  /// 重複エラーを作成するファクトリ
  factory DatabaseException.duplicate({
    required String collection,
    required String documentId,
  }) {
    return DatabaseException(
      message: 'データが既に存在します',
      operation: DatabaseOperation.create,
      collection: collection,
      documentId: documentId,
      code: 'DUPLICATE_DOCUMENT',
      isIntegrityError: true,
    );
  }

  /// 整合性エラーを作成するファクトリ
  factory DatabaseException.integrityViolation({
    required String message,
    String? collection,
    String? documentId,
    Object? originalError,
  }) {
    return DatabaseException(
      message: message,
      collection: collection,
      documentId: documentId,
      code: 'INTEGRITY_VIOLATION',
      isIntegrityError: true,
      originalError: originalError,
    );
  }

  /// 権限エラーを作成するファクトリ
  factory DatabaseException.permissionDenied({
    required DatabaseOperation operation,
    required String collection,
    String? documentId,
  }) {
    return DatabaseException(
      message: 'データベースへのアクセス権限がありません',
      operation: operation,
      collection: collection,
      documentId: documentId,
      code: 'PERMISSION_DENIED',
    );
  }

  /// トランザクション失敗エラーを作成するファクトリ
  factory DatabaseException.transactionFailed({
    required String message,
    String? collection,
    Object? originalError,
  }) {
    return DatabaseException(
      message: message,
      collection: collection,
      code: 'TRANSACTION_FAILED',
      originalError: originalError,
    );
  }
}

/// データベース操作の種類
enum DatabaseOperation {
  create,
  read,
  update,
  delete,
  query,
}

// ===== ヘルパー関数 =====

/// 例外を適切な型に変換
AppException convertToAppException(
  Object error, {
  StackTrace? stackTrace,
  String? context,
}) {
  // 既にAppExceptionの場合はそのまま返す
  if (error is AppException) return error;

  // FirebaseException等の既知のエラーを変換
  // TODO: 必要に応じて他のエラー型も追加
  final message = context != null ? '$context: $error' : error.toString();

  // デフォルトはNetworkExceptionとして扱う
  return NetworkException(
    message: message,
    originalError: error,
    stackTrace: stackTrace,
  );
}

/// 例外をログに記録してスロー
Never throwWithLog(
  AppException exception, {
  String name = 'AppException',
}) {
  exception.log(name: name);
  throw exception;
}
