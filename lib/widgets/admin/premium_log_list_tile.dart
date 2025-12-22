import 'package:flutter/material.dart';
import '../../models/premium_log_model.dart';
import '../../services/premium_log_service.dart';
import '../../models/user.dart';

class PremiumLogListTile extends StatelessWidget {
  final PremiumLog log;

  const PremiumLogListTile({super.key, required this.log});

  Future<void> _showDetailDialog(BuildContext context) async {
    print('\n=========== [PremiumLogListTile] ===========');
    print('>>> タイルがタップされました (TEL: ${log.email})');
    print('>>> Firestoreからユーザー情報を取得します...');

    User? user;

    try {
      // fetchUser も統合版 User に合わせて phoneNumber で検索
      user = await PremiumLogService().fetchUser(log.email);
      print('>>> fetchUser 完了');
    } catch (e) {
      print('!!! [ERROR] fetchUser 実行中に例外発生: $e');
      return;
    }

    if (user == null) {
      print('!!! ユーザーが存在しません (TEL: ${log.email})');
      print('============================================\n');
      return;
    }

    print('>>> ユーザー情報取得成功: '
        '${user.lastName} ${user.firstName}, Premium: ${user.premium}');
    print('>>> ダイアログを表示します');
    print('============================================\n');

    final String statusText = user.premium ? "契約中" : "未契約";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ユーザ詳細"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("電話番号: ${user?.phoneNumber ?? '不明'}"),
            Text("名前: ${user?.lastName ?? ''} ${user?.firstName ?? ''}"),
            Text("メール: ${user?.id}"),
            const SizedBox(height: 10),
            Text("現在の契約状況: $statusText"),
            const SizedBox(height: 10),
            Text("ログ詳細: ${log.detail}"),
            Text("ログ日時: ${log.timestamp}"),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("閉じる"),
            onPressed: () {
              print('>>> ダイアログを閉じました (TEL: ${log.email})');
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('>>> ListTile が描画されました (TEL: ${log.email})');

    return ListTile(
      title: Text("TEL: ${log.email}"),
      subtitle: Text("ログ: ${log.detail}"),
      trailing: Text(log.timestamp.toString()),
      onTap: () => _showDetailDialog(context),
    );
  }
}
