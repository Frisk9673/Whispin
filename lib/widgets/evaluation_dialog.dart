import 'package:flutter/material.dart';
import '../models/user_evaluation.dart';
import '../models/friend_request.dart';
import '../models/block.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class EvaluationDialog extends StatefulWidget {
  final String partnerId;
  final String currentUserId;
  final StorageService storageService;

  const EvaluationDialog({
    Key? key,
    required this.partnerId,
    required this.currentUserId,
    required this.storageService,
  }) : super(key: key);

  @override
  State<EvaluationDialog> createState() => _EvaluationDialogState();
}

class _EvaluationDialogState extends State<EvaluationDialog> {
  String? _selectedRating;
  bool _addFriend = false;
  bool _blockUser = false;

  Future<void> _handleSubmit() async {
    if (_selectedRating != null) {
      final evaluation = UserEvaluation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        evaluatorId: widget.currentUserId,
        evaluatedId: widget.partnerId,
        rating: _selectedRating!,
        createdAt: DateTime.now(),
      );
      widget.storageService.evaluations.add(evaluation);
    }

    if (_addFriend) {
      final existingRequest = widget.storageService.friendRequests.firstWhere(
        (f) =>
            (f.senderId == widget.currentUserId &&
                f.receiverId == widget.partnerId) ||
            (f.senderId == widget.partnerId &&
                f.receiverId == widget.currentUserId),
        orElse: () => FriendRequest(
          id: '',
          senderId: '',
          receiverId: '',
          status: '',
          createdAt: DateTime.now(),
        ),
      );

      if (existingRequest.id.isEmpty) {
        final friendRequest = FriendRequest(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: widget.currentUserId,
          receiverId: widget.partnerId,
          status: AppConstants.friendRequestStatusPending,
          createdAt: DateTime.now(),
        );
        widget.storageService.friendRequests.add(friendRequest);
      }
    }

    if (_blockUser) {
      final existingBlock = widget.storageService.blocks.firstWhere(
        (b) =>
            b.blockerId == widget.currentUserId &&
            b.blockedId == widget.partnerId,
        orElse: () => Block(
          id: '',
          blockerId: '',
          blockedId: '',
          active: false,
          createdAt: DateTime.now(),
        ),
      );

      if (existingBlock.id.isEmpty) {
        final block = Block(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          blockerId: widget.currentUserId,
          blockedId: widget.partnerId,
          active: true,
          createdAt: DateTime.now(),
        );
        widget.storageService.blocks.add(block);
      } else {
        final index = widget.storageService.blocks.indexOf(existingBlock);
        widget.storageService.blocks[index] =
            existingBlock.copyWith(active: true);
      }
    }

    await widget.storageService.save();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;

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
        constraints: BoxConstraints(maxWidth: 400),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        12,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding + MediaQuery.of(context).padding.bottom,
      ),
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
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'チャットの評価',
          style: AppTextStyles.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '相手とのチャットはいかがでしたか？',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRatingButton(
              icon: Icons.thumb_up,
              label: 'Good',
              value: AppConstants.ratingThumbsUp,
              color: AppColors.success,
            ),
            _buildRatingButton(
              icon: Icons.thumb_down,
              label: 'Bad',
              value: AppConstants.ratingThumbsDown,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: AppColors.divider),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _addFriend,
          onChanged: (value) {
            setState(() {
              _addFriend = value ?? false;
            });
          },
          title: Text('フレンド申請を送る', style: AppTextStyles.bodyMedium),
          secondary: Icon(Icons.person_add, color: AppColors.primary),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _blockUser,
          onChanged: (value) {
            setState(() {
              _blockUser = value ?? false;
            });
          },
          title: Text('ブロックする', style: AppTextStyles.bodyMedium),
          secondary: Icon(Icons.block, color: AppColors.error),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
          ),
          child: Text(
            '送信',
            style: AppTextStyles.buttonMedium,
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
  }) {
    final isSelected = _selectedRating == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRating = value;
        });
      },
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.inputBackground,
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? color : AppColors.textDisabled,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}