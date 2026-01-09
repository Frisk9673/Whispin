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
  Widget build(BuildContext context) {
    final provider = context.watch<PremiumLogProvider>();

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

                ElevatedButton(
                  onPressed: () async {
                    final tel = _controller.text.trim();
                    await provider.filterByTel(tel);
                  },
                  child: const Text("検索"),
                ),

                const SizedBox(width: 10),

                OutlinedButton(
                  onPressed: () async {
                    _controller.clear();
                    await provider.loadAllLogs();
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
                : provider.logs.isEmpty
                    ? const Center(child: Text('ログがありません'))
                    : ListView.builder(
                        itemCount: provider.logs.length,
                        itemBuilder: (context, index) {
                          return PremiumLogListTile(
                            log: provider.logs[index],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}