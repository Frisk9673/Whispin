import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/user_service.dart';
import '../services/otp_service.dart';
import 'dart:convert';

class UserController {
  final router = Router();
  final userService = UserService();
  final otpService = OTPService();

  UserController() {
    /// POST /user/create
    router.post('/create', (Request req) async {
      final body = jsonDecode(await req.readAsString());

      final email = body['email'];
      final firstName = body['firstName'];
      final lastName = body['lastName'];
      final nickname = body['nickname'];

      if ([email, firstName, lastName, nickname].contains(null)) {
        return Response.badRequest(
          body: jsonEncode({"error": "必須項目が不足しています"}),
        );
      }

      // DB登録
      await userService.createUser(
        email: email,
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
      );

      // OTP生成
      String otp = otpService.generateOTP();
      await otpService.sendOTP(email, otp);

      return Response.ok(jsonEncode({
        "result": "success",
        "otp": otp, // 実運用では返さない
      }));
    });
  }
}
