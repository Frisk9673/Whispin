import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whispin/services/firestore_storage_service.dart';
import 'package:whispin/services/auth_service.dart';
import 'package:whispin/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // モックサービスを作成
    final storageService = FirestoreStorageService();
    await storageService.initialize();
    
    final authService = AuthService(storageService);
    await authService.initialize();

    // Build our app with services
    await tester.pumpWidget(
      MyApp(
        authService: authService,
        storageService: storageService,
      ),
    );

    // アプリが起動することを確認
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // UserRegisterPage が表示されることを確認（ログインしていない場合）
    expect(find.text('ユーザー登録'), findsOneWidget);
  });
}