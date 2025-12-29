import 'dart:io' show File, Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:whispin/screens/account_create/account_create_screen.dart';
import 'package:whispin/screens/user/question_chat_user.dart';
import '../../widgets/common/header.dart';
import '../../providers/user_provider.dart';

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

  // ... (画像選択関連のメソッドは変更なし) ...

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
      // ✅ UserProviderをクリア
      context.read<UserProvider>().clearUser();
      
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
    // ✅ UserProviderからユーザー情報を取得
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;

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
              child: userProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : SingleChildScrollView(
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
                                  border: Border.all(
                                      color: Colors.black87, width: 2),
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
                                  onEnter: (_) =>
                                      setState(() => _isCameraHovered = true),
                                  onExit: (_) =>
                                      setState(() => _isCameraHovered = false),
                                  cursor: SystemMouseCursors.click,
                                  child: Tooltip(
                                    message: 'プロフィール画像を変更',
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _isCameraHovered
                                              ? Colors.blue
                                              : Colors.black87,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                          boxShadow: _isCameraHovered
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.blue
                                                        .withOpacity(0.3),
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

                          // ✅ UserProviderのデータを表示
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'ニックネーム: ${currentUser?.nickname ?? "未設定"}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '本名: ${currentUser?.fullName ?? "未設定"}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '電話番号: ${currentUser?.phoneNumber ?? "未設定"}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              // ✅ プレミアムステータス表示
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: userProvider.isPremium
                                      ? Colors.blue.shade50
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: userProvider.isPremium
                                        ? Colors.blue
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      userProvider.isPremium
                                          ? Icons.diamond
                                          : Icons.person,
                                      color: userProvider.isPremium
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      userProvider.isPremium
                                          ? 'プレミアム会員'
                                          : '通常会員',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: userProvider.isPremium
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
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

                          // アカウント削除ボタン（変更なし）
                          _buildButton(
                            'アカウント削除',
                            _isDeleteAccountHovered
                                ? Colors.red[700]!
                                : Colors.red,
                            () async {
                              // ... (既存のコード) ...
                            },
                            (value) => setState(
                                () => _isDeleteAccountHovered = value),
                          ),

                          const SizedBox(height: 16),

                          // ✅ 有料プランボタン（UserProvider使用版）
                          _buildButton(
                            userProvider.isPremium ? 'プレミアム解約' : 'プレミアム加入',
                            _isPremiumHovered ? Colors.blue[700]! : Colors.blue,
                            () => _handlePremiumButton(context, userProvider),
                            (value) =>
                                setState(() => _isPremiumHovered = value),
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
                            (value) =>
                                setState(() => _isContactHovered = value),
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
                          color: _isBackButtonHovered
                              ? Colors.blue
                              : Colors.black87,
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
                        color: _isBackButtonHovered
                            ? Colors.blue
                            : Colors.black87,
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

  // ✅ プレミアム処理を別メソッドに分離
  Future<void> _handlePremiumButton(
      BuildContext context, UserProvider userProvider) async {
    print('=== プレミアムボタン押下 ===');
    print('現在のステータス: ${userProvider.isPremium ? "プレミアム" : "通常"}');

    final isPremium = userProvider.isPremium;

    // 確認ダイアログ
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isPremium ? Icons.warning : Icons.diamond,
              color: isPremium ? Colors.orange : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(isPremium ? "プレミアム解約" : "プレミアムプラン加入"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPremium ? '本当に解約しますか？' : 'プレミアムプランに加入しますか？',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(isPremium ? '解約すると以下の特典が利用できなくなります:' : 'プレミアム特典:'),
            const SizedBox(height: 8),
            const Text('• チャット延長回数が無制限'),
            const Text('• 優先サポート'),
            const Text('• 広告非表示'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("いいえ"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPremium ? Colors.red : Colors.blue,
            ),
            child: Text(
              "はい",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != true) {
      print('⏹️ ユーザーがキャンセルしました\n');
      return;
    }

    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(isPremium ? '解約処理中...' : 'プレミアムに加入中...'),
          ],
        ),
      ),
    );

    try {
      // ✅ UserProviderで更新
      await userProvider.updatePremiumStatus(!isPremium);

      // ローディングを閉じる
      Navigator.pop(context);

      // 成功メッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(isPremium ? "プレミアムを解約しました" : "プレミアムに加入しました！"),
            ],
          ),
          backgroundColor: isPremium ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      print('🎉 処理完了\n');
    } catch (e) {
      print('❌ エラー発生: $e');

      // ローディングを閉じる
      Navigator.pop(context);

      // エラーメッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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