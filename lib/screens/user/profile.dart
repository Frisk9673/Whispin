import 'dart:io' show File, Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../user_chat.dart';
import '../../widgets/common/header.dart';
import '../../logout.dart';
import 'account_create.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedImagePath;

  Future<void> _pickImage() async {
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final bool isDesktop = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMobile) ...[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('写真を撮る'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('ライブラリから選択'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.gallery);
                  },
                ),
              ],
              if (isDesktop)
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('フォルダから選択'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.gallery);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('キャンセル'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null && mounted) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の選択に失敗しました: $e')),
      );
    }
  }

  ImageProvider? _buildProfileImage() {
    if (_selectedImagePath == null) return null;

    if (kIsWeb) {
      return NetworkImage(_selectedImagePath!);
    }
    return FileImage(File(_selectedImagePath!));
  }

  @override
  Widget build(BuildContext context) {
    final loginEmail =
        FirebaseAuth.instance.currentUser?.email ?? "未ログイン";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CommonHeader(
              onSettingsPressed: () {},
              onProfilePressed: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // プロフィール画像
                    Stack(
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.black87, width: 2),
                          ),
                          child: _selectedImagePath != null
                              ? CircleAvatar(
                                  backgroundImage: _buildProfileImage(),
                                  radius: 90,
                                )
                              : const Icon(
                                  Icons.account_circle,
                                  size: 180,
                                  color: Colors.grey,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black87,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Text(
                          'ニックネーム: XXXXXXX',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '本名: XXXXXXX',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '電話番号: XXX-XXXX-XXXX',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    _buildButton(
                      'ログアウト',
                      Colors.red,
                      () => signOutAndGoToRegister(context),
                    ),

                    const SizedBox(height: 16),

                    // ----------------------------
                    // 🔥 アカウント削除
                    // ----------------------------
                    _buildButton(
                      'アカウント削除',
                      Colors.red,
                      () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('確認'),
                            content:
                                const Text('本当にアカウントを削除しますか？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('キャンセル'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('はい'),
                              ),
                            ],
                          ),
                        );

                        if (result != true) return;

                        final email =
                            FirebaseAuth.instance.currentUser?.email;

                        if (email == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('ログイン情報を取得できません')),
                          );
                          return;
                        }

                        try {
                          // FirestoreでEmailAddressから検索
                          final query = await FirebaseFirestore.instance
                              .collection('User')
                              .where('EmailAddress', isEqualTo: email)
                              .limit(1)
                              .get();

                          if (query.docs.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('ユーザー情報が見つかりません')),
                            );
                            return;
                          }

                          final doc = query.docs.first;

                          // 論理削除
                          await doc.reference.update({
                            'DeletedAt': FieldValue.serverTimestamp(),
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('アカウントを削除しました')),
                          );

                          // ログアウト後 → 登録画面へ
                          await FirebaseAuth.instance.signOut();

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UserRegisterPage()),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('削除エラー: $e')),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildButton(
  '有料プラン',
  Colors.blue,
  () async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    // Firestore から Premium を取得
    final query = await FirebaseFirestore.instance
        .collection('User')
        .where('EmailAddress', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    final userDoc = query.docs.first;
    final bool isPremium = userDoc['Premium'] ?? false;

    // ★ Premium 状態によって表示するポップアップを変更する
    if (!isPremium) {
      // --- 加入確認ポップアップ ---
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("プレミアムプラン加入"),
          content: const Text("プレミアムに加入しますか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("いいえ"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("はい"),
            ),
          ],
        ),
      );

      if (result == true) {
        await userDoc.reference.update({
          'Premium': true,
          'LastUpdated_Premium': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("プレミアムに加入しました！")),
        );
      }

    } else {
      // --- 解約確認ポップアップ ---
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("プレミアム解約"),
          content: const Text("本当に解約しますか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("いいえ"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("はい"),
            ),
          ],
        ),
      );

      if (result == true) {
        await userDoc.reference.update({
          'Premium': false,
          'LastUpdated_Premium': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("プレミアムを解約しました")),
        );
      }
    }
  },
),

                    _buildButton(
                      'お問い合わせ',
                      Colors.blue,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserChatScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 80,
                height: 80,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black87, width: 3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 40, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
