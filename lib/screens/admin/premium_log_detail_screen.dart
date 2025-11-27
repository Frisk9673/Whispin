import 'package:flutter/material.dart';
import '../../models/premium_log_model.dart';
import '../../services/premium_log_service.dart';

class PremiumLogDetailScreen extends StatelessWidget {
  final PremiumLog log;

  const PremiumLogDetailScreen({super.key, required this.log});

  String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PremiumLogService().fetchUser(log.telId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text("会員ログ詳細"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("名前：${user.lastName} ${user.firstName}",
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 12),
                Text("電話番号：${user.telId}"),
                const SizedBox(height: 12),
                Text("メール：${user.email}"),
                const SizedBox(height: 12),
                Text("契約状況：${log.detail}"),
                const SizedBox(height: 12),
                Text("日時：${formatDate(log.timestamp)}"),
              ],
            ),
          ),
        );
      },
    );
  }
}
