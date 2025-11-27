// screens/admin/premium_log_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/premium_log_provider.dart';
import '../../widgets/admin/premium_log_list_tile.dart';

class PremiumLogListScreen extends StatefulWidget {
  const PremiumLogListScreen({super.key});

  @override
  State<PremiumLogListScreen> createState() => _PremiumLogListScreenState();
}

class _PremiumLogListScreenState extends State<PremiumLogListScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      print("\n=== PremiumLogListScreen: 初期ロード開始 ===");
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

                // 🔍 検索ボタン追加
                ElevatedButton(
                  onPressed: () async {
                    final tel = _controller.text.trim();

                    print("\n=== [SEARCH BUTTON] 電話番号検索 ===");
                    print("入力値: '$tel'");
                    await provider.filterByTel(tel);
                    print("=== [SEARCH BUTTON] 検索完了 ===\n");
                  },
                  child: const Text("検索"),
                ),

                const SizedBox(width: 10),

                // 🧹 クリアボタン（全件に戻す）
                OutlinedButton(
                  onPressed: () async {
                    _controller.clear();
                    print("\n=== [CLEAR BUTTON] 全件表示に戻す ===");
                    await provider.loadAllLogs();
                    print("=== [CLEAR BUTTON] 完了 ===\n");
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
