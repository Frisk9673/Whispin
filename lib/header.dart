// import 'package:flutter/material.dart';

// class CommonHeader extends StatelessWidget {
//   final String appName;
//   final VoidCallback? onSettingsPressed;
//   final VoidCallback? onProfilePressed;
//   final bool showSettingsButton;
//   final bool showProfileButton;

//   const CommonHeader({
//     super.key,
//     this.appName = 'whispin',
//     this.onSettingsPressed,
//     this.onProfilePressed,
//     this.showSettingsButton = true,
//     this.showProfileButton = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             appName,
//             style: const TextStyle(
//               fontSize: 40,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           Row(
//             children: [
//               if (showSettingsButton)
//                 _buildHeaderButton(
//                   icon: Icons.settings,
//                   onPressed: onSettingsPressed ?? () {},
//                 ),
//               if (showSettingsButton && showProfileButton)
//                 const SizedBox(width: 12),
//               if (showProfileButton)
//                 _buildHeaderButton(
//                   icon: Icons.account_circle,
//                   onPressed: onProfilePressed ?? () {},
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderButton({
//     required IconData icon,
//     required VoidCallback onPressed,
//   }) {
//     return SizedBox(
//       width: 60,
//       height: 60,
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.grey[300],
//           shape: const CircleBorder(),
//           padding: EdgeInsets.zero,
//         ),
//         child: Icon(
//           icon,
//           size: 32,
//           color: Colors.black87,
//         ),
//       ),
//     );
//   }
// }






















import 'package:flutter/material.dart';
import 'profile.dart'; // ProfileScreenをインポート

class CommonHeader extends StatelessWidget {
  final String appName;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;
  final bool showSettingsButton;
  final bool showProfileButton;
  final BuildContext? context; // ナビゲーション用にcontextを追加

  const CommonHeader({
    super.key,
    this.appName = 'whispin',
    this.onSettingsPressed,
    this.onProfilePressed,
    this.showSettingsButton = true,
    this.showProfileButton = true,
    this.context, // contextをオプショナルに
  });

  // プロフィール画面へ遷移するメソッド
  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

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
                  icon: Icons.settings,
                  onPressed: onSettingsPressed ?? () {
                    // 設定ボタンのデフォルト動作
                    print('⚙️ 設定ボタンが押されました');
                  },
                ),
              if (showSettingsButton && showProfileButton)
                const SizedBox(width: 12),
              if (showProfileButton)
                _buildHeaderButton(
                  icon: Icons.account_circle,
                  onPressed: onProfilePressed ?? () {
                    // プロフィールボタンのデフォルト動作 - プロフィール画面へ遷移
                    _navigateToProfile(context);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
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