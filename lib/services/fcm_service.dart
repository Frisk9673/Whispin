import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import '../utils/app_logger.dart';

/// Firebase Cloud Messaging サービス
///
/// プッシュ通知の送受信、トークン管理を行います
class FCMService {
  static const String _logName = 'FCMService';
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  // 招待通知を受信したときのコールバック
  Function(Map<String, dynamic>)? onInvitationReceived;
  
  /// FCMサービスを初期化
  Future<void> initialize() async {
    logger.section('FCMService初期化開始', name: _logName);
    
    try {
      // 1. 通知権限をリクエスト
      logger.start('通知権限をリクエスト中...', name: _logName);
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        logger.success('通知権限が許可されました', name: _logName);
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        logger.info('仮の通知権限が許可されました', name: _logName);
      } else {
        logger.warning('通知権限が拒否されました', name: _logName);
      }
      
      // 2. FCMトークンを取得
      logger.start('FCMトークンを取得中...', name: _logName);
      _fcmToken = await _firebaseMessaging.getToken();
      logger.success('FCMトークン取得完了', name: _logName);
      logger.debug('Token: ${_fcmToken?.substring(0, 20)}...', name: _logName);
      
      // 3. トークン更新リスナーを設定
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        logger.info('FCMトークンが更新されました', name: _logName);
        _fcmToken = newToken;
        logger.debug('New Token: ${newToken.substring(0, 20)}...', name: _logName);
      });
      
      // 4. ローカル通知を初期化
      await _initializeLocalNotifications();
      
      // 5. メッセージハンドラーを設定
      _setupMessageHandlers();
      
      logger.section('FCMService初期化完了', name: _logName);
    } catch (e, stack) {
      logger.error('FCMService初期化エラー: $e', 
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  /// ローカル通知を初期化
  Future<void> _initializeLocalNotifications() async {
    logger.start('ローカル通知初期化中...', name: _logName);
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    logger.success('ローカル通知初期化完了', name: _logName);
  }
  
  /// メッセージハンドラーを設定
  void _setupMessageHandlers() {
    logger.start('メッセージハンドラー設定中...', name: _logName);
    
    // フォアグラウンドメッセージ
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // バックグラウンド・終了状態からのメッセージ（アプリ起動）
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    logger.success('メッセージハンドラー設定完了', name: _logName);
  }
  
  /// フォアグラウンドでメッセージを受信したときの処理
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    logger.section('フォアグラウンドメッセージ受信', name: _logName);
    logger.info('From: ${message.from}', name: _logName);
    logger.info('Data: ${message.data}', name: _logName);
    
    if (message.notification != null) {
      logger.info('Title: ${message.notification!.title}', name: _logName);
      logger.info('Body: ${message.notification!.body}', name: _logName);
    }
    
    // 招待通知の場合
    if (message.data['type'] == 'room_invitation') {
      logger.info('ルーム招待通知を検出', name: _logName);
      
      // ローカル通知を表示
      await _showLocalNotification(
        title: message.notification?.title ?? 'ルーム招待',
        body: message.notification?.body ?? '新しい招待があります',
        payload: message.data.toString(),
      );
      
      // コールバックを呼び出し
      if (onInvitationReceived != null) {
        onInvitationReceived!(message.data);
      }
    }
  }
  
  /// アプリが開かれたときのメッセージ処理（バックグラウンド・終了状態から）
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    logger.section('アプリ起動メッセージ処理', name: _logName);
    logger.info('Data: ${message.data}', name: _logName);
    
    // 招待通知の場合
    if (message.data['type'] == 'room_invitation') {
      logger.info('招待からアプリを起動', name: _logName);
      
      // コールバックを呼び出し
      if (onInvitationReceived != null) {
        onInvitationReceived!(message.data);
      }
    }
  }
  
  /// 通知がタップされたときの処理
  void _onNotificationTapped(NotificationResponse response) {
    logger.section('通知タップ処理', name: _logName);
    logger.info('Payload: ${response.payload}', name: _logName);
    
    // TODO: ペイロードから招待情報を取得してコールバック呼び出し
  }
  
  /// ローカル通知を表示
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    logger.debug('ローカル通知表示: $title', name: _logName);
    
    const androidDetails = AndroidNotificationDetails(
      'room_invitation_channel',
      'ルーム招待',
      channelDescription: 'ルームへの招待通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  /// アプリ起動時に保留中のメッセージをチェック
  Future<Map<String, dynamic>?> checkInitialMessage() async {
    logger.section('初期メッセージチェック開始', name: _logName);
    
    try {
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      
      if (initialMessage != null) {
        logger.success('初期メッセージを検出', name: _logName);
        logger.info('Data: ${initialMessage.data}', name: _logName);
        
        if (initialMessage.data['type'] == 'room_invitation') {
          logger.info('招待メッセージを検出', name: _logName);
          return initialMessage.data;
        }
      } else {
        logger.info('初期メッセージなし', name: _logName);
      }
      
      return null;
    } catch (e, stack) {
      logger.error('初期メッセージチェックエラー: $e',
          name: _logName, error: e, stackTrace: stack);
      return null;
    }
  }
  
  /// 招待通知を送信（Cloud Functions経由）
  ///
  /// 実際の送信はCloud Functionsで行われる想定
  /// このメソッドはCloud Functionsのトリガーとなるデータを作成
  Future<void> sendInvitationNotification({
    required String inviteeId,
    required String inviterName,
    required String roomName,
    required String roomId,
    required String invitationId,
  }) async {
    logger.section('招待通知送信準備', name: _logName);
    logger.info('To: $inviteeId', name: _logName);
    logger.info('From: $inviterName', name: _logName);
    logger.info('Room: $roomName', name: _logName);
    
    // Cloud Functionsで処理されるため、ここでは準備のみ
    // 実際の通知送信はFirestore Triggersで実行される
    
    logger.success('招待通知データ準備完了', name: _logName);
    logger.info('Cloud Functionsが通知を送信します', name: _logName);
  }
}

/// バックグラウンドメッセージハンドラー（トップレベル関数）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.section('バックグラウンドメッセージ受信', name: 'FCM_BG');
  logger.info('Message ID: ${message.messageId}', name: 'FCM_BG');
  logger.info('Data: ${message.data}', name: 'FCM_BG');
  
  // バックグラウンドでの処理（必要最小限）
  if (message.data['type'] == 'room_invitation') {
    logger.info('招待通知（バックグラウンド）', name: 'FCM_BG');
  }
}