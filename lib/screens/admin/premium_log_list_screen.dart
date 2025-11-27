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
  @override
  void initState() {
    super.initState();

    // 全件ロード
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          // ======== 検索フォーム ========
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "電話番号で検索",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                provider.filterByTel(value.trim());
              },
            ),
          ),

          // ======== ログ一覧 ========
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.logs.isEmpty
                    ? const Center(child: Text("ログがありません"))
                    : ListView.builder(
                        itemCount: provider.logs.length,
                        itemBuilder: (context, index) {
                          return PremiumLogListTile(log: provider.logs[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
