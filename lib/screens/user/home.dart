import 'package:flutter/material.dart';
import '../../widgets/common/header.dart';
import 'profile.dart';
import 'room_join_screen.dart';
import 'room_create_screen.dart';
import 'friend_list_screen.dart';
import 'block_list_screen.dart';

class RoomJoinScreen extends StatelessWidget {
  const RoomJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final buttonSize = size.width * 0.20;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CommonHeader(
              onProfilePressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircleButton(
                          label: "部屋に参加",
                          size: buttonSize,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RoomJoinScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: size.width * 0.08),
                        _buildCircleButton(
                          label: "ブロック一覧",
                          size: buttonSize,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BlockListScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircleButton(
                          label: "部屋を作成",
                          size: buttonSize,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RoomCreateScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: size.width * 0.08),
                        _buildCircleButton(
                          label: "フレンド一覧",
                          size: buttonSize,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FriendListScreen(),
                              ),
                            );
                          },
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