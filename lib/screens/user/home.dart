import 'package:flutter/material.dart';
import '../../widgets/common/header.dart';
import 'profile.dart';

class RoomJoinScreen extends StatelessWidget {
  const RoomJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonSize = size.width * 0.20; // 画面幅の35%の円ボタン

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー（高さ固定）
            CommonHeader(
              onProfilePressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),

            // メインエリア
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 上の段
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircleButton(
                          label: "部屋に参加",
                          size: buttonSize,
                          onPressed: () {},
                        ),
                        SizedBox(width: size.width * 0.08),
                        _buildCircleButton(
                          label: "ブロック一覧",
                          size: buttonSize,
                          onPressed: () {},
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.05),

                    // 下の段
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircleButton(
                          label: "部屋を作成",
                          size: buttonSize,
                          onPressed: () {},
                        ),
                        SizedBox(width: size.width * 0.08),
                        _buildCircleButton(
                          label: "フレンド一覧",
                          size: buttonSize,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 円形ボタン（レスポンシブサイズ対応）
  Widget _buildCircleButton({
    required String label,
    required double size,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black87,
            width: 3,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}