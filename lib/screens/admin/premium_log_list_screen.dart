import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whispin/constants/responsive.dart';
import '../../providers/premium_log_provider.dart';
import '../../widgets/admin/premium_log_list_tile.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';

// 対象業務: ログ閲覧（プレミアム利用ログの検索・確認）
class PremiumLogListScreen extends StatefulWidget {
  const PremiumLogListScreen({super.key});

  @override
  State<PremiumLogListScreen> createState() => _PremiumLogListScreenState();
}

class _PremiumLogListScreenState extends State<PremiumLogListScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(PremiumLogProvider provider) async {
    final email = _controller.text.trim();

    if (email.isEmpty) {
      context.showWarningSnackBar('メールアドレスを入力してください');
      return;
    }

    await provider.filterByEmail(email);

    if (!mounted) return;

    if (provider.logs.isEmpty) {
      context.showInfoSnackBar('該当するログが見つかりませんでした');
    } else {
      context.showSuccessSnackBar('${provider.logs.length}件のログが見つかりました');
    }
  }

  Future<void> _handleClear(PremiumLogProvider provider) async {
    _controller.clear();
    await provider.loadAllLogs();

    if (!mounted) return;
    context.showSuccessSnackBar('全件表示に戻しました');
  }

  // 共通部品化判断基準:
  // - 検索フォーム + 結果一覧の構成がユーザー向け履歴画面でも同一
  // - 管理者限定の列（内部IDや監査情報）に依存しない
  // 条件を満たす場合は widgets/common への移行を検討する。
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PremiumLogProvider>();
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'プレミアムログ',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textWhite,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
      ),
            body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundLight,
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: Column(
          children: [
            // 検索エリア
            _buildSearchArea(provider, isMobile),

            // 統計情報
            _buildStatsCard(provider),

            // ログリスト
            Expanded(
              child: _buildLogList(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchArea(PremiumLogProvider provider, bool isMobile) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: Theme.of(context).cardColor,
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // タイトル
          Row(
            children: [
              Icon(Icons.search, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'メールアドレスで検索',
                style: textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 検索フィールドとボタン
          if (isMobile) ...[
            // モバイル: 縦並び
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'メールアドレスを入力',
                prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => setState(() {}),
              onSubmitted: (_) => _handleSearch(provider),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => _handleSearch(provider),
                    icon: const Icon(Icons.search),
                    label: const Text('検索'),
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => _handleClear(provider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('クリア'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // デスクトップ: 横並び
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'メールアドレスを入力',
                      prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (_) => _handleSearch(provider),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed:
                      provider.isLoading ? null : () => _handleSearch(provider),
                  icon: const Icon(Icons.search),
                  label: const Text('検索'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed:
                      provider.isLoading ? null : () => _handleClear(provider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('クリア'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(PremiumLogProvider provider) {
    return Container(
      margin: EdgeInsets.all(AppConstants.defaultPadding),
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            size: 40,
            color: AppColors.textWhite,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '表示中のログ件数',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textWhite.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.logs.length}件',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (provider.isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.textWhite,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogList(PremiumLogProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              '読み込み中...',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ログが見つかりません',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '検索条件を変更してください',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      itemCount: provider.logs.length,
      itemBuilder: (context, index) {
        return PremiumLogListTile(
          log: provider.logs[index],
        );
      },
    );
  }
}
