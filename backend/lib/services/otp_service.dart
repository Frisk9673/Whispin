import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

class OTPService {
  /// 6桁OTP生成
  String generateOTP() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  /// メールへOTP送信
  Future<bool> sendOTP(String email, String otpCode) async {
    final smtpServer = gmail("your_email@gmail.com", "your_app_password");

    final message = Message()
      ..from = Address("your_email@gmail.com", "Whispinサポート")
      ..recipients.add(email)
      ..subject = "【Whispin】ワンタイムパスワード"
      ..text = "あなたの認証コードは：$otpCode です。\n5分以内に入力してください。";

    try {
      await send(message, smtpServer);
      return true;
    } catch (e) {
      print("メール送信エラー: $e");
      return false;
    }
  }
}
