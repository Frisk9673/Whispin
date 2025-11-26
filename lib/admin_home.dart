import 'package:flutter/material.dart';


class AdminHomePage extends StatefulWidget {
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int paidMemberCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaidMemberCount();
    // ここで有料会員数の取得処理を実装
    // 例: fetchPaidMemberCount();
  }

  Future<void> _fetchPaidMemberCount() async {
    try {
      final count = 0;

      setState(() {
        paidMemberCount = count;
        isLoading = false;
      });
    } catch (e) {
      print('エラー: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _circleButton({required String label, required VoidCallback onPressed, Color? backgroundColor}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      child: SizedBox(
        width: 88,
        height: 88,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('管理画面'),
        actions: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                // ログアウト処理
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'ログアウト',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 上部: 中央に有料会員数、その下に左右の円形ボタン
          Padding(
            padding: EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
            child: isLoading
                ? SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 画面上部中央のテキスト（タップでログ一覧へ遷移）
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/premium_log_list');
                        },
                        child: Center(
                          child: Text(
                            '有料会員数: ${paidMemberCount}人',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // ボタン行：左に円形「お問い合わせ」、右に円形「有料会員ログ」
                      Row(
                        children: [
                          _circleButton(
                            label: 'お問い合わせ',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/contact');
                            },
                            backgroundColor: Colors.white,
                          ),
                          Spacer(),
                          _circleButton(
                            label: '有料会員\nログ',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/premium_log_list');
                            },
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: Center(
              child: Text('管理画面コンテンツ'),
            ),
          ),
        ],
      ),
    );
  }
}
