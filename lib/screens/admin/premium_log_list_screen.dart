import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/premium_log_provider.dart';
import '../../widgets/admin/premium_log_list_tile.dart';
import '../../utils/app_logger.dart';

class PremiumLogListScreen extends StatefulWidget {
  const PremiumLogListScreen({super.key});

  @override
  State<PremiumLogListScreen> createState() => _PremiumLogListScreenState();
}

class _PremiumLogListScreenState extends State<PremiumLogListScreen> {
  final TextEditingController _controller = TextEditingController();
  static const String _logName = 'PremiumLogListScreen';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      logger.section('初期ロード開始', name: _logName);
      Provider.of<PremiumLogProvider>(context, listen: false).loadAllLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PremiumLogProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("プレミアム契約ログ一覧"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: "電話番号で絞り込み",
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 検索ボタン
                ElevatedButton(
                  onPressed: () async {
                    final tel = _controller.text.trim();

                    logger.section('電話番号検索', name: _logName);
                    logger.info('入力値: "$tel"', name: _logName);
                    
                    await provider.filterByTel(tel);
                    
                    logger.section('検索完了', name: _logName);
                  },
                  child: const Text("検索"),
                ),

                const SizedBox(width: 10),

                // クリアボタン（全件に戻す）
                OutlinedButton(
                  onPressed: () async {
                    _controller.clear();
                    
                    logger.section('全件表示に戻す', name: _logName);
                    
                    await provider.loadAllLogs();
                    
                    logger.section('完了', name: _logName);
                  },
                  child: const Text("クリア"),
                ),
              ],
            ),
          ),

          const Divider(),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: provider.logs.length,
                    itemBuilder: (context, index) {
                      final log = provider.logs[index];
                      return PremiumLogListTile(log: log);
                    },
                  ),
          )
        ],
      ),
    );
  }
}