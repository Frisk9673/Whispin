import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:crypto/crypto.dart'; // ← パスワードハッシュ化用
import '../lib/services/user_service.dart';

/// 自作の CORS ミドルウェア
Middleware customCorsHeaders() {
  return (Handler innerHandler) {
    return (Request request) async {
      final origin = request.headers['origin'] ?? '*';

      if (request.method == 'OPTIONS') {
        return Response.ok('',
            headers: {
              'Access-Control-Allow-Origin': origin,
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': 'Origin, Content-Type',
              'Access-Control-Allow-Credentials': 'true',
            });
      }

      final response = await innerHandler(request);
      return response.change(headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
        'Access-Control-Allow-Credentials': 'true',
      });
    };
  };
}

void main() async {
  final userService = UserService();

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(customCorsHeaders())
      .addHandler((Request req) async {
    if (req.method == 'POST' && req.url.path == 'create_user') {
      final body = await req.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // パスワードをハッシュ化して保存
      final password = data['password'] ?? '';
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      final result = await userService.createUser(
        email: data['email'] ?? '',
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        nickname: data['nickname'] ?? '',
        password: hashedPassword, // ← ハッシュ化したパスワードを保存
        tel_id: data['tel_id'] ?? '', // ← 電話番号を保存
      );

      return Response.ok(
        jsonEncode({'status': result ? 'success' : 'error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.notFound('Not Found');
  });

  final port = 8081;
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('Server listening on port $port');
}
