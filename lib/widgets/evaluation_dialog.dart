import 'package:flutter/material.dart';
import '../models/user_evaluation.dart';
import '../models/friend_request.dart';
import '../models/block.dart';
import '../services/storage_service.dart';

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
          status: 'pending',
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
    final isMobile = MediaQuery.of(context).size.width < 768;

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
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(maxWidth: 400),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          '相手とのチャットはいかがでしたか？',
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRatingButton(
              icon: Icons.thumb_up,
              label: 'Good',
              value: 'thumbs_up',
              color: Colors.green,
            ),
            _buildRatingButton(
              icon: Icons.thumb_down,
              label: 'Bad',
              value: 'thumbs_down',
              color: Colors.red,
            ),
          ],
        ),
        SizedBox(height: 24),
        Divider(),
        SizedBox(height: 16),
        CheckboxListTile(
          value: _addFriend,
          onChanged: (value) {
            setState(() {
              _addFriend = value ?? false;
            });
          },
          title: Text('フレンド申請を送る'),
          secondary: Icon(Icons.person_add, color: Color(0xFF667EEA)),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _blockUser,
          onChanged: (value) {
            setState(() {
              _blockUser = value ?? false;
            });
          },
          title: Text('ブロックする'),
          secondary: Icon(Icons.block, color: Colors.red),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF667EEA),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '送信',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? color : Colors.grey.shade400,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
