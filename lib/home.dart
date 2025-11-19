import 'package:flutter/material.dart';
import 'header.dart'; // CommonHeaderをインポート

class RoomJoinScreen extends StatelessWidget {
  const RoomJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 共通ヘッダーの使用
            const CommonHeader(
              // 必要に応じてカスタマイズ
              // onSettingsPressed: () {
              //   // 設定画面への遷移処理
              // },
              // onProfilePressed: () {
              //   // プロフィール画面への遷移処理
              // },
            ),
            // メインコンテンツ
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 上部の2つのボタン（部屋に参加、ブロック一覧）
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildCircleButton(
                              label: '部屋に参加',
                              onPressed: () {
                                // 部屋に参加する処理
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildCircleButton(
                              label: 'ブロック一覧',
                              onPressed: () {
                                // ブロック一覧画面への遷移
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // 下部の2つのボタン
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildCircleButton(
                              label: '部屋を作成',
                              onPressed: () {
                                // 部屋作成画面への遷移
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildCircleButton(
                              label: 'フレンド一覧',
                              onPressed: () {
                                // フレンド一覧画面への遷移
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black87,
              width: 3,
            ),
          ),
          child: Center(
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
        ),
      ),
    );
  }
}
