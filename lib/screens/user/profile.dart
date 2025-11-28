import 'dart:io' show File, Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whispin/screens/account_create/account_create_screen.dart';
import 'package:whispin/screens/user/user_chat_screen.dart';
import '../../widgets/common/header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedImagePath;
  
  // ホバー状態を管理する変数
  bool _isLogoutHovered = false;
  bool _isDeleteAccountHovered = false;
  bool _isPremiumHovered = false;
  bool _isContactHovered = false;
  bool _isBackButtonHovered = false;
  bool _isCameraHovered = false;

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
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('写真を撮る'),
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(ImageSource.camera);
                    },
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('ライブラリから選択'),
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
              if (isDesktop)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ListTile(
                    leading: const Icon(Icons.folder),
                    title: const Text('フォルダから選択'),
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(ImageSource.gallery);
                    },
                  ),
                ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('キャンセル'),
                  onTap: () => Navigator.pop(context),
                ),
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

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UserRegisterPage()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログアウトエラー: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _isCameraHovered = true),
                            onExit: (_) => setState(() => _isCameraHovered = false),
                            cursor: SystemMouseCursors.click,
                            child: Tooltip(
                              message: 'プロフィール画像を変更',
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isCameraHovered ? Colors.blue : Colors.black87,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: _isCameraHovered
                                        ? [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: _isCameraHovered ? 30 : 28,
                                  ),
                                ),
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
                      _isLogoutHovered ? Colors.red[700]! : Colors.red,
                      _logout,
                      (value) => setState(() => _isLogoutHovered = value),
                    ),

                    const SizedBox(height: 16),

                    // アカウント削除ボタン
_buildButton(
  'アカウント削除',
  _isDeleteAccountHovered ? Colors.red[700]! : Colors.red,
  () async {
    // 確認ダイアログを表示
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('アカウント削除の確認'),
          ],
        ),
        content: const Text('本当にアカウントを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('いいえ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'はい',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    // 「いいえ」を選択した場合は何もせず終了
    if (result != true) return;

    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('アカウントを削除中...'),
          ],
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;

      if (email == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログイン情報を取得できません'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Firestoreでユーザーを検索
      final query = await FirebaseFirestore.instance
          .collection('User')
          .where('EmailAddress', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー情報が見つかりません'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final doc = query.docs.first;

      // Firestoreで論理削除のみ実行
      await doc.reference.update({
        'DeletedAt': FieldValue.serverTimestamp(),
        'IsDeleted': true,
        'Status': 'deleted',
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('アカウントを削除しました'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // ログアウトのみ実行（Authアカウントは削除しない）
      await FirebaseAuth.instance.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const UserRegisterPage()),
        (route) => false,
      );

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('削除エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  (value) => setState(() => _isDeleteAccountHovered = value),
),

                    const SizedBox(height: 16),

                    _buildButton(
  '有料プラン',
  _isPremiumHovered ? Colors.blue[700]! : Colors.blue,
  () async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    final query = await FirebaseFirestore.instance
        .collection('User')
        .where('EmailAddress', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    final userDoc = query.docs.first;
    final bool isPremium = userDoc['Premium'] ?? false;

    if (!isPremium) {
      // 加入処理
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

        // Log_Premium に履歴追加
        await FirebaseFirestore.instance.collection('Log_Premium').add({
          'ID': email,
          'Timestamp': FieldValue.serverTimestamp(),
          'Detail': '加入',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("プレミアムに加入しました！")),
        );
      }
    } else {
      // 解約処理
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

        // Log_Premium に履歴追加
        await FirebaseFirestore.instance.collection('Log_Premium').add({
          'ID': email,
          'Timestamp': FieldValue.serverTimestamp(),
          'Detail': '解約',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("プレミアムを解約しました")),
        );
      }
    }
  },
  (value) => setState(() => _isPremiumHovered = value),
),


                    const SizedBox(height: 16),

                    _buildButton(
                      'お問い合わせ',
                      _isContactHovered ? Colors.blue[700]! : Colors.blue,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserChatScreen(),
                          ),
                        );
                      },
                      (value) => setState(() => _isContactHovered = value),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isBackButtonHovered = true),
                onExit: (_) => setState(() => _isBackButtonHovered = false),
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: '戻る',
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBackButtonHovered 
                            ? Colors.grey[100] 
                            : Colors.white,
                        side: BorderSide(
                          color: _isBackButtonHovered ? Colors.blue : Colors.black87,
                          width: _isBackButtonHovered ? 4 : 3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isBackButtonHovered ? 4 : 0,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 40,
                        color: _isBackButtonHovered ? Colors.blue : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    String text, 
    Color color, 
    VoidCallback onPressed,
    Function(bool) onHover,
  ) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: text,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
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
        ),
      ),
    );
  }
}