import 'package:flutter/material.dart';
import '../../models/premium_log_model.dart';

class PremiumLogListTile extends StatelessWidget {
  final PremiumLog log;
  final VoidCallback onTap;

  const PremiumLogListTile({
    super.key,
    required this.log,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isContract = log.detail == "契約";

    return ListTile(
      title: Text("${log.telId} さん"),
      subtitle: Text("${log.detail}：${log.timestamp}"),
      trailing: Icon(
        isContract ? Icons.check_circle : Icons.cancel,
        color: isContract ? Colors.green : Colors.red,
      ),
      onTap: onTap,
    );
  }
}
