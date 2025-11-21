import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/premium_log_provider.dart';
import '../../widgets/admin/premium_log_list_tile.dart';
import 'premium_log_detail_screen.dart';

class PremiumLogListScreen extends StatefulWidget {
  const PremiumLogListScreen({super.key});

  @override
  State<PremiumLogListScreen> createState() => _PremiumLogListScreenState();
}

class _PremiumLogListScreenState extends State<PremiumLogListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PremiumLogProvider>().loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PremiumLogProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("プレミアム契約ログ一覧"),
      ),
      body: Column(
        children: [
          // 🔍 電話番号検索
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "電話番号で検索",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    provider.searchByTel(_searchController.text.trim());
                  },
                  child: const Text("検索"),
                ),
              ],
            ),
          ),

          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: provider.logs.length,
                    itemBuilder: (context, index) {
                      final log = provider.logs[index];
                      return PremiumLogListTile(
                        log: log,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PremiumLogDetailScreen(log: log),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
