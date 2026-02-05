/// アプリケーション全体で使用する定数
class AppConstants {
  // インスタンス化を防ぐ
  AppConstants._();

  // アプリ情報
  static const String appName = 'Whispin';
  static const String appVersion = '1.0.0';

  // チャットルーム設定
  static const int roomNameMaxLength = 30;
  static const int messageMaxLength = 100;
  static const int defaultChatDurationMinutes = 10;
  static const int extensionDurationMinutes = 5;
  static const int defaultExtensionLimit = 2;
  static const int extensionRequestThresholdMinutes = 2;

  // パスワード設定
  static const int passwordMinLength = 6;
  static const int passwordMaxLength = 50;

  // UI設定
  static const double defaultPadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double buttonHeight = 56.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 140.0;
  static const double avatarSizeSmall = 36.0;

  // アニメーション
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration loadingIndicatorDelay = Duration(milliseconds: 100);

  // ストレージキー
  static const String currentUserKey = 'current_user';
  static const String authTokenKey = 'auth_token';
  static const String themeKey = 'theme_mode';

  // Firestoreコレクション
  static const String usersCollection = 'users';
  static const String roomsCollection = 'rooms';
  static const String friendshipsCollection = 'friendships';
  static const String friendRequestsCollection = 'friendRequests';
  static const String evaluationsCollection = 'evaluations';
  static const String extensionRequestsCollection = 'extensionRequests';
  static const String blocksCollection = 'blocks';
  static const String invitationsCollection = 'invitations';
  static const String administratorCollection = 'administrator';
  static const String questionChatCollection = 'QuestionChat';
  static const String premiumLogCollection = 'Log_Premium';
  static const String premiumCounterCollection = 'PremiumCounter';

  // ルーム状態
  static const int roomStatusWaiting = 0;
  static const int roomStatusActive = 1;
  static const int roomStatusFinished = 2;

  // 延長リクエスト状態
  static const String extensionStatusPending = 'pending';
  static const String extensionStatusApproved = 'approved';
  static const String extensionStatusRejected = 'rejected';

  // フレンド申請状態
  static const String friendRequestStatusPending = 'pending';
  static const String friendRequestStatusAccepted = 'accepted';
  static const String friendRequestStatusRejected = 'rejected';

  // 招待状態
  static const String invitationStatusPending = 'pending';
  static const String invitationStatusAccepted = 'accepted';
  static const String invitationStatusRejected = 'rejected';
  static const String invitationStatusExpired = 'expired';

  // 評価
  static const String ratingThumbsUp = 'thumbs_up';
  static const String ratingThumbsDown = 'thumbs_down';

  // エラーメッセージ
  static const String errorGeneric = 'エラーが発生しました';
  static const String errorNetwork = 'ネットワークエラーが発生しました';
  static const String errorAuth = '認証エラーが発生しました';
  static const String errorNotFound = '見つかりませんでした';
  static const String errorPermission = '権限がありません';

  // 成功メッセージ
  static const String successLogin = 'ログインしました';
  static const String successLogout = 'ログアウトしました';
  static const String successRegister = '登録が完了しました';
  static const String successUpdate = '更新しました';
  static const String successDelete = '削除しました';

  // バリデーションメッセージ
  static const String validationRequired = 'この項目は必須です';
  static const String validationEmailInvalid = '有効なメールアドレスを入力してください';
  static const String validationPasswordShort =
      'パスワードは$passwordMinLength文字以上にしてください';
  static const String validationPasswordMismatch = 'パスワードが一致しません';
  static const String validationMaxLength = '最大文字数を超えています';

  // デフォルト値
  static const String defaultNickname = '未設定';
  static const String defaultMessage = 'メッセージがありません';
  static const String waitingForUser = 'ユーザーを待っています...';
  static const String waitingStatus = '待機中';

  // 日時フォーマット
  static const String timeFormatHHMM = 'HH:mm';
  static const String dateFormatYYYYMMDD = 'yyyy-MM-dd';
  static const String dateTimeFormatFull = 'yyyy-MM-dd HH:mm:ss';

  // ブレークポイント
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
}
