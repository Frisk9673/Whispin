import 'package:flutter/material.dart';
import '../../models/premium_log_model.dart';
import '../../services/premium_log_service.dart';
import '../../models/user_model.dart';

class PremiumLogListTile extends StatelessWidget {
  final PremiumLog log;

  const PremiumLogListTile({super.key, required this.log});

  Future<void> _showDetailDialog(BuildContext context) async {
    // Firestore からユーザ取得
    final UserModel? user =
        await PremiumLogService().fetchUser(log.telId);

    if (user == null) {
      return;
    }

    final String statusText = user.premium ? "契約中" : "未契約";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ユーザ詳細"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("電話番号: ${user.telId}"),
            Text("名前: ${user.lastName} ${user.firstName}"),
            Text("メール: ${user.email}"),
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
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("TEL: ${log.telId}"),
      subtitle: Text("ログ: ${log.detail}"),
      trailing: Text(log.timestamp.toString()),
      onTap: () => _showDetailDialog(context),
    );
  }
}
