import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    // Header
                    Row(
                      children: [
                        Text(
                          'Whispin',
                          style: TextStyle(
                            fontFamily: 'Serif',
                            fontSize: 32,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        // underline line to mimic screenshot
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 6, bottom: 36),
                      height: 2,
                      color: Colors.black12,
                    ),

                    const SizedBox(height: 18),

                    // Title
                    Center(
                      child: Column(
                        children: const [
                          Text(
                            '① 電話番号を',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '入力してください',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '② ※ハイフン(-)なし',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Phone input box styled like screenshot
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black26, width: 2),
                      ),
                      child: Row(
                        children: [
                          // left small circle like screenshot indicator
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '00001111-2222',
                                isDense: true,
                              ),
                              style: const TextStyle(letterSpacing: 2.0),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // SMS button
                    SizedBox(
                      width: 140,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: implement SMS authentication
                          final phone = _phoneController.text.trim();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('送信: $phone')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('SMS認証',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),

            // Back button bottom-left like screenshot
            Positioned(
              left: 18,
              bottom: 24,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black87, width: 2),
                    color: Colors.white,
                  ),
                  child: const Icon(Icons.arrow_back, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
