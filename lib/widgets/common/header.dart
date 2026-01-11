import 'package:flutter/material.dart';
import '../../screens/user/profile.dart';

class CommonHeader extends StatelessWidget {
  final String appName;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;
  final bool showSettingsButton;
  final bool showProfileButton;

  const CommonHeader({
    super.key,
    this.appName = 'whispin',
    this.onSettingsPressed,
    this.onProfilePressed,
    this.showSettingsButton = true,
    this.showProfileButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            appName,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Row(
            children: [
              if (showSettingsButton)
                _buildHeaderButton(
                  context: context,
                  icon: Icons.settings,
                  onPressed: onSettingsPressed ?? () {
                    print('⚙️ 設定ボタンが押されました');
                  },
                ),
              if (showSettingsButton && showProfileButton)
                const SizedBox(width: 12),
              if (showProfileButton)
                _buildHeaderButton(
                  context: context,
                  icon: Icons.account_circle,
                  onPressed: onProfilePressed ?? () {
                    // デフォルト動作: ProfileScreenへ遷移
                    print('👤 プロフィールボタンが押されました');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          icon,
          size: 32,
          color: Colors.black87,
        ),
      ),
    );
  }
}