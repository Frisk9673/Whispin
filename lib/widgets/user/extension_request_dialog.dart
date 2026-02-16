// lib/widgets/extension_request_dialog.dart
import 'package:flutter/material.dart';
import '../../models/user/extension_request.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';

class ExtensionRequestDialog extends StatelessWidget {
  /// 入力: 延長リクエスト表示用データ。
  final ExtensionRequest request;

  /// 結果通知(承認): 親でルート遷移やAPI呼び出しを行うためのコールバック。
  final VoidCallback onApprove;

  /// 結果通知(拒否): 親でルート遷移や状態更新を行うためのコールバック。
  final VoidCallback onReject;

  const ExtensionRequestDialog({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final bodyColor = isDark ? Colors.white70 : AppColors.textPrimary;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '延長リクエスト',
              style: AppTextStyles.headlineSmall.copyWith(color: titleColor),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '相手がチャット時間の延長を希望しています。',
            style: AppTextStyles.bodyMedium.copyWith(color: bodyColor),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(
                color: AppColors.info.withValues(alpha: isDark ? 0.45 : 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '延長すると${AppConstants.extensionDurationMinutes}分間追加されます',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.lightBlue[200] : AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          child: Text(
            '拒否',
            style: TextStyle(color: isDark ? Colors.red[300] : AppColors.error),
          ),
        ),
        ElevatedButton(
          onPressed: onApprove,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.green[600] : AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: const Text('承認'),
        ),
      ],
    );
  }
}
