import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/user_service.dart';
import 'dart:convert';

class UserController {
  final router = Router();
  final userService = UserService();

  UserController() {
    /// POST /user/create
    router.post('/create', (Request req) async {
      final body = jsonDecode(await req.readAsString());

      final email = body['email'];
      final firstName = body['firstName'];
      final lastName = body['lastName'];
      final nickname = body['nickname'];
      final password = body['password'];
      final tel_id = body['tel_id']; // ← 電話番号追加

      if ([email, firstName, lastName, nickname, password, tel_id].contains(null)) {
        return Response.badRequest(
          body: jsonEncode({"error": "必須項目が不足しています"}),
        );
      }

      // DB登録
      final result = await userService.createUser(
        email: email,
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        password: password,
        tel_id: tel_id, // ← 電話番号を渡す
      );

      return Response.ok(
        jsonEncode({"status": result ? "success" : "error"}),
      );
    });
  }
}
