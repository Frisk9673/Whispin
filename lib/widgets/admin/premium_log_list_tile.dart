import 'package:flutter/material.dart';
import '../../models/premium_log_model.dart';
import '../../services/premium_log_service.dart';
import '../../models/user.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/datetime_extensions.dart';
import '../../utils/app_logger.dart';

class PremiumLogListTile extends StatelessWidget {
  final PremiumLog log;
  static const String _logName = 'PremiumLogListTile';

  const PremiumLogListTile({super.key, required this.log});

  Future<void> _showDetailDialog(BuildContext context) async {
    logger.section('タイルタップ', name: _logName);
    logger.info('email: ${log.email}', name: _logName);
    logger.start('Firestoreからユーザー情報を取得します...', name: _logName);

    User? user;

    try {
      user = await PremiumLogService().fetchUserByEmail(log.email);
      if (!context.mounted) return;
      logger.success('fetchUserByEmail 完了', name: _logName);
    } catch (e, stack) {
      logger.error(
        'fetchUserByEmail 実行中に例外発生: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      return;
    }

    if (user == null) {
      logger.warning(
        'ユーザーが存在しません (email: ${log.email})',
        name: _logName,
      );
      logger.section('処理終了', name: _logName);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.defaultBorderRadius,
              ),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 8),
                const Text('エラー'),
              ],
            ),
            content: const Text('ユーザー情報が見つかりませんでした'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      }
      return;
    }

    logger.info(
      'ユーザー情報取得成功: ${user.lastName} ${user.firstName}, Premium: ${user.premium}',
      name: _logName,
    );
    logger.start('ダイアログを表示します', name: _logName);

    final String statusText = user.premium ? '契約中' : '未契約';
    final Color statusColor =
        user.premium ? AppColors.success : AppColors.textSecondary;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ヘッダー
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.textWhite,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ユーザー詳細',
                          style: AppTextStyles.titleLarge,
                        ),
                        Text(
                          '${user?.lastName} ${user?.firstName}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      logger.info(
                        'ダイアログを閉じました (email: ${log.email})',
                        name: _logName,
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 基本情報
              _buildInfoSection(
                title: '基本情報',
                icon: Icons.info_outline,
                children: [
                  _buildInfoRow(
                    Icons.email,
                    'メールアドレス',
                    user!.id,
                  ),
                  _buildInfoRow(
                    Icons.phone,
                    '電話番号',
                    user.phoneNumber ?? '未設定',
                  ),
                  _buildInfoRow(
                    Icons.badge,
                    'ニックネーム',
                    user.nickname.isEmpty ? '未設定' : user.nickname,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 契約状況
              _buildInfoSection(
                title: '契約状況',
                icon: Icons.diamond,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          user.premium
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: statusColor,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '現在のステータス',
                                style: AppTextStyles.labelMedium,
                              ),
                              Text(
                                statusText,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ログ情報
              _buildInfoSection(
                title: 'ログ情報',
                icon: Icons.history,
                children: [
                  _buildInfoRow(
                    Icons.event_note,
                    '詳細',
                    log.detail,
                  ),
                  _buildInfoRow(
                    Icons.access_time,
                    '日時',
                    log.timestamp.toJapaneseDateWithWeekday +
                        '\n' +
                        log.timestamp.toTimeString,
                  ),
                  _buildInfoRow(
                    Icons.schedule,
                    '経過時間',
                    log.timestamp.toRelativeTime,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  logger.info(
                    'ダイアログを閉じました (email: ${log.email})',
                    name: _logName,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                  ),
                ),
                child: Text(
                  '閉じる',
                  style: AppTextStyles.buttonMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    logger.section('処理完了', name: _logName);
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.debug(
      'ListTile が描画されました (email: ${log.email})',
      name: _logName,
    );

    final isSubscription = log.detail == '契約';
    final actionColor =
        isSubscription ? AppColors.success : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        borderRadius:
            BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              // アイコン
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                  border: Border.all(
                    color: actionColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSubscription
                      ? Icons.add_circle
                      : Icons.remove_circle,
                  color: actionColor,
                  size: 32,
                ),
              ),

              const SizedBox(width: 16),

              // 情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            log.email,
                            style: AppTextStyles.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        log.detail,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.timestamp.toRelativeTime,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            log.timestamp.toJapaneseDate,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}