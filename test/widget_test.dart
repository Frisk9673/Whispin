import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:whispin/services/firestore_storage_service.dart';
import 'package:whispin/services/auth_service.dart';
import 'package:whispin/services/chat_service.dart';
import 'package:whispin/services/invitation_service.dart';
import 'package:whispin/providers/chat_provider.dart';
import 'package:whispin/providers/user_provider.dart';
import 'package:whispin/providers/admin_provider.dart';
import 'package:whispin/repositories/user_repository.dart';
import 'package:whispin/repositories/friendship_repository.dart';
import 'package:whispin/repositories/chat_room_repository.dart';
import 'package:whispin/repositories/block_repository.dart';
import 'package:whispin/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // モックサービスを作成
    final storageService = FirestoreStorageService();
    await storageService.initialize();
    
    final authService = AuthService(storageService);
    await authService.initialize();
    
    final chatService = ChatService(storageService);
    final invitationService = InvitationService(storageService);

    // Repository層の初期化
    final userRepository = UserRepository();
    final friendshipRepository = FriendshipRepository();
    final chatRoomRepository = ChatRoomRepository();
    final blockRepository = BlockRepository();

    // Build our app with all providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Providers
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(
            create: (_) => UserProvider(userRepository: userRepository),
          ),
          ChangeNotifierProvider(
            create: (_) => AdminProvider(userRepository: userRepository),
          ),

          // Services
          Provider<FirestoreStorageService>.value(value: storageService),
          Provider<AuthService>.value(value: authService),
          Provider<ChatService>.value(value: chatService),
          Provider<InvitationService>.value(value: invitationService),

          // Repositories
          Provider<UserRepository>.value(value: userRepository),
          Provider<FriendshipRepository>.value(value: friendshipRepository),
          Provider<ChatRoomRepository>.value(value: chatRoomRepository),
          Provider<BlockRepository>.value(value: blockRepository),
        ],
        child: MyApp(
          authService: authService,
          storageService: storageService,
        ),
      ),
    );

    // アプリが起動することを確認
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // 初期画面が表示されることを確認
    // ログインしていない場合はログイン画面が表示される
    await tester.pumpAndSettle();
    
    // ログイン画面またはホーム画面のどちらかが表示されることを確認
    final hasLoginScreen = find.text('ログイン').evaluate().isNotEmpty;
    final hasHomeScreen = find.text('Whispin').evaluate().isNotEmpty;
    
    expect(hasLoginScreen || hasHomeScreen, true);
  });
}