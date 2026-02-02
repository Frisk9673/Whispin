import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whispin/constants/responsive.dart';
import '../models/user_evaluation.dart';
import '../models/block.dart';
import '../services/storage_service.dart';
import '../services/friendship_service.dart';
import '../repositories/block_repository.dart';
import '../repositories/user_repository.dart';
import '../constants/app_constants.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../extensions/context_extensions.dart';
import '../utils/app_logger.dart';

class EvaluationDialog extends StatefulWidget {
  final String partnerId;
  final String currentUserId;
  final StorageService storageService;

  const EvaluationDialog({
    super.key,
    required this.partnerId,
    required this.currentUserId,
    required this.storageService,
  });

  @override
  State<EvaluationDialog> createState() => _EvaluationDialogState();
}

class _EvaluationDialogState extends State<EvaluationDialog> {
  String? _selectedRating;
  bool _addFriend = false;
  bool _blockUser = false;
  bool _isSubmitting = false;
  static const String _logName = 'EvaluationDialog';

  final BlockRepository _blockRepository = BlockRepository();

  Future<void> _handleSubmit() async {
    // 二重送信防止
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    logger.section('評価ダイアログ送信開始', name: _logName);
    logger.info('currentUserId: ${widget.currentUserId}', name: _logName);
    logger.info('partnerId: ${widget.partnerId}', name: _logName);
    logger.info('評価: $_selectedRating', name: _logName);
    logger.info('フレンド追加: $_addFriend', name: _logName);
    logger.info('ブロック: $_blockUser', name: _logName);

    try {
      // ===== 1. 評価の保存 =====
      if (_selectedRating != null) {
        logger.start('評価を保存中...', name: _logName);
        final evaluation = UserEvaluation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          evaluatorId: widget.currentUserId,
          evaluatedId: widget.partnerId,
          rating: _selectedRating!,
          createdAt: DateTime.now(),
        );
        widget.storageService.evaluations.add(evaluation);
        logger.success('評価保存完了', name: _logName);

        // ===== 1.5. 被評価者（相手）のrateを更新 =====
        logger.start('相手のrateを更新中...', name: _logName);
        await _updatePartnerRate();
        logger.success('相手のrate更新完了', name: _logName);
      }

      // ===== 2. フレンドリクエストの送信 =====
      if (_addFriend) {
        logger.start('フレンドリクエスト送信', name: _logName);

        final friendshipService = context.read<FriendshipService>();

        final result = await friendshipService.sendFriendRequest(
          senderId: widget.currentUserId,
          receiverId: widget.partnerId,
        );

        logger.success(
          result['message'] ?? 'フレンド処理完了',
          name: _logName,
        );
      }

      // ===== 3. ブロックの実行 =====
      if (_blockUser) {
        logger.start('ブロック処理中...', name: _logName);

        try {
          final blockId = await _blockRepository.blockUser(
            widget.currentUserId,
            widget.partnerId,
          );

          logger.success('ブロック完了: $blockId', name: _logName);

          // StorageServiceにも追加
          final block = Block(
            id: blockId,
            blockerId: widget.currentUserId,
            blockedId: widget.partnerId,
            active: true,
            createdAt: DateTime.now(),
          );

          logger.debug('Block作成:', name: _logName);
          logger.debug('  id: ${block.id}', name: _logName);
          logger.debug('  blockerId: ${block.blockerId}', name: _logName);
          logger.debug('  blockedId: ${block.blockedId}', name: _logName);

          // 既存のブロックを検索
          final existingIndex =
              widget.storageService.blocks.indexWhere((b) => b.id == blockId);

          if (existingIndex == -1) {
            widget.storageService.blocks.add(block);
          } else {
            widget.storageService.blocks[existingIndex] = block;
          }
        } catch (e, stack) {
          logger.error('ブロック処理エラー: $e',
              name: _logName, error: e, stackTrace: stack);
        }
      }

      // ===== 4. StorageService保存 =====
      logger.start('StorageService保存中...', name: _logName);
      await widget.storageService.save();
      logger.success('全データ保存完了', name: _logName);

      logger.section('評価ダイアログ送信完了', name: _logName);

      // ダイアログを閉じる
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      logger.error('送信エラー: $e', name: _logName, error: e, stackTrace: stack);

      if (mounted) {
        context.showErrorSnackBar('送信に失敗しました: $e');
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// ★ 追加: 被評価者（相手）のrateを更新するメソッド
  Future<void> _updatePartnerRate() async {
    logger.section('_updatePartnerRate() 開始', name: _logName);
    logger.info('partnerId: ${widget.partnerId}', name: _logName);
    logger.info('selectedRating: $_selectedRating', name: _logName);

    try {
      // UserRepositoryを取得
      final userRepository = context.read<UserRepository>();

      // 相手のユーザー情報を取得
      logger.start('相手のユーザー情報を取得中...', name: _logName);
      final partnerUser = await userRepository.findById(widget.partnerId);

      if (partnerUser == null) {
        logger.error('相手のユーザーが見つかりません: ${widget.partnerId}', name: _logName);
        throw Exception('相手のユーザーが見つかりません');
      }

      logger.success('相手のユーザー情報取得完了', name: _logName);
      logger.info('  現在のrate: ${partnerUser.rate}', name: _logName);

      // 新しいrateを計算
      // 高評価(thumbs_up): +1, 低評価(thumbs_down): -1
      final rateAdjustment =
          _selectedRating == AppConstants.ratingThumbsUp ? 1.0 : -1.0;

      final newRate = (partnerUser.rate + rateAdjustment).clamp(-100.0, 100.0);

      logger.info('rate調整: $_selectedRating → $rateAdjustment', name: _logName);
      logger.info('新しいrate: $newRate', name: _logName);

      // Repository経由でrateを更新
      logger.start('Repository経由でrateを更新中...', name: _logName);
      await userRepository.updateRate(widget.partnerId, newRate);
      logger.success('Repository更新完了', name: _logName);

      logger.section('_updatePartnerRate() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('rate更新エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    if (isMobile) {
      return _buildBottomSheet(context);
    } else {
      return _buildDialog(context);
    }
  }

  Widget _buildDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: _buildContent(isMobile: false),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Material(
      color: Colors.transparent, // ← 重要
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + context.padding.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildContent(isMobile: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent({required bool isMobile}) {
    final fontSize = context.responsiveFontSize(16);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'チャットの評価',
          style: AppTextStyles.headlineSmall.copyWith(
            fontSize: context.responsiveFontSize(20),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Text(
          '相手とのチャットはいかがでしたか？',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: context.responsiveFontSize(13),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildRatingButton(
                icon: Icons.thumb_up,
                label: 'Good',
                value: AppConstants.ratingThumbsUp,
                color: AppColors.success,
                isMobile: isMobile,
              ),
            ),
            SizedBox(width: isMobile ? 10 : 16),
            Expanded(
              child: _buildRatingButton(
                icon: Icons.thumb_down,
                label: 'Bad',
                value: AppConstants.ratingThumbsDown,
                color: AppColors.error,
                isMobile: isMobile,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Divider(color: AppColors.divider),
        SizedBox(height: isMobile ? 12 : 16),
        CheckboxListTile(
          value: _addFriend,
          onChanged: _isSubmitting
              ? null
              : (value) {
                  setState(() {
                    _addFriend = value ?? false;
                    if (_addFriend) {
                      _blockUser = false;
                    }
                  });
                },
          title: Text(
            'フレンド申請を送る',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: fontSize),
          ),
          secondary: Icon(
            Icons.person_add,
            color: AppColors.primary,
            size: isMobile ? 20 : 24,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 8),
        ),
        SizedBox(height: isMobile ? 4 : 8),
        CheckboxListTile(
          value: _blockUser,
          onChanged: _isSubmitting
              ? null
              : (value) {
                  setState(() {
                    _blockUser = value ?? false;
                    if (_blockUser) {
                      _addFriend = false;
                    }
                  });
                },
          title: Text(
            'ブロックする',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: fontSize),
          ),
          secondary: Icon(
            Icons.block,
            color: AppColors.error,
            size: isMobile ? 20 : 24,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 8),
        ),
        SizedBox(height: isMobile ? 16 : 24),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  height: isMobile ? 18 : 20,
                  width: isMobile ? 18 : 20,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '送信',
                  style: AppTextStyles.buttonMedium.copyWith(
                    fontSize: context.responsiveFontSize(16),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRatingButton({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isMobile,
  }) {
    final isSelected = _selectedRating == value;
    final iconSize = isMobile ? 36.0 : 44.0;
    final btnRadius = isMobile ? 16.0 : AppConstants.defaultBorderRadius;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSubmitting
            ? null
            : () {
                setState(() {
                  _selectedRating = value;
                });
              },
        borderRadius: BorderRadius.circular(btnRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 18 : 24,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.12)
                : AppColors.inputBackground,
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: isSelected ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(btnRadius),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: iconSize + (isSelected ? 12 : 0),
                height: iconSize + (isSelected ? 12 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? color.withOpacity(0.15) : Colors.transparent,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: isSelected ? color : AppColors.textDisabled,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 8 : 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
              if (isSelected) ...[
                SizedBox(height: isMobile ? 4 : 6),
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
