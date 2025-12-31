import 'package:flutter/material.dart';
import '../../models/premium_log_model.dart';
import '../../services/premium_log_service.dart';
import '../../models/user.dart';
import '../../utils/app_logger.dart';

class PremiumLogListTile extends StatelessWidget {
  final PremiumLog log;
  static const String _logName = 'PremiumLogListTile';

  const PremiumLogListTile({super.key, required this.log});

  Future<void> _showDetailDialog(BuildContext context) async {
    logger.section('タイルタップ', name: _logName);
    logger.info('TEL: ${log.email}', name: _logName);
    logger.start('Firestoreからユーザー情報を取得します...', name: _logName);

    User? user;

    try {
      user = await PremiumLogService().fetchUser(log.email);
      logger.success('fetchUser 完了', name: _logName);
    } catch (e, stack) {
      logger.error('fetchUser 実行中に例外発生: $e', 
        name: _logName, 
        error: e, 
        stackTrace: stack,
      );
      return;
    }

    if (user == null) {
      logger.warning('ユーザーが存在しません (TEL: ${log.email})', name: _logName);
      logger.section('処理終了', name: _logName);
      return;
    }

    logger.info('ユーザー情報取得成功: ${user.lastName} ${user.firstName}, Premium: ${user.premium}',
        name: _logName);
    logger.start('ダイアログを表示します', name: _logName);

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
              logger.info('ダイアログを閉じました (TEL: ${log.email})', name: _logName);
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
    
    logger.section('処理完了', name: _logName);
  }

  @override
  Widget build(BuildContext context) {
    logger.debug('ListTile が描画されました (TEL: ${log.email})', name: _logName);

    return ListTile(
      title: Text("TEL: ${log.email}"),
      subtitle: Text("ログ: ${log.detail}"),
      trailing: Text(log.timestamp.toString()),
      onTap: () => _showDetailDialog(context),
    );
  }
}